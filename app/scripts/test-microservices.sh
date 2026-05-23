#!/bin/bash

echo "Testing Microservices Architecture"
echo "===================================="
echo ""

# Test health endpoints
echo "1. Testing Health Endpoints..."
for service in gateway:8080 order:8081 inventory:8082 payment:8083 notification:8084; do
    name=${service%%:*}
    port=${service##*:}
    echo -n "  $name: "
    curl -s http://localhost:$port/$name/api/health | jq -r '.status // "error"'
done

echo ""
echo "2. Testing E2E Order Flow..."

# Create an order through the gateway
ORDER_DATA='{
  "product": "laptop",
  "quantity": 1,
  "amount": 1299.99,
  "customer": "john@example.com"
}'

echo "  Creating order via gateway..."
RESPONSE=$(curl -s -X POST http://localhost:8080/gateway/api/orders \
  -H "Content-Type: application/json" \
  -d "$ORDER_DATA")

echo "$RESPONSE" | jq '.'

ORDER_ID=$(echo "$RESPONSE" | jq -r '.orderId // empty')

if [ -n "$ORDER_ID" ]; then
    echo ""
    echo "3. Fetching Order Details..."
    curl -s http://localhost:8080/gateway/api/orders/$ORDER_ID | jq '.'

    echo ""
    echo "4. Checking Inventory..."
    curl -s http://localhost:8082/inventory/api/stock/laptop | jq '.'

    echo ""
    echo "5. Checking Notifications..."
    curl -s http://localhost:8084/notification/api/notifications/$ORDER_ID | jq '.'
fi

echo ""
echo "===================================="
echo "Test complete!"
