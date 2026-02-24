#!/usr/bin/env bash

# Exit on undefined variables, but we handle command errors per repo manually
set -u

# ==============================================================================
# CONFIGURATION
# ==============================================================================
# 1. Global variable: Repo list
# Format: "repo_name|git_url"
REPOS=(
    "chess|https://github.com/namanvashistha/chess.git"
    "foodly|https://github.com/namanvashistha/foodly.git"
    "hyperbole|https://github.com/namanvashistha/hyperbole.git"
    "limedb|https://github.com/namanvashistha/limedb.git"
)

# 2. Global variable: Machine config
BASE_DIR="/opt/namanvashistha_deploy"
LOG_FILE="/var/log/namanvashistha_deploy.log"
LOCK_FILE="/tmp/namanvashistha_deploy.lock"
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
    local compose_cmd="docker compose"
    if ! command -v docker compose &> /dev/null; then
        compose_cmd="docker-compose"
    fi

    if ! $compose_cmd up -d --build >> "$LOG_FILE" 2>&1; then
        error "Docker compose failed for $repo_name."
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
