#!/bin/bash

echo "Starting continuous traffic generation..."
echo "Press Ctrl+C to stop"
echo ""

PRODUCTS=("laptop" "phone" "tablet" "monitor" "keyboard" "mouse" "headset" "webcam" "speaker" "charger" "printer" "scanner" "router" "switch" "cable")
TOTAL=0

while true; do
    # Burst pattern - 20 requests
    for i in {1..20}; do
        product=${PRODUCTS[$((RANDOM % 15))]}
        quantity=$((RANDOM % 10 + 1))
        customer="cust-$((RANDOM % 500))"
        
        curl -s -X POST http://localhost:8080/gateway/api/orders \
            -H "Content-Type: application/json" \
            -d "{\"product\":\"$product\",\"quantity\":$quantity,\"customerId\":\"$customer\"}" \
            -o /dev/null &
    done
    
    wait
    TOTAL=$((TOTAL + 20))
    echo "$(date '+%H:%M:%S') - Total requests: $TOTAL"
    
    # Random delay between bursts (1-5 seconds)
    sleep $((RANDOM % 5 + 1))
done
