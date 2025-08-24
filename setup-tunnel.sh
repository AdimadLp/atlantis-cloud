#!/bin/bash

# Cloudflare Tunnel Setup Script for Atlantis Cloud
# This script helps you set up and configure your Cloudflare Tunnel

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Cloudflare Tunnel Setup - Atlantis Cloud${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if required tools are installed
check_requirements() {
    print_step "Checking requirements..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Require docker compose plugin
    if ! docker compose version >/dev/null 2>&1; then
        print_error "'docker compose' plugin not found."
        print_info "Install with: sudo apt install docker-compose-plugin"
        exit 1
    fi
    
    print_success "Requirements check passed"
}

# Check if .env file exists
check_env_file() {
    print_step "Checking environment configuration..."
    
    if [ ! -f ".env" ]; then
        print_warning ".env file not found"
        print_info "Creating .env from template..."
        
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_success ".env file created from template"
            print_warning "Please edit .env file with your actual values before continuing"
            return 1
        else
            print_error ".env.example not found. Cannot create .env file."
            exit 1
        fi
    fi
    
    print_success "Environment file exists"
    return 0
}

# Check tunnel credentials
check_tunnel_credentials() {
    print_step "Checking tunnel credentials..."
    
    if [ ! -d "cloudflared" ]; then
        print_info "Creating cloudflared directory..."
        mkdir -p cloudflared
    fi
    
    # Check for credentials file
    local creds_files=(cloudflared/*.json)
    if [ ! -f "${creds_files[0]}" ]; then
        print_warning "No tunnel credentials file found in cloudflared/"
        print_info "You need to:"
        print_info "1. Create a tunnel: cloudflared tunnel create atlantis-cloud"
        print_info "2. Copy the generated .json file to ./cloudflared/"
        print_info "3. Update CLOUDFLARE_TUNNEL_ID in .env with your tunnel ID"
        return 1
    fi
    
    # Extract tunnel ID from filename
    local creds_file="${creds_files[0]}"
    local tunnel_id=$(basename "$creds_file" .json)
    
    print_success "Found credentials file: $creds_file"
    print_info "Tunnel ID: $tunnel_id"
    
    # Check if tunnel ID matches .env
    if [ -f ".env" ]; then
        local env_tunnel_id=$(grep "^CLOUDFLARE_TUNNEL_ID=" .env | cut -d'=' -f2)
        if [ "$env_tunnel_id" != "$tunnel_id" ]; then
            print_warning "Tunnel ID in .env ($env_tunnel_id) doesn't match credentials file ($tunnel_id)"
            print_info "Updating .env with correct tunnel ID..."
            sed -i "s/^CLOUDFLARE_TUNNEL_ID=.*/CLOUDFLARE_TUNNEL_ID=$tunnel_id/" .env
            print_success "Updated CLOUDFLARE_TUNNEL_ID in .env"
        fi
    fi
    
    return 0
}

# Validate configuration
validate_config() {
    print_step "Validating tunnel configuration..."
    
    if [ ! -f "cloudflared/config.yml" ]; then
        print_error "cloudflared/config.yml not found"
        return 1
    fi
    
    # Check if config.yml has proper structure
    if ! grep -q "ingress:" cloudflared/config.yml; then
        print_error "config.yml missing ingress section"
        return 1
    fi
    
    if ! grep -q "service: http_status:404" cloudflared/config.yml; then
        print_error "config.yml missing catch-all rule (service: http_status:404)"
        return 1
    fi
    
    print_success "Configuration validation passed"
    return 0
}

# Test tunnel connectivity
test_tunnel() {
    print_step "Testing tunnel connectivity..."
    
    print_info "Starting cloudflared container for testing..."
    
    # Start only cloudflared for testing using docker compose plugin
    if docker compose -f docker-compose.cloudflared.yaml up -d cloudflared; then
        print_success "Cloudflared container started"
        
        # Wait for container to be ready
        print_info "Waiting for tunnel to establish connection..."
        sleep 10
        
        # Check container logs
        print_info "Checking tunnel logs..."
        docker logs cloudflared_tunnel --tail 20
        
        # Check if tunnel is registered
        if docker exec cloudflared_tunnel cloudflared tunnel info 2>/dev/null; then
            print_success "Tunnel is connected successfully"
        else
            print_warning "Tunnel connection may have issues - check logs above"
        fi
        
    # Stop test container
    docker compose -f docker-compose.cloudflared.yaml down
    else
        print_error "Failed to start cloudflared container"
        return 1
    fi
}

# Setup DNS records information
show_dns_setup() {
    print_step "DNS Configuration Required"
    
    echo ""
    print_info "You need to configure the following DNS records in Cloudflare:"
    echo ""
    
    # Extract hostnames from config.yml
    if [ -f "cloudflared/config.yml" ]; then
        local hostnames=$(grep "hostname:" cloudflared/config.yml | awk '{print $3}' | sort -u)
        local tunnel_id=$(grep "^CLOUDFLARE_TUNNEL_ID=" .env 2>/dev/null | cut -d'=' -f2 || echo "YOUR_TUNNEL_ID")
        
        for hostname in $hostnames; do
            echo -e "  ${GREEN}$hostname${NC}"
            echo -e "    Type: ${YELLOW}CNAME${NC}"
            echo -e "    Target: ${YELLOW}$tunnel_id.cfargotunnel.com${NC}"
            echo ""
        done
    fi
    
    print_info "After configuring DNS records, test your domains:"
    print_info "curl -I https://notes.atlantis-cloud.com"
    print_info "curl -I https://drive.atlantis-cloud.com"
    print_info "curl -I https://obsidian.atlantis-cloud.com"
}

# Main setup flow
main() {
    print_header
    
    check_requirements
    
    if ! check_env_file; then
        print_warning "Please configure your .env file first, then run this script again"
        exit 1
    fi
    
    if ! check_tunnel_credentials; then
        print_warning "Please set up tunnel credentials first, then run this script again"
        exit 1
    fi
    
    if ! validate_config; then
        print_error "Configuration validation failed"
        exit 1
    fi
    
    print_success "Configuration looks good!"
    
    # Ask if user wants to test
    echo ""
    read -p "Do you want to test the tunnel connectivity? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        test_tunnel
    fi
    
    show_dns_setup
    
    print_success "Setup complete!"
    print_info "You can now start all services with: ./atlantis-cloud.sh start"
}

# Handle script arguments
case "${1:-}" in
    "check")
        check_requirements
        check_env_file
        check_tunnel_credentials
        validate_config
        ;;
    "test")
        test_tunnel
        ;;
    "dns")
        show_dns_setup
        ;;
    *)
        main
        ;;
esac
