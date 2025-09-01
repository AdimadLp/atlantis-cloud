#!/bin/bash

# Atlantis Cloud - Service Management Script
# This script manages all the separated docker-compose services

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ENV_FILE="$SCRIPT_DIR/.env"

COMPOSE_CMD="docker compose"

ensure_compose_cmd() {
    if ! docker compose version >/dev/null 2>&1; then
        echo -e "${RED}[ERROR]${NC} 'docker compose' plugin not found."
        echo -e "${YELLOW}[WARNING]${NC} Install with: sudo apt install docker-compose-plugin"
        exit 1
    fi
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
check_env_file() {
    if [ ! -f "$ENV_FILE" ]; then
        print_error ".env file not found at $ENV_FILE"
        print_warning "Please create it with the required environment variables"
        exit 1
    fi
}

# Service definitions
declare -A SERVICES=(
    ["cloudflared"]="$SCRIPT_DIR/docker-compose.cloudflared.yaml"
    ["iot"]="$SCRIPT_DIR/iot/irrigation/docker-compose.yaml"
    ["notes"]="$SCRIPT_DIR/notes/docker-compose.yaml"
    ["obsidian"]="$SCRIPT_DIR/obsidian/docker-compose.yaml"
    ["drive"]="$SCRIPT_DIR/drive/docker-compose.yaml"
    ["signaturepdf"]="$SCRIPT_DIR/signaturepdf/docker-compose.yaml"
    ["immich"]="$SCRIPT_DIR/immich/docker-compose.yaml"
)

# Function to run docker-compose command for a specific service
run_compose() {
    local service=$1
    local command=$2
    local compose_file=${SERVICES[$service]}
    
    if [ ! -f "$compose_file" ]; then
        print_error "Docker compose file not found for service '$service': $compose_file"
        return 1
    fi
    
    print_status "Running '$command' for service '$service'"
    # Ensure compose plugin is available
    ensure_compose_cmd
    $COMPOSE_CMD -f "$compose_file" --env-file "$ENV_FILE" $command
}

# Function to start services in the correct order
start_all() {
    print_status "Starting all Atlantis Cloud services..."
    
    # Start infrastructure services first (databases, etc.)
    run_compose "iot" "up -d"
    run_compose "drive" "up -d" 
    run_compose "notes" "up -d"
    run_compose "obsidian" "up -d"
    run_compose "signaturepdf" "up -d"
    run_compose "immich" "up -d"
    
    # Wait a bit for services to initialize
    print_status "Waiting for services to initialize..."
    sleep 10
    
    # Start cloudflared last (it needs to connect to all networks)
    run_compose "cloudflared" "up -d"
    
    print_success "All services started!"
    print_status "Services will be available at:"
    echo "  - IoT: iot.atlantis-cloud.com"
    echo "  - Notes: notes.atlantis-cloud.com" 
    echo "  - Obsidian: obsidian.atlantis-cloud.com"
    echo "  - Drive: drive.atlantis-cloud.com"
    echo "  - SignaturePDF: pdf.atlantis-cloud.com"
    echo "  - Immich Photos: photos.atlantis-cloud.com"
}

# Function to stop all services
stop_all() {
    print_status "Stopping all Atlantis Cloud services..."
    
    # Stop cloudflared first
    run_compose "cloudflared" "down"
    
    # Stop other services
    for service in iot drive notes obsidian signaturepdf immich; do
        run_compose "$service" "down"
    done
    
    print_success "All services stopped!"
}

# Function to show status of all services
status_all() {
    print_status "Atlantis Cloud Services Status:"
    echo ""
    
    for service in "${!SERVICES[@]}"; do
        echo -e "${BLUE}=== $service ===${NC}"
        run_compose "$service" "ps"
        echo ""
    done
}

# Function to show logs for a specific service
logs_service() {
    local service=$1
    if [ -z "$service" ]; then
        print_error "Please specify a service: cloudflared, iot, notes, obsidian, drive, signaturepdf, immich"
        return 1
    fi
    
    if [ ! "${SERVICES[$service]}" ]; then
        print_error "Unknown service: $service"
        print_warning "Available services: ${!SERVICES[*]}"
        return 1
    fi
    
    run_compose "$service" "logs -f"
}

# Function to start a specific service with cloudflared
start_service() {
    local service=$1
    if [ -z "$service" ]; then
        print_error "Please specify a service: iot, notes, obsidian, drive, signaturepdf, immich"
        return 1
    fi
    
    if [ "$service" = "cloudflared" ]; then
        print_error "Use 'start' command to start all services, or specify a specific service to start with cloudflared"
        return 1
    fi
    
    if [ ! "${SERVICES[$service]}" ]; then
        print_error "Unknown service: $service"
        print_warning "Available services (excluding cloudflared): iot, notes, obsidian, drive, signaturepdf, immich"
        return 1
    fi
    
    print_status "Starting service '$service' with cloudflared..."
    
    # Start the specific service first
    run_compose "$service" "up -d"
    
    # Wait a bit for the service to initialize
    print_status "Waiting for service to initialize..."
    sleep 5
    
    # Start cloudflared to enable access
    run_compose "cloudflared" "up -d"
    
    print_success "Service '$service' and cloudflared started!"
    print_status "Service will be available at:"
    case "$service" in
        "iot")
            echo "  - IoT: iot.atlantis-cloud.com"
            ;;
        "notes")
            echo "  - Notes: notes.atlantis-cloud.com"
            ;;
        "obsidian")
            echo "  - Obsidian: obsidian.atlantis-cloud.com"
            ;;
        "drive")
            echo "  - Drive: drive.atlantis-cloud.com"
            ;;
        "signaturepdf")
            echo "  - SignaturePDF: pdf.atlantis-cloud.com"
            ;;
        "immich")
            echo "  - Immich Photos: photos.atlantis-cloud.com"
            ;;
    esac
}

# Function to restart a specific service
restart_service() {
    local service=$1
    if [ -z "$service" ]; then
        print_error "Please specify a service: cloudflared, iot, notes, obsidian, drive, signaturepdf, immich"
        return 1
    fi
    
    if [ ! "${SERVICES[$service]}" ]; then
        print_error "Unknown service: $service"
        print_warning "Available services: ${!SERVICES[*]}"
        return 1
    fi
    
    print_status "Restarting service: $service"
    run_compose "$service" "down"
    run_compose "$service" "up -d"
    print_success "Service $service restarted!"
}

# Main script logic
check_env_file

case "$1" in
    "start"|"up")
        if [ -n "$2" ]; then
            start_service "$2"
        else
            start_all
        fi
        ;;
    "stop"|"down")
        stop_all
        ;;
    "restart")
        if [ -n "$2" ]; then
            restart_service "$2"
        else
            stop_all
            sleep 5
            start_all
        fi
        ;;
    "status"|"ps")
        status_all
        ;;
    "logs")
        logs_service "$2"
        ;;
    *)
        echo "Atlantis Cloud Service Manager"
        echo ""
        echo "Usage: $0 {start|stop|restart|status|logs} [service]"
        echo ""
        echo "Commands:"
        echo "  start [service]    Start all services or specific service with cloudflared"
        echo "  stop               Stop all services"
        echo "  restart [svc]      Restart all services or specific service"
        echo "  status             Show status of all services"
        echo "  logs <service>     Show logs for specific service"
        echo ""
        echo "Available services: ${!SERVICES[*]}"
        echo ""
        echo "Examples:"
        echo "  $0 start                    # Start all services"
        echo "  $0 start notes              # Start only notes service with cloudflared"
        echo "  $0 restart cloudflared      # Restart only cloudflared"
        echo "  $0 logs iot                # Show IoT service logs"
        exit 1
        ;;
esac
