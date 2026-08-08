#!/usr/bin/env bash
set -u

# ==============================================================================
# CONFIGURATION
# ==============================================================================
# Format: "repo_name|git_url"
#
# dash is first because it now carries the caddy proxy container, and getting
# the proxy up before the services it routes to is the sane order on a fresh
# box. Not a hard dependency — the `caddy` network is created in main() before
# any repo is touched, so the others would come up fine regardless.
#
# chess, foodly, hyperbole and limedb used to be here. They are now deployed by
# ConOps (a container in dash), which watches their GitHub repos and redeploys on
# new commits. Do NOT add them back while they are registered there — both would
# race to run `compose up` on the same project.
#
# These two stay because ConOps cannot deploy them: it clones into its own
# runtime directory, and both depend on files that are not in git. dash needs a
# gitignored .env (CF_TUNNEL_TOKEN, BESZEL_*, AUTOKUMA_*) plus its ./beszel and
# ./ecards bind mounts; text-to-image-bot declares `env_file: .env` outright.
REPOS=(
    "dash|https://github.com/namanvashistha/dash.git"
    "text-to-image-bot|https://github.com/namanvashistha/text-to-image-bot.git"
)

# Determine the appropriate home directory, even if run with sudo
if [ -n "${SUDO_USER:-}" ]; then
    TARGET_HOME=$(eval echo "~${SUDO_USER}")
else
    TARGET_HOME="$HOME"
fi

BASE_DIR="$TARGET_HOME/namanvashistha"
LOG_FILE="$BASE_DIR/deploy.log"
LOCK_FILE="$BASE_DIR/.deploy.lock"

# ==============================================================================
# LOGGING AND LOCKING
# ==============================================================================
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }
error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2 | tee -a "$LOG_FILE"; }

acquire_lock() {
    if ! mkdir "$LOCK_FILE.dir" 2>/dev/null; then
        error "Deployment already running (lock directory exists)."
        exit 1
    fi
    trap 'rm -rf "$LOCK_FILE.dir"' EXIT
}

# ==============================================================================
# DEPENDENCIES
# ==============================================================================
install_docker() {
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        return
    fi
    log "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl restart docker
    if ! command -v docker &> /dev/null; then
        error "Failed to install Docker."
        exit 1
    fi
}

# ==============================================================================
# REPOSITORY DEPLOYMENT
# ==============================================================================
deploy_repo() {
    IFS='|' read -r repo_name repo_url <<< "$1"
    local target_dir="$BASE_DIR/$repo_name"

    log "--- Deploying: $repo_name ---"

    # Git Clone / Pull
    if [ ! -d "$target_dir" ]; then
        git clone "$repo_url" "$target_dir" >> "$LOG_FILE" 2>&1 || { error "Clone failed."; return 1; }
    else
        cd "$target_dir" || return 1
        git stash -q >> "$LOG_FILE" 2>&1 || true
        git pull -q origin main >> "$LOG_FILE" 2>&1 || git pull -q origin master >> "$LOG_FILE" 2>&1 || { error "Pull failed."; return 1; }
    fi

    cd "$target_dir" || return 1

    if [ ! -f "docker-compose.yml" ] && [ ! -f "docker-compose.yaml" ]; then
        error "No docker-compose file found."
        return 1
    fi

    # Docker Compose Up
    docker compose up -d --build --remove-orphans >> "$LOG_FILE" 2>&1 || { error "Compose failed."; return 1; }
    docker compose ps -q | xargs -r docker update --restart unless-stopped >> "$LOG_FILE" 2>&1 || true

    log "Success: $repo_name"
}


# ==============================================================================
# MAIN
# ==============================================================================
main() {
    mkdir -p "$BASE_DIR"
    touch "$LOG_FILE"

    acquire_lock
    install_docker

    # The caddy network and volume stay here rather than in dash's compose.
    # Compose won't adopt resources it didn't create — pointing dash's compose
    # at them with `name:` fails with "has incorrect label
    # com.docker.compose.network" — and making them compose-owned would mean
    # tearing down every container on the box once. Both commands are
    # idempotent, so this is a no-op after the first run.
    if ! docker network ls | grep -qw "caddy"; then
        docker network create caddy > /dev/null
    fi
    docker volume create caddy_data > /dev/null 2>&1 || true

    local failed_repos=0
    for repo in "${REPOS[@]}"; do
        if ! deploy_repo "$repo"; then
            failed_repos=$((failed_repos + 1))
        fi
    done

    log "--------------------------------------------------"
    if [ "$failed_repos" -gt 0 ]; then
        log "Completed with $failed_repos failures. See $LOG_FILE"
    else
        log "Deployment completed successfully!"
    fi
}

main "$@"
