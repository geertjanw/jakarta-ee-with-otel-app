#!/bin/bash

# Load configuration
CONFIG_FILE="$(dirname "$0")/../data/config.json"
DATASET=$(grep -o '"dataset": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)

echo "Confirming new dataset: $DATASET"
echo "Sending 100 test requests..."
echo ""

PRODUCTS=("laptop" "phone" "tablet" "monitor" "keyboard")
for i in {1..100}; do
    product=${PRODUCTS[$((RANDOM % 5))]}
    quantity=$((RANDOM % 5 + 1))
    customer="dataset-confirm-$i"
    
    curl -s -X POST http://localhost:8080/gateway/api/orders \
        -H "Content-Type: application/json" \
        -d "{\"product\":\"$product\",\"quantity\":$quantity,\"customerId\":\"$customer\"}" \
        -o /dev/null &
    
    if [ $((i % 20)) -eq 0 ]; then
        wait
        echo "Sent $i requests to $DATASET"
    fi
done
wait

echo ""
echo "✓ 100 confirmation requests sent to dataset: $DATASET"
echo ""
echo "Dataset Configuration:"
echo "  Dataset Name: $DATASET"
echo "  Service Names:"
grep -o '"name": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4 | sed 's/^/    - /'
