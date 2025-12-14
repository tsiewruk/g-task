#!/bin/bash
set -e

# ======================================
# Entrypoint Script - Load Environment Variables
# ======================================

echo "🚀 Starting PHP Application Container..."

# Load environment variables from /etc/environment if it exists
if [ -f /etc/environment ]; then
    echo "📝 Loading environment variables from /etc/environment..."

    # Export all variables from /etc/environment
    set -a
    source /etc/environment
    set +a

    echo "✓ Environment variables loaded successfully"
else
    echo "⚠️  /etc/environment not found, using default environment"
fi

# Display loaded configuration (without sensitive data)
echo "Configuration loaded:"
echo "  - APP_ENV: ${APP_ENV:-not set}"
echo "  - APP_NAME: ${APP_NAME:-not set}"
echo "  - MYSQL_HOST: ${MYSQL_HOST:-not set}"
echo "  - REDIS_HOST: ${REDIS_HOST:-not set}"

# Note: Docker Compose handles service dependencies via health checks
# The app will wait for MySQL and Redis to be healthy before starting
echo "✓ Dependencies are ready (managed by Docker Compose health checks)"

# Set proper permissions
chown -R www-data:www-data /var/www/html 2>/dev/null || true

echo "✅ Application ready - starting Apache..."
echo "============================================"

# Execute the main command (apache2-foreground)
exec "$@"
