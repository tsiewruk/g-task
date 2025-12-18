#!/bin/bash

# ======================================
# Reusable Docker Build Script
# PoC PHP Containerization
# ======================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
IMAGE_NAME="php-poc-app"
IMAGE_REGISTRY="localhost"
VERSION="latest"
BUILD_TARGET="production"
PUSH_IMAGE=false
BUILD_ARGS=""

# Function to display usage
usage() {
    cat << EOF
${BLUE}==========================================
Docker Build Script - PHP PoC
==========================================${NC}

${GREEN}Usage:${NC}
  ./build.sh [OPTIONS]

${GREEN}Options:${NC}
  -t, --target TARGET       Build target (production|development) [default: production]
  -v, --version VERSION     Image version tag [default: latest]
  -r, --registry REGISTRY   Docker registry [default: localhost]
  -n, --name NAME           Image name [default: php-poc-app]
  -p, --push                Push image to registry after build
  -c, --clean               Clean build (no cache)
  -h, --help                Display this help message

${GREEN}Examples:${NC}
  # Build production image
  ./build.sh --target production --version 1.0.0

  # Build development image with Xdebug
  ./build.sh --target development --version dev

  # Build and push to registry
  ./build.sh --target production --version 1.0.0 --registry docker.io/myuser --push

  # Clean build without cache
  ./build.sh --target production --clean

${GREEN}Available Targets:${NC}
  production   - Optimized production image with OPcache
  development  - Development image with Xdebug and dev dependencies

EOF
    exit 0
}

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)
            BUILD_TARGET="$2"
            shift 2
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -r|--registry)
            IMAGE_REGISTRY="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -p|--push)
            PUSH_IMAGE=true
            shift
            ;;
        -c|--clean)
            BUILD_ARGS="--no-cache"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate build target
if [[ "$BUILD_TARGET" != "production" && "$BUILD_TARGET" != "development" ]]; then
    print_error "Invalid build target: $BUILD_TARGET"
    print_error "Valid targets are: production, development"
    exit 1
fi

# Construct full image name
FULL_IMAGE_NAME="${IMAGE_REGISTRY}/${IMAGE_NAME}:${VERSION}"
FULL_IMAGE_NAME_TARGET="${IMAGE_REGISTRY}/${IMAGE_NAME}:${VERSION}-${BUILD_TARGET}"

# Print build configuration
print_info "==========================================\n"
print_info "Build Configuration:"
echo "  Target:        ${BUILD_TARGET}"
echo "  Version:       ${VERSION}"
echo "  Image Name:    ${FULL_IMAGE_NAME}"
echo "  Image Target:  ${FULL_IMAGE_NAME_TARGET}"
echo "  Registry:      ${IMAGE_REGISTRY}"
echo "  Push:          ${PUSH_IMAGE}"
echo "  Build Args:    ${BUILD_ARGS}"
print_info "==========================================\n"

# Check if Dockerfile exists
if [[ ! -f "Dockerfile" ]]; then
    print_error "Dockerfile not found in current directory!"
    exit 1
fi

# Build the image
print_info "Building Docker image..."
print_info "Target: ${BUILD_TARGET}"

if docker build \
    --target "${BUILD_TARGET}" \
    --tag "${FULL_IMAGE_NAME}" \
    --tag "${FULL_IMAGE_NAME_TARGET}" \
    ${BUILD_ARGS} \
    .; then
    print_success "Image built successfully!"
else
    print_error "Failed to build Docker image"
    exit 1
fi

# Display image information
print_info "\nImage Details:"
docker images "${IMAGE_REGISTRY}/${IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# Push to registry if requested
if [[ "$PUSH_IMAGE" == true ]]; then
    print_info "\nPushing image to registry..."

    if docker push "${FULL_IMAGE_NAME}"; then
        print_success "Image ${FULL_IMAGE_NAME} pushed successfully!"
    else
        print_error "Failed to push image to registry"
        exit 1
    fi

    if docker push "${FULL_IMAGE_NAME_TARGET}"; then
        print_success "Image ${FULL_IMAGE_NAME_TARGET} pushed successfully!"
    else
        print_error "Failed to push image to registry"
        exit 1
    fi
fi

# Print summary
print_success "\n=========================================="
print_success "Build Complete!"
print_success "==========================================\n"
print_info "Built images:"
echo "  - ${FULL_IMAGE_NAME}"
echo "  - ${FULL_IMAGE_NAME_TARGET}"

print_info "\nTo run the container:"
if [[ "$BUILD_TARGET" == "production" ]]; then
    echo "  docker run -d -p 8000:80 --name php-app ${FULL_IMAGE_NAME}"
else
    echo "  docker run -d -p 8000:80 -v \$(pwd)/src:/var/www/html/src --name php-app-dev ${FULL_IMAGE_NAME}"
fi

print_info "\nOr use docker-compose:"
if [[ "$BUILD_TARGET" == "production" ]]; then
    echo "  docker-compose up -d"
else
    echo "  docker-compose --profile dev up -d"
fi

print_success "\nDone! 🚀"