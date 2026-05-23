#!/bin/bash

# Load configuration
CONFIG_FILE="$(dirname "$0")/../data/config.json"
DATASET=$(grep -o '"dataset": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)

echo "Generating high-volume traffic to Dash0..."

PRODUCTS=("laptop" "phone" "tablet" "monitor" "keyboard" "mouse" "headset" "webcam" "speaker" "charger")
TOTAL=0

for batch in {1..10}; do
    echo "Batch $batch - Sending 50 concurrent requests..."
    
    for i in {1..50}; do
        product=${PRODUCTS[$((RANDOM % 10))]}
        quantity=$((RANDOM % 10 + 1))
        customer="cust-$((RANDOM % 1000))"
        
        curl -s -X POST http://localhost:8080/gateway/api/orders \
            -H "Content-Type: application/json" \
            -d "{\"product\":\"$product\",\"quantity\":$quantity,\"customerId\":\"$customer\"}" \
            -o /dev/null &
    done
    
    wait
    TOTAL=$((TOTAL + 50))
    echo "  Completed $TOTAL requests so far"
    sleep 2
done

echo ""
echo "Traffic generation complete! Sent $TOTAL requests to Dash0."
echo "Dataset: $DATASET"
SERVICES=$(grep -o '"name": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4 | paste -sd ',' -)
echo "Services: $SERVICES"
