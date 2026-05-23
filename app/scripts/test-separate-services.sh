#!/bin/bash

# Load configuration
CONFIG_FILE="$(dirname "$0")/../data/config.json"
DATASET=$(grep -o '"dataset": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)

echo "Testing Separate Microservices Architecture"
echo "============================================"
echo ""

# Test health endpoints
echo "1. Testing Health Endpoints..."
echo ""

declare -A SERVICES
SERVICES[gateway]=8080
SERVICES[order]=8081
SERVICES[inventory]=8082
SERVICES[payment]=8083
SERVICES[notification]=8084

for service in gateway order inventory payment notification; do
    port="${SERVICES[$service]}"
    echo -n "  $service (port $port): "
    
    response=$(curl -s http://localhost:$port/$service/api/health 2>/dev/null)
    if [ $? -eq 0 ]; then
        status=$(echo "$response" | jq -r '.status // .service // "ok"' 2>/dev/null)
        echo "✓ $status"
    else
        echo "✗ not responding"
    fi
done

echo ""
echo "2. Testing E2E Order Flow..."
echo ""

# Create order through gateway
ORDER_DATA='{
  "product": "laptop",
  "quantity": 2,
  "amount": 1999.99,
  "customer": "separate-test@example.com"
}'

echo "  Creating order via gateway (port 8080)..."
RESPONSE=$(curl -s -X POST http://localhost:8080/gateway/api/orders \
  -H "Content-Type: application/json" \
  -d "$ORDER_DATA" 2>/dev/null)

echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"

ORDER_ID=$(echo "$RESPONSE" | jq -r '.orderId // empty' 2>/dev/null)

if [ -n "$ORDER_ID" ]; then
    echo ""
    echo "  ✓ Order created: $ORDER_ID"
    echo ""
    echo "  This order created distributed traces across:"
    echo "    - api-gateway (port 8080)"
    echo "    - order-service (port 8081)"
    echo "    - inventory-service (port 8082)"
    echo "    - payment-service (port 8083)"
    echo "    - notification-service (port 8084)"
else
    echo "  ✗ Order creation failed"
fi

echo ""
echo "============================================"
echo "Test complete!"
echo ""
echo "View in Dash0:"
echo "  Dataset: $DATASET"
echo "  You should now see 5 separate services!"
