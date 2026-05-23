#!/bin/bash

echo "Generating massive load - 2000 requests..."
PRODUCTS=("laptop" "phone" "tablet" "monitor" "keyboard" "mouse" "headset" "webcam" "speaker" "charger" "printer" "scanner" "router" "switch" "cable" "desk" "chair" "lamp" "fan" "heater")

for batch in {1..40}; do
    for i in {1..50}; do
        product=${PRODUCTS[$((RANDOM % 20))]}
        quantity=$((RANDOM % 15 + 1))
        customer="cust-$((RANDOM % 2000))"
        
        curl -s -X POST http://localhost:8080/gateway/api/orders \
            -H "Content-Type: application/json" \
            -d "{\"product\":\"$product\",\"quantity\":$quantity,\"customerId\":\"$customer\"}" \
            -o /dev/null &
    done
    wait
    echo "Batch $batch/40 complete ($((batch * 50)) requests)"
    sleep 1
done

echo ""
echo "Massive load complete - 2000 requests sent!"
