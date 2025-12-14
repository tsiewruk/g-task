#!/bin/bash

# ======================================
# Test Script - Verify PHP PoC Stack
# ======================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

TESTS_PASSED=0
TESTS_FAILED=0

test_service() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}

    print_info "Testing $name..."

    if response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>&1); then
        if [ "$response" -eq "$expected_code" ]; then
            print_success "$name is responding (HTTP $response)"
            ((TESTS_PASSED++))
            return 0
        else
            print_error "$name returned HTTP $response (expected $expected_code)"
            ((TESTS_FAILED++))
            return 1
        fi
    else
        print_error "$name is not responding"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_docker_service() {
    local service=$1

    print_info "Checking Docker service: $service..."

    if docker-compose ps | grep -q "$service.*Up"; then
        print_success "$service is running"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "$service is not running"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_php_extension() {
    local extension=$1

    print_info "Checking PHP extension: $extension..."

    if docker-compose exec -T php-app php -m | grep -qi "^$extension$"; then
        print_success "$extension is loaded"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "$extension is not loaded"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo ""
print_info "================================================"
print_info "PHP PoC Stack - Comprehensive Test Suite"
print_info "================================================"
echo ""

# Test 1: Docker services
print_info "=== Test 1: Docker Services ==="
test_docker_service "php_poc_traefik"
test_docker_service "php_poc_app"
test_docker_service "php_poc_mysql"
test_docker_service "php_poc_redis"
echo ""

# Test 2: HTTP endpoints
print_info "=== Test 2: HTTP Endpoints ==="
test_service "PHP Application" "http://app.localhost"
test_service "Traefik Dashboard" "http://localhost:8080/dashboard/" 200
test_service "phpinfo()" "http://app.localhost/?phpinfo=1"
echo ""

# Test 3: PHP extensions
print_info "=== Test 3: PHP Extensions ==="
test_php_extension "PDO"
test_php_extension "pdo_mysql"
test_php_extension "redis"
test_php_extension "opcache"
echo ""

# Test 4: Database connectivity
print_info "=== Test 4: Database Connectivity ==="
print_info "Testing MySQL connection..."
if docker-compose exec -T mysql mysqladmin ping -h localhost -u root -proot_password &> /dev/null; then
    print_success "MySQL is accessible"
    ((TESTS_PASSED++))
else
    print_error "MySQL is not accessible"
    ((TESTS_FAILED++))
fi

print_info "Testing Redis connection..."
if docker-compose exec -T redis redis-cli ping &> /dev/null; then
    print_success "Redis is accessible"
    ((TESTS_PASSED++))
else
    print_error "Redis is not accessible"
    ((TESTS_FAILED++))
fi
echo ""

# Test 5: Environment variables
print_info "=== Test 5: Environment Variables ==="
print_info "Checking if /etc/environment is loaded..."

if docker-compose exec -T php-app bash -c '[ -n "$APP_ENV" ] && echo "OK"' | grep -q "OK"; then
    print_success "Environment variables are loaded"
    ((TESTS_PASSED++))
else
    print_error "Environment variables are not loaded"
    ((TESTS_FAILED++))
fi
echo ""

# Test 6: Volume mounts
print_info "=== Test 6: Volume Mounts ==="
print_info "Checking MySQL volume..."
if docker volume ls | grep -q "php_poc_mysql_data"; then
    print_success "MySQL volume exists"
    ((TESTS_PASSED++))
else
    print_error "MySQL volume is missing"
    ((TESTS_FAILED++))
fi

print_info "Checking Redis volume..."
if docker volume ls | grep -q "php_poc_redis_data"; then
    print_success "Redis volume exists"
    ((TESTS_PASSED++))
else
    print_error "Redis volume is missing"
    ((TESTS_FAILED++))
fi
echo ""

# Summary
print_info "================================================"
print_info "Test Summary"
print_info "================================================"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    print_success "All tests passed! ($TESTS_PASSED/$((TESTS_PASSED + TESTS_FAILED)))"
    echo ""
    print_info "Your PHP PoC stack is working correctly!"
    print_info ""
    print_info "Access points:"
    echo "  - Application:    http://app.localhost"
    echo "  - Traefik:        http://traefik.localhost"
    echo "  - phpinfo():      http://app.localhost/?phpinfo=1"
    exit 0
else
    print_error "Some tests failed: $TESTS_FAILED failed, $TESTS_PASSED passed"
    echo ""
    print_warning "Please check the logs:"
    echo "  docker-compose logs"
    exit 1
fi
