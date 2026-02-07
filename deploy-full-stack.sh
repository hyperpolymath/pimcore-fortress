#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Pimcore Fortress - Full Stack Deployment Script
#
# Deploys complete verified container ecosystem + databases + Pimcore CMS

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPERPOLYMATH_REPOS="$HOME/Documents/hyperpolymath-repos"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking system dependencies..."

    local missing=()

    # Check for required commands
    command -v podman >/dev/null 2>&1 || missing+=("podman")
    command -v podman-compose >/dev/null 2>&1 || missing+=("podman-compose")
    command -v php >/dev/null 2>&1 || missing+=("php")
    command -v composer >/dev/null 2>&1 || missing+=("composer")
    command -v deno >/dev/null 2>&1 || missing+=("deno")
    command -v jq >/dev/null 2>&1 || missing+=("jq")

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Install with:"
        log_info "  sudo dnf install ${missing[*]} -y"
        return 1
    fi

    # Check for clang-devel (needed for VerisimDB)
    if ! rpm -qa | grep -q clang-devel; then
        log_warning "clang-devel not installed (needed for VerisimDB)"
        log_info "  sudo dnf install clang-devel -y"
    fi

    log_success "All dependencies satisfied"
    return 0
}

start_databases() {
    log_info "Starting databases (PostgreSQL + Redis)..."

    cd "$SCRIPT_DIR"
    podman-compose -f docker-compose.dev.yml up -d db redis

    log_info "Waiting for databases to be ready..."
    sleep 5

    # Test PostgreSQL
    if podman exec pimcore-fortress-db-1 pg_isready -U pimcore >/dev/null 2>&1; then
        log_success "PostgreSQL ready (port 5432)"
    else
        log_error "PostgreSQL failed to start"
        return 1
    fi

    # Test Redis
    if podman exec pimcore-fortress-redis-1 redis-cli ping >/dev/null 2>&1; then
        log_success "Redis ready (port 6379)"
    else
        log_error "Redis failed to start"
        return 1
    fi
}

start_vordr() {
    log_info "Starting Vörðr container runtime (port 8080)..."

    cd "$HYPERPOLYMATH_REPOS/vordr/src/mcp-adapter"

    # Kill existing instance
    if [ -f /tmp/vordr-mcp.pid ]; then
        kill "$(cat /tmp/vordr-mcp.pid)" 2>/dev/null || true
    fi

    # Start Vörðr
    nohup deno run --allow-net --allow-read --allow-env http-server.ts \
        > /tmp/vordr-mcp.log 2>&1 &
    echo $! > /tmp/vordr-mcp.pid

    sleep 3

    # Test
    if curl -s -X POST http://localhost:8080 \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","id":1,"method":"ping"}' \
        | grep -q '"pong"'; then
        log_success "Vörðr running (PID: $(cat /tmp/vordr-mcp.pid))"
    else
        log_error "Vörðr failed to start"
        return 1
    fi
}

start_svalinn() {
    log_info "Starting Svalinn edge gateway (port 8000)..."

    cd "$HYPERPOLYMATH_REPOS/svalinn"

    # Kill existing instance
    pkill -f "deno.*svalinn" || true

    # Start Svalinn
    AUTH_ENABLED=false \
    SVALINN_PORT=8000 \
    VORDR_ENDPOINT=http://localhost:8080 \
        nohup deno task start > /tmp/svalinn.log 2>&1 &
    echo $! > /tmp/svalinn.pid

    sleep 3

    # Test
    if curl -s http://localhost:8000/health | grep -q '"version"'; then
        log_success "Svalinn running (PID: $(cat /tmp/svalinn.pid))"
    else
        log_error "Svalinn failed to start"
        return 1
    fi
}

start_verisimdb() {
    log_info "Starting VerisimDB provenance ledger (port 9090)..."

    local binary="$HYPERPOLYMATH_REPOS/verisimdb/target/release/verisimdb"

    if [ ! -f "$binary" ]; then
        log_warning "VerisimDB not built yet"
        log_info "Building VerisimDB (this may take several minutes)..."

        cd "$HYPERPOLYMATH_REPOS/verisimdb"
        cargo build --release

        if [ ! -f "$binary" ]; then
            log_error "VerisimDB build failed"
            return 1
        fi
    fi

    # Kill existing instance
    pkill -f "verisimdb.*--port" || true

    # Start VerisimDB
    nohup "$binary" --port 9090 > /tmp/verisimdb.log 2>&1 &
    echo $! > /tmp/verisimdb.pid

    sleep 3

    log_success "VerisimDB running (PID: $(cat /tmp/verisimdb.pid))"
}

install_pimcore() {
    log_info "Installing Pimcore dependencies..."

    cd "$SCRIPT_DIR"

    if [ ! -d "vendor" ]; then
        log_info "Running composer install..."
        composer install --no-interaction --optimize-autoloader
        log_success "Composer dependencies installed"
    else
        log_success "Composer dependencies already installed"
    fi

    # Check .env file
    if [ ! -f ".env" ]; then
        log_info "Creating .env file..."
        cat > .env << 'ENVEOF'
APP_ENV=dev
APP_DEBUG=true
APP_SECRET=$(openssl rand -hex 32)

DATABASE_URL="postgresql://pimcore:pimcore@localhost:5432/pimcore"
REDIS_URL="redis://localhost:6379"
LITHOGLYPH_API_URL="http://localhost:8082"
VERISIMDB_ENDPOINT="http://localhost:9090/sparql"

PIMCORE_ADMIN_USERNAME=admin
PIMCORE_ADMIN_PASSWORD=admin
ENVEOF
        log_success ".env file created"
    fi

    # Initialize Pimcore database
    log_info "Initializing Pimcore database..."
    php bin/console doctrine:database:create --if-not-exists
    php bin/console doctrine:schema:update --force
    php bin/console cache:clear

    log_success "Pimcore initialized"
}

start_pimcore() {
    log_info "Starting Pimcore web server (port 8081)..."

    cd "$SCRIPT_DIR"

    # Kill existing PHP server
    pkill -f "php.*8081" || true

    # Start Pimcore
    nohup php -S localhost:8081 -t public/ > /tmp/pimcore.log 2>&1 &
    echo $! > /tmp/pimcore.pid

    sleep 3

    if curl -s http://localhost:8081 >/dev/null 2>&1; then
        log_success "Pimcore running (PID: $(cat /tmp/pimcore.pid))"
        log_success "Access at: http://localhost:8081"
    else
        log_error "Pimcore failed to start"
        return 1
    fi
}

print_status() {
    echo ""
    echo "======================================"
    echo "  Pimcore Fortress - Service Status"
    echo "======================================"
    echo ""

    # Check each service
    services=(
        "PostgreSQL:5432:podman ps -f name=db --format '{{.Status}}'"
        "Redis:6379:podman ps -f name=redis --format '{{.Status}}'"
        "Vörðr:8080:curl -s -X POST http://localhost:8080 -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"ping\"}'"
        "Svalinn:8000:curl -s http://localhost:8000/health"
        "VerisimDB:9090:[ -f /tmp/verisimdb.pid ] && ps -p \$(cat /tmp/verisimdb.pid)"
        "Pimcore:8081:curl -s http://localhost:8081"
    )

    for service_def in "${services[@]}"; do
        IFS=':' read -r name port check <<< "$service_def"
        printf "  %-12s [%s] " "$name" "$port"
        if eval "$check" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Running${NC}"
        else
            echo -e "${RED}✗ Stopped${NC}"
        fi
    done

    echo ""
    echo "======================================"
    echo ""
}

main() {
    echo ""
    echo "======================================"
    echo "  Pimcore Fortress Deployment"
    echo "  Verified Container Ecosystem"
    echo "======================================"
    echo ""

    # Check dependencies first
    if ! check_dependencies; then
        log_error "Dependency check failed"
        exit 1
    fi

    # Start services in order
    start_databases || { log_error "Database startup failed"; exit 1; }
    start_vordr || { log_error "Vörðr startup failed"; exit 1; }
    start_svalinn || { log_error "Svalinn startup failed"; exit 1; }
    start_verisimdb || log_warning "VerisimDB startup failed (non-critical)"

    # Pimcore setup
    install_pimcore || { log_error "Pimcore installation failed"; exit 1; }
    start_pimcore || { log_error "Pimcore startup failed"; exit 1; }

    # Print final status
    print_status

    log_success "Deployment complete!"
    log_info "Next steps:"
    log_info "  1. Access Pimcore at http://localhost:8081"
    log_info "  2. Login with admin/admin"
    log_info "  3. Upload assets to test Lithoglyph integration"
    echo ""
}

# Run main function
main "$@"
