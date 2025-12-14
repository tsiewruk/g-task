#!/bin/bash

# ======================================
# Create Archive Script
# Package project for submission
# ======================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

ARCHIVE_NAME="php-poc-containerization"
FORMAT="${1:-tar.gz}"

print_info "Creating archive: ${ARCHIVE_NAME}.${FORMAT}"

# Cleanup old archives
if [ -f "${ARCHIVE_NAME}.tar.gz" ]; then
    rm "${ARCHIVE_NAME}.tar.gz"
    print_info "Removed old tar.gz archive"
fi

if [ -f "${ARCHIVE_NAME}.zip" ]; then
    rm "${ARCHIVE_NAME}.zip"
    print_info "Removed old zip archive"
fi

# Create archive based on format
case $FORMAT in
    tar.gz|tgz)
        print_info "Creating tar.gz archive..."
        tar -czf "${ARCHIVE_NAME}.tar.gz" \
            --exclude='.git' \
            --exclude='old' \
            --exclude='vendor' \
            --exclude='*.log' \
            --exclude='helm/php-poc/charts' \
            --exclude='helm/php-poc/Chart.lock' \
            --exclude='.DS_Store' \
            --exclude='*.swp' \
            --exclude='*.swo' \
            --exclude='.idea' \
            --exclude='.vscode' \
            --exclude="${ARCHIVE_NAME}.tar.gz" \
            --exclude="${ARCHIVE_NAME}.zip" \
            .

        SIZE=$(du -h "${ARCHIVE_NAME}.tar.gz" | cut -f1)
        print_success "Archive created: ${ARCHIVE_NAME}.tar.gz (${SIZE})"
        ;;

    zip)
        print_info "Creating zip archive..."
        zip -r "${ARCHIVE_NAME}.zip" . \
            -x "*.git*" \
            -x "old/*" \
            -x "vendor/*" \
            -x "*.log" \
            -x "helm/php-poc/charts/*" \
            -x "helm/php-poc/Chart.lock" \
            -x ".DS_Store" \
            -x "*.swp" \
            -x "*.swo" \
            -x ".idea/*" \
            -x ".vscode/*" \
            -x "${ARCHIVE_NAME}.tar.gz" \
            -x "${ARCHIVE_NAME}.zip"

        SIZE=$(du -h "${ARCHIVE_NAME}.zip" | cut -f1)
        print_success "Archive created: ${ARCHIVE_NAME}.zip (${SIZE})"
        ;;

    *)
        print_warning "Unknown format: ${FORMAT}"
        print_info "Usage: $0 [tar.gz|zip]"
        exit 1
        ;;
esac

# Show archive contents
print_info "\nArchive contents (first 20 files):"
case $FORMAT in
    tar.gz|tgz)
        tar -tzf "${ARCHIVE_NAME}.tar.gz" | head -20
        echo "..."
        TOTAL=$(tar -tzf "${ARCHIVE_NAME}.tar.gz" | wc -l)
        print_info "Total files: ${TOTAL}"
        ;;
    zip)
        unzip -l "${ARCHIVE_NAME}.zip" | head -23
        echo "..."
        TOTAL=$(unzip -l "${ARCHIVE_NAME}.zip" | tail -1 | awk '{print $2}')
        print_info "Total files: ${TOTAL}"
        ;;
esac

print_success "\nArchive ready for submission!"
print_info "\nTo extract:"
case $FORMAT in
    tar.gz|tgz)
        echo "  tar -xzf ${ARCHIVE_NAME}.tar.gz"
        ;;
    zip)
        echo "  unzip ${ARCHIVE_NAME}.zip"
        ;;
esac
