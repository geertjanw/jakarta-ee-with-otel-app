#!/bin/bash

echo "Generating OpenTelemetry property files from config.json..."
echo ""

CONFIG_FILE="../data/config.json"

# Check if config.json exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ ERROR: config.json not found!"
    echo ""
    echo "First time setup required:"
    echo "  1. cd ../data"
    echo "  2. cp config.template.json config.json"
    echo "  3. Edit config.json with your Dash0 credentials"
    echo ""
    exit 1
fi
DATASET=$(grep -o '"dataset": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
ENDPOINT=$(grep -o '"endpoint": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
AUTH=$(grep -o '"authorization": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)

echo "Configuration:"
echo "  Dataset: $DATASET"
echo "  Endpoint: $ENDPOINT"
echo ""

# Service mappings: service-name:folder-name
SERVICES="api-gateway:gateway order-service:order inventory-service:inventory payment-service:payment notification-service:notification"

for mapping in $SERVICES; do
    service_name="${mapping%%:*}"
    folder="${mapping##*:}"
    output_file="../${folder}/src/main/resources/otel.properties"

    cat > "$output_file" <<EOF
# ==========================================
# OpenTelemetry Configuration for ${service_name}
# ==========================================
#
# ⚠️  AUTO-GENERATED - DO NOT EDIT DIRECTLY
#
# This file is generated from: app/data/config.json
# To regenerate: cd app/scripts && ./generate-otel-properties.sh
#
# This file contains secrets and is excluded from git.
# See: app/${folder}/src/main/resources/otel.properties.template
# ==========================================

# Service Identity
otel.service.name=${service_name}
otel.service.version=1.0.0
otel.service.namespace=ecommerce

# Dash0 Endpoint Configuration
otel.exporter.otlp.endpoint=${ENDPOINT}
otel.exporter.otlp.protocol=grpc
otel.exporter.otlp.headers=${AUTH},Dash0-Dataset=${DATASET}

# Telemetry Exporters
otel.traces.exporter=otlp
otel.metrics.exporter=otlp
otel.logs.exporter=otlp

# Resource Attributes (optional)
otel.resource.attributes=deployment.environment=local

# Sampling Configuration
# Use always_on for development, adjust for production
otel.traces.sampler=always_on

# SDK Configuration
otel.sdk.disabled=false
EOF

    echo "✓ Created ${folder}/src/main/resources/otel.properties"
done

echo ""
echo "=========================================="
echo "Property files generated successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Update domain.xml files to use classpath:otel.properties"
echo "2. Rebuild services: cd ../gateway && mvn clean package (repeat for all)"
echo "3. Restart domains: ./start-all-services.sh"
echo "4. Verify: ./verify-telemetry.sh"
