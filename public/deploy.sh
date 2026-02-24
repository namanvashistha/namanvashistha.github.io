#!/usr/bin/env bash
set -u

# ==============================================================================
# CONFIGURATION
# ==============================================================================
# Format: "repo_name|git_url"
REPOS=(
    "chess|https://github.com/namanvashistha/chess.git"
    "foodly|https://github.com/namanvashistha/foodly.git"
    "hyperbole|https://github.com/namanvashistha/hyperbole.git"
    "limedb|https://github.com/namanvashistha/limedb.git"
)
ROOT_DOMAIN="namanvashistha.com"

# Determine the appropriate home directory, even if run with sudo
if [ -n "${SUDO_USER:-}" ]; then
    TARGET_HOME=$(eval echo "~${SUDO_USER}")
else
    TARGET_HOME="$HOME"
fi

BASE_DIR="$TARGET_HOME/namanvashistha"
LOG_FILE="$BASE_DIR/deploy.log"
LOCK_FILE="$BASE_DIR/.deploy.lock"
CADDY_NETWORK="caddy"

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
# CADDY (via caddy-docker-proxy)
# ==============================================================================
setup_caddy() {
    log "Setting up Caddy Docker Proxy..."

    # Auto-detect TLS mode based on IP
    local public_ip
    public_ip=$(curl -s --max-time 3 ifconfig.me || echo "unknown")
    local first_repo="${REPOS[0]%%|*}"
    local domain_ip
    domain_ip=$(dig +short "${first_repo}.${ROOT_DOMAIN}" 2>/dev/null | tail -n1 || echo "")

    local port_args=""
    local extra_args=""
    if [ "$public_ip" != "unknown" ] && [ "$public_ip" = "$domain_ip" ]; then
        log "Direct IP match → EC2 mode: Caddy will provision Let's Encrypt."
        port_args="-p 80:80 -p 443:443"
    else
        log "Behind Cloudflare/Tunnel → HTTP-only mode."
        # auto_https=off makes Caddy serve plain HTTP on internal port 443.
        # We map host:80 → container:443 so cloudflared can reach it.
        port_args="-p 80:443"
        extra_args="--label caddy= --label caddy.auto_https=off"
    fi

    docker rm -f caddy_proxy >> "$LOG_FILE" 2>&1 || true
    docker run -d \
        --name caddy_proxy \
        --network "$CADDY_NETWORK" \
        --restart unless-stopped \
        -p 80:80 -p 443:443 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v caddy_data:/data \
        $extra_args \
        lucaslorentz/caddy-docker-proxy:ci-alpine >> "$LOG_FILE" 2>&1 || { error "Failed to start Caddy."; exit 1; }

    log "Caddy Docker Proxy is running."
}

# ==============================================================================
# MAIN
# ==============================================================================
main() {
    mkdir -p "$BASE_DIR"
    touch "$LOG_FILE"

    acquire_lock
    install_docker

    # Create shared caddy network (all services join this)
    if ! docker network ls | grep -qw "$CADDY_NETWORK"; then
        docker network create "$CADDY_NETWORK" > /dev/null
    fi

    local failed_repos=0
    for repo in "${REPOS[@]}"; do
        if ! deploy_repo "$repo"; then
            failed_repos=$((failed_repos + 1))
        fi
    done

    setup_caddy

    log "--------------------------------------------------"
    if [ "$failed_repos" -gt 0 ]; then
        log "Completed with $failed_repos failures. See $LOG_FILE"
    else
        log "Deployment completed successfully!"
    fi
}

main "$@"
