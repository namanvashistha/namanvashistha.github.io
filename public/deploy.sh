#!/usr/bin/env bash
set -u

# ==============================================================================
# CONFIGURATION
# ==============================================================================
# Format: "repo_name|git_url|internal_port"
REPOS=(
    "chess|https://github.com/namanvashistha/chess.git|9000"
    "foodly|https://github.com/namanvashistha/foodly.git|80"
    "hyperbole|https://github.com/namanvashistha/hyperbole.git|8080"
    "limedb|https://github.com/namanvashistha/limedb.git|3000"
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
CADDY_DIR="$BASE_DIR/caddy"
DOCKER_NETWORK="naman_shared_net"

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
    IFS='|' read -r repo_name repo_url internal_port <<< "$1"
    internal_port="${internal_port:-80}"
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

    # Container Discovery & Proxy Config
    local live_container=""
    for cid in $(docker compose ps -q 2>/dev/null); do
        if docker inspect "$cid" --format '{{json .NetworkSettings.Ports}} {{json .Config.ExposedPorts}}' | grep -q "${internal_port}/tcp"; then
            live_container=$(docker inspect "$cid" --format '{{.Name}}' | sed 's/^\///')
            break
        fi
    done


    if [ -n "$live_container" ]; then
        log "Bridging $live_container to Caddy via port $internal_port"
        docker network connect "$DOCKER_NETWORK" "$live_container" >> "$LOG_FILE" 2>&1 || true
        
        local caddy_scheme="http://"
        [ "$ENABLE_TLS" = "true" ] && caddy_scheme=""
        echo "${caddy_scheme}${repo_name}.${ROOT_DOMAIN} {
    reverse_proxy ${live_container}:${internal_port}
}
" >> "$CADDY_DIR/Caddyfile"
    fi
    log "Success: $repo_name"
}

# ==============================================================================
# MAIN
# ==============================================================================
main() {
    mkdir -p "$BASE_DIR" "$CADDY_DIR"
    touch "$LOG_FILE"
    
    acquire_lock
    install_docker

    if ! docker network ls | grep -qw "$DOCKER_NETWORK"; then
        docker network create "$DOCKER_NETWORK" > /dev/null
    fi

    # Auto-detect TLS
    local public_ip
    public_ip=$(curl -s --max-time 3 ifconfig.me || echo "unknown")
    local domain_ip
    domain_ip=$(ping -c 1 "${REPOS[0]%%|*}.${ROOT_DOMAIN}" 2>/dev/null | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -n 1 || echo "")
    
    ENABLE_TLS="false"
    if [ "$public_ip" != "unknown" ] && [ "$public_ip" = "$domain_ip" ]; then
        ENABLE_TLS="true"
    fi

    # Initialize Caddyfile
    > "$CADDY_DIR/Caddyfile"

    local failed_repos=0
    for repo in "${REPOS[@]}"; do
        if ! deploy_repo "$repo"; then
            failed_repos=$((failed_repos + 1))
        fi
    done

    # Start Caddy
    docker rm -f caddy_proxy >> "$LOG_FILE" 2>&1 || true
    docker run -d \
        --name caddy_proxy \
        --network "$DOCKER_NETWORK" \
        --restart unless-stopped \
        -p 80:80 \
        -p 443:443 \
        -v "$CADDY_DIR/Caddyfile:/etc/caddy/Caddyfile" \
        -v caddy_data:/data \
        -v caddy_config:/config \
        caddy:latest >> "$LOG_FILE" 2>&1 || { error "Failed to start Caddy."; exit 1; }

    log "--------------------------------------------------"
    if [ "$failed_repos" -gt 0 ]; then
        log "Completed with $failed_repos failures. See $LOG_FILE"
        exit 0
    else
        log "Deployment completed successfully!"
        exit 0
    fi
}

main "$@"
