#!/bin/bash

# Load configuration
CONFIG_FILE="$(cd "$(dirname "$0")/.." && pwd)/data/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ ERROR: config.json not found at $CONFIG_FILE"
    echo "Run: cd ../data && cp config.template.json config.json"
    exit 1
fi

GLASSFISH_BASE=$(grep -o '"glassfishBase": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
ASADMIN="$GLASSFISH_BASE/bin/asadmin"
DOMAINS_DIR="$GLASSFISH_BASE/glassfish/domains"

echo "Starting all GlassFish domains..."
echo ""

# Service configurations: domain:admin_port:http_port:service_name
declare -a DOMAINS=(
    "gateway-domain:4848:8080:api-gateway"
    "order-domain:4849:8081:order-service"
    "inventory-domain:4850:8082:inventory-service"
    "payment-domain:4851:8083:payment-service"
    "notification-domain:4852:8084:notification-service"
)

for domain_config in "${DOMAINS[@]}"; do
    IFS=':' read -r domain_name admin_port http_port service_name <<< "$domain_config"
    
    echo "Starting $service_name ($domain_name)..."
    $ASADMIN start-domain --domaindir "$DOMAINS_DIR" "$domain_name" > /dev/null 2>&1 &
    
    echo "  Domain: $domain_name"
    echo "  Admin: http://localhost:$admin_port"
    echo "  HTTP:  http://localhost:$http_port"
    echo ""
done

echo "Waiting for domains to start..."
sleep 15

echo ""
echo "Checking domain status..."
for domain_config in "${DOMAINS[@]}"; do
    IFS=':' read -r domain_name admin_port http_port service_name <<< "$domain_config"
    
    if curl -s http://localhost:$http_port/ > /dev/null 2>&1; then
        echo "  ✓ $service_name - Running on port $http_port"
    else
        echo "  ✗ $service_name - Not responding on port $http_port"
    fi
done

echo ""
echo "All domains started!"
