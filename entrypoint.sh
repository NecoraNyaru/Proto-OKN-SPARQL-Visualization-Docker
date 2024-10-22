#!/bin/bash

# Start the Jena Fuseki server with the specified configuration
echo "Starting Jena Fuseki server..."
$JENA_FUSEKI_HOME/fuseki-server --config=$JENA_FUSEKI_HOME/configuration/fuseki-config.ttl &

# Start NGINX to serve the static content
echo "Starting NGINX server to serve static files..."
service nginx start

echo "Servers started successfully."

# Keep the container running
tail -f /dev/null
