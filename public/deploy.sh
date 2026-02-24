#!/usr/bin/env bash

# Exit on undefined variables, but we handle command errors per repo manually
set -u

# ==============================================================================
# CONFIGURATION
# ==============================================================================
# 1. Global variable: Repo list
# Format: "repo_name|git_url|container_name|internal_port"
REPOS=(
    "chess|https://github.com/namanvashistha/chess.git|chess_go-app_1|9000"
    "foodly|https://github.com/namanvashistha/foodly.git|foodly_app_1|80"
    "hyperbole|https://github.com/namanvashistha/hyperbole.git|hyperbole-web|8080"
    "limedb|https://github.com/namanvashistha/limedb.git|limedb_web_1|3000"
)

# Determine the appropriate home directory, even if run with sudo
if [ -n "${SUDO_USER:-}" ]; then
    TARGET_HOME=$(eval echo "~${SUDO_USER}")
else
    TARGET_HOME="$HOME"
fi

# 2. Global variable: Machine config
BASE_DIR="$TARGET_HOME/namanvashistha"
LOG_FILE="$BASE_DIR/deploy.log"
LOCK_FILE="$BASE_DIR/.deploy.lock"
CADDY_DIR="$BASE_DIR/caddy"
ROOT_DOMAIN="namanvashistha.com"
DOCKER_NETWORK="naman_shared_net"
DOCKER_USER_GROUP="docker"

# ==============================================================================
# LOGGING AND LOCKING
# ==============================================================================
# 10. Log output safely
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ERROR: $1" >&2 | tee -a "$LOG_FILE"
}

# 9. File locking to prevent concurrent runs
acquire_lock() {
    # Using mkdir as a highly portable atomic locking mechanism
    # If flock is available (Linux), it can also be used, but mkdir works perfectly across unix systems.
    if ! mkdir "$LOCK_FILE.dir" 2>/dev/null; then
        error "Another instance of the deployment script is already running (lock directory exists). Exiting."
        exit 1
    fi
    # Ensure lock is removed on exit
    trap 'rm -rf "$LOCK_FILE.dir"' EXIT
    log "Acquired lock."
}

# ==============================================================================
# DEPENDENCIES
# ==============================================================================
# 3. Install Docker if not present
install_docker() {
    if ! command -v docker &> /dev/null; then
        log "Docker not found. Installing Docker..."
        # Uses the official Docker installation script, works on most Linux distros
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh || { error "Failed to install Docker."; exit 1; }
        rm get-docker.sh
        log "Docker installed successfully."
        
        # Ensure Docker service is running
        systemctl start docker || true
        systemctl enable docker || true
    else
        log "Docker is already installed."
    fi

    # Verify Docker Compose is available
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose not found. Please ensure Docker Compose plugin is installed."
        exit 1
    fi
}

# ==============================================================================
# DOCKER NETWORK
# ==============================================================================
# 4. Create shared Docker network (idempotent)
create_network() {
    if ! docker network ls | grep -qw "$DOCKER_NETWORK"; then
        log "Creating shared Docker network: $DOCKER_NETWORK..."
        docker network create "$DOCKER_NETWORK" || { error "Failed to create Docker network."; exit 1; }
    else
        log "Shared Docker network $DOCKER_NETWORK already exists."
    fi
}

# ==============================================================================
# CADDY REVERSE PROXY
# ==============================================================================
setup_caddy() {
    log "Configuring Caddy Reverse Proxy..."
    mkdir -p "$CADDY_DIR"
    local caddyfile="$CADDY_DIR/Caddyfile"
    
    # -------------------------------------------------------------
    # AUTO-DETECT TLS REQUIREMENT
    # -------------------------------------------------------------
    # If the domain's DNS points directly to THIS machine's public IP (e.g., EC2/VPS),
    # Caddy should provision Let's Encrypt TLS.
    # If it points elsewhere (e.g., Cloudflare Tunnel / Proxy), Cloudflare handles TLS,
    # so Caddy should just serve over HTTP internally.
    
    local public_ip=$(curl -s --max-time 5 ifconfig.me || echo "unknown")
    
    # Use the first repo's subdomain for the IP check, since the root domain might point elsewhere (e.g., GitHub Pages)
    local first_repo_info="${REPOS[0]}"
    local first_repo_name="${first_repo_info%%|*}"
    local check_domain="${first_repo_name}.${ROOT_DOMAIN}"

    # Use dig/getent to resolve the domain to an IP securely
    local domain_ip=""
    if command -v dig >/dev/null 2>&1; then
        domain_ip=$(dig +short "$check_domain" | tail -n1)
    elif command -v getent >/dev/null 2>&1; then
        domain_ip=$(getent ahostsv4 "$check_domain" | awk '{ print $1 }' | head -n1)
    else
        domain_ip=$(ping -c 1 "$check_domain" | grep PING | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    fi

    local ENABLE_TLS="false"
    if [ "$public_ip" != "unknown" ] && [ "$public_ip" = "$domain_ip" ]; then
        log "Detected Public IP match for $check_domain. Enabling automatic Let's Encrypt TLS in Caddy."
        ENABLE_TLS="true"
    else
        log "Domain $check_domain does not resolve directly to this machine's public IP ($public_ip != $domain_ip)."
        log "Assuming Cloudflare Tunnel / External Proxy. Disabling Let's Encrypt in Caddy (serving HTTP internally)."
    fi
    # -------------------------------------------------------------

    # Start fresh Caddyfile
    > "$caddyfile"

    for repo_info in "${REPOS[@]}"; do
        # Parse the string using Bash string manipulation or IFS
        IFS='|' read -r repo_name repo_url container_name internal_port <<< "$repo_info"
        
        # Set defaults if not provided in the array
        container_name="${container_name:-$repo_name}"
        internal_port="${internal_port:-80}"
        
        # Bridge the independent docker-compose container to the shared Caddy network
        # This keeps the repo's docker-compose completely unmodified and independent,
        # but allows Caddy to see it.
        log "Bridging $container_name to $DOCKER_NETWORK..."
        docker network connect "$DOCKER_NETWORK" "$container_name" >> "$LOG_FILE" 2>&1 || true
        
        # If ENABLE_TLS is true, Caddy handles Let's Encrypt SSL automatically (good for EC2).
        # If false, we explicitly tell Caddy to serve HTTP since Cloudflare handles HTTPS.
        if [ "$ENABLE_TLS" = "true" ]; then
            echo "${repo_name}.${ROOT_DOMAIN} {" >> "$caddyfile"
        else
            echo "http://${repo_name}.${ROOT_DOMAIN} {" >> "$caddyfile"
        fi
        
        echo "    reverse_proxy ${container_name}:${internal_port}" >> "$caddyfile"
        echo "}" >> "$caddyfile"
        echo "" >> "$caddyfile"
    done

    # Remove existing Caddy container if it exists
    if docker ps -a --format '{{.Names}}' | grep -Eq "^caddy_proxy$"; then
        log "Removing existing Caddy container..."
        docker rm -f caddy_proxy >> "$LOG_FILE" 2>&1
    fi

    log "Starting Caddy container..."
    if ! docker run -d \
        --name caddy_proxy \
        --network "$DOCKER_NETWORK" \
        --restart unless-stopped \
        -p 80:80 \
        -p 443:443 \
        -v "$caddyfile:/etc/caddy/Caddyfile" \
        -v caddy_data:/data \
        -v caddy_config:/config \
        caddy:latest >> "$LOG_FILE" 2>&1; then
        error "Failed to start Caddy container."
        exit 1
    fi
}

# ==============================================================================
# REPOSITORY DEPLOYMENT
# ==============================================================================
deploy_repo() {
    local repo_info="$1"
    local repo_name="${repo_info%%|*}"
    local repo_url="${repo_info##*|}"
    local target_dir="$BASE_DIR/$repo_name"

    log "--------------------------------------------------"
    log "Starting deployment for: $repo_name"

    # 5. Clone repos if missing, otherwise git pull
    if [ ! -d "$target_dir" ]; then
        log "Cloning $repo_name from $repo_url..."
        if ! git clone "$repo_url" "$target_dir" >> "$LOG_FILE" 2>&1; then
            error "Failed to clone $repo_name. Skipping."
            return 1
        fi
    else
        log "Directory exists. Pulling latest changes for $repo_name..."
        cd "$target_dir" || { error "Failed to cd into $target_dir."; return 1; }
        
        # Stash any local changes to ensure clean pull, then pull
        git stash >> "$LOG_FILE" 2>&1 || true
        if ! git pull origin main >> "$LOG_FILE" 2>&1; then
            log "Failed to pull main, trying master..."
            if ! git pull origin master >> "$LOG_FILE" 2>&1; then
                error "Failed to pull latest changes for $repo_name. Skipping."
                return 1
            fi
        fi
    fi

    # Navigate to repo directory
    cd "$target_dir" || { error "Failed to cd into $target_dir."; return 1; }

    # 8. Assume each repo has its own docker-compose.yml
    if [ ! -f "docker-compose.yml" ] && [ ! -f "docker-compose.yaml" ]; then
        error "No docker-compose.yml found in $repo_name. Skipping."
        return 1
    fi

    # 6. Run docker compose up -d --build in each repo
    # 12. Fail fast on errors but continue to next repo if one fails
    # NOTE: Since each repo is run in its own directory, Docker automatically assigns isolated 
    # projects per repo, preventing shared services (like Redis) from overlapping unexpectedly.
    # 7. NOT exposing DB ports should be handled naturally inside the individual docker-compose.yamls 
    # by NOT mapping local ports (e.g., omitting 'ports: - "5432:5432"').
    
    log "Building and starting containers for $repo_name..."
    
    # Use modern `docker compose` if available, fallback to `docker-compose`
    if docker compose version &> /dev/null; then
        docker compose up -d --build 2>&1 | tee -a "$LOG_FILE"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            error "Docker compose failed for $repo_name."
            return 1
        fi
        
        # Ensure containers restart on machine reboot
        docker compose ps -q | xargs -r docker update --restart unless-stopped >> "$LOG_FILE" 2>&1
    elif command -v docker-compose &> /dev/null; then
        docker-compose up -d --build 2>&1 | tee -a "$LOG_FILE"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            error "Docker-compose failed for $repo_name."
            return 1
        fi
        
        # Ensure containers restart on machine reboot
        docker-compose ps -q | xargs -r docker update --restart unless-stopped >> "$LOG_FILE" 2>&1
    else
        error "No docker compose command available."
        return 1
    fi

    log "Successfully deployed $repo_name."
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================
main() {
    # Ensure Base Directory and Log file exist
    # NOTE: Run script with sudo if creating directories in /opt & /var/log
    mkdir -p "$BASE_DIR" || { echo "Failed to create base directory $BASE_DIR"; exit 1; }
    touch "$LOG_FILE" || { echo "Failed to create log file $LOG_FILE"; exit 1; }

    log "Starting deployment script..."

    acquire_lock
    install_docker
    create_network
    setup_caddy

    # Iterate over repositories and deploy
    local failed_repos=0
    for repo in "${REPOS[@]}"; do
        # 12. Fail fast on errors but continue to next repo if one fails
        if ! deploy_repo "$repo"; then
            failed_repos=$((failed_repos + 1))
            error "Deployment failed for repo: ${repo%%|*}. Proceeding to the next repo."
        fi
    done

    log "--------------------------------------------------"
    if [ "$failed_repos" -gt 0 ]; then
        log "Deployment completed with $failed_repos repository failures. Check logs for details."
        exit 0 # Keep exit 0 if cron doesn't need to alert on partial failures, or change if preferred.
    else
        log "Deployment completed successfully for all repositories."
        exit 0
    fi
}

# Execute main function
main "$@"
