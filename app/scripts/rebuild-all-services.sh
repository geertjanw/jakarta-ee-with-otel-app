#!/bin/bash

echo "=========================================="
echo "Rebuilding All Services"
echo "=========================================="
echo ""

cd ..

SERVICES=(gateway order inventory payment notification)
SUCCESS_COUNT=0
FAIL_COUNT=0

for service in "${SERVICES[@]}"; do
    echo "Building ${service}..."

    if (cd "${service}" && mvn clean package -q); then
        echo "✓ ${service} built successfully"
        ((SUCCESS_COUNT++))
    else
        echo "✗ ${service} build failed"
        ((FAIL_COUNT++))
    fi
    echo ""
done

echo "=========================================="
echo "Build Summary"
echo "=========================================="
echo "Success: ${SUCCESS_COUNT}/5"
echo "Failed: ${FAIL_COUNT}/5"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✓ All services built successfully!"
    echo ""
    echo "WAR files location:"
    for service in "${SERVICES[@]}"; do
        echo "  ${service}/target/${service}.war"
    done
    echo ""
    echo "Next steps:"
    echo "1. Stop all domains: pkill -9 -f glassfish"
    echo "2. Start domains: cd scripts && ./start-all-services.sh"
    echo "3. Verify: ./verify-telemetry.sh"
else
    echo "⚠ Some builds failed. Check errors above."
    exit 1
fi
