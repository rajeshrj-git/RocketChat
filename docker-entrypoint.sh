#!/bin/sh
set -e

# Use a more robust method to wait for MongoDB
if [ -n "$MONGO_URL" ]; then
    echo "Waiting for MongoDB to be ready..."

    # Extract host and port using a standard method.
    # This uses `awk` to handle various URL formats more reliably.
    MONGO_HOST=$(echo "$MONGO_URL" | awk -F[/:] '{print $4}')
    MONGO_PORT=$(echo "$MONGO_URL" | awk -F[/:] '{print $5}')

    if [ -z "$MONGO_HOST" ] || [ -z "$MONGO_PORT" ]; then
        echo "ERROR: Could not parse MONGO_URL: $MONGO_URL"
        exit 1
    fi

    echo "Trying host: $MONGO_HOST, port: $MONGO_PORT"
    # Use wait-for (sh-compatible) or netcat
    while ! nc -z "$MONGO_HOST" "$MONGO_PORT" 2>/dev/null; do
        echo "MongoDB not ready yet. Retrying in 1 second..."
        sleep 1
    done
    echo "MongoDB is ready. Starting application."
fi

exec "$@"