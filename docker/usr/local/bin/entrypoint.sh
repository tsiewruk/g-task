#!/bin/bash
set -e

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

exec "$@"
