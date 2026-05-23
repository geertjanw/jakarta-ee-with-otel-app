#!/bin/bash

echo "Generating varied request patterns..."

# Health checks pattern
echo "1. Health check requests (100 requests)..."
for i in {1..100}; do
    curl -s http://localhost:8080/gateway/api/health -o /dev/null &
    if [ $((i % 10)) -eq 0 ]; then
        wait
        echo "  $i health checks sent"
    fi
done
wait

# Order creation with different error scenarios
echo "2. Order creation requests (200 requests)..."
PRODUCTS=("laptop" "phone" "tablet" "monitor" "keyboard")
for i in {1..200}; do
    product=${PRODUCTS[$((RANDOM % 5))]}
    # Vary quantity to trigger different behaviors
    quantity=$((RANDOM % 20 + 1))
    customer="cust-$((RANDOM % 100))"
    
    curl -s -X POST http://localhost:8080/gateway/api/orders \
        -H "Content-Type: application/json" \
        -d "{\"product\":\"$product\",\"quantity\":$quantity,\"customerId\":\"$customer\"}" \
        -o /dev/null &
    
    if [ $((i % 20)) -eq 0 ]; then
        wait
        echo "  $i orders sent"
        sleep 1
    fi
done
wait

# Direct service calls (bypassing gateway)
echo "3. Direct service requests (100 requests)..."
for i in {1..50}; do
    curl -s http://localhost:8081/order/api/health -o /dev/null &
    curl -s http://localhost:8082/inventory/api/health -o /dev/null &
done
wait

echo "4. Order retrieval attempts (50 requests)..."
for i in {1..50}; do
    order_id="order-$((RANDOM % 1000))"
    curl -s http://localhost:8080/gateway/api/orders/$order_id -o /dev/null &
    if [ $((i % 10)) -eq 0 ]; then
        wait
    fi
done
wait

echo ""
echo "Varied traffic generation complete!"
echo "Total: ~450 requests with different patterns"
