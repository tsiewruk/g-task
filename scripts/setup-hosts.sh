#!/bin/bash

# ======================================
# Setup /etc/hosts for local development
# Adds localhost domains for Traefik routing
# ======================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    print_error "Please run with sudo:"
    echo "  sudo $0"
    exit 1
fi

HOSTS_FILE="/etc/hosts"
MARKER_START="# PHP PoC - START"
MARKER_END="# PHP PoC - END"

# Domains to add
DOMAINS=(
    "app.localhost"
    "dev.localhost"
    "traefik.localhost"
    "pma.localhost"
    "redis.localhost"
)

print_info "Setting up /etc/hosts for PHP PoC..."

# Check if entries already exist
if grep -q "$MARKER_START" "$HOSTS_FILE"; then
    print_warning "Entries already exist in $HOSTS_FILE"
    print_info "Removing old entries..."

    # Remove old entries
    sed -i.bak "/$MARKER_START/,/$MARKER_END/d" "$HOSTS_FILE"
    print_success "Old entries removed"
fi

# Add new entries
print_info "Adding new entries to $HOSTS_FILE..."

cat >> "$HOSTS_FILE" << EOF

$MARKER_START
127.0.0.1 app.localhost
127.0.0.1 dev.localhost
127.0.0.1 traefik.localhost
127.0.0.1 pma.localhost
127.0.0.1 redis.localhost
$MARKER_END
EOF

print_success "Entries added successfully!"

print_info "\nAdded domains:"
for domain in "${DOMAINS[@]}"; do
    echo "  - http://$domain"
done

print_success "\nSetup complete! You can now access services via .localhost domains"

# Verify
print_info "\nVerifying entries..."
if grep -A 6 "$MARKER_START" "$HOSTS_FILE" > /dev/null; then
    print_success "Verification passed"
else
    print_error "Verification failed - please check $HOSTS_FILE manually"
    exit 1
fi
