#!/bin/bash

echo "=========================================="
echo "Migrating Domain Configurations"
echo "=========================================="
echo ""

# Load configuration
CONFIG_FILE="$(cd "$(dirname "$0")/.." && pwd)/data/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ ERROR: config.json not found at $CONFIG_FILE"
    echo "Run: cd ../data && cp config.template.json config.json"
    exit 1
fi

GLASSFISH_BASE=$(grep -o '"glassfishBase": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
GLASSFISH_BASE="${GLASSFISH_BASE}/glassfish"
AGENT_PATH=$(grep -o '"otelAgent": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
BACKUP_DATE=$(date +%Y%m%d-%H%M%S)

DOMAINS=(gateway-domain order-domain inventory-domain payment-domain notification-domain)

# Step 1: Backup all domain.xml files
echo "Step 1: Creating backups..."
for domain in "${DOMAINS[@]}"; do
    DOMAIN_XML="${GLASSFISH_BASE}/domains/${domain}/config/domain.xml"
    BACKUP_FILE="${DOMAIN_XML}.backup-${BACKUP_DATE}"

    cp "$DOMAIN_XML" "$BACKUP_FILE"
    echo "✓ Backed up ${domain}/config/domain.xml"
done

echo ""
echo "Step 2: Updating domain.xml files..."
echo ""

for domain in "${DOMAINS[@]}"; do
    DOMAIN_XML="${GLASSFISH_BASE}/domains/${domain}/config/domain.xml"

    echo "Processing ${domain}..."

    # Create temporary file with updated configuration
    # Remove all old OTEL JVM options and add the new ones
    sed -e '/-Dotel\.service\.name=/d' \
        -e '/-Dotel\.exporter\.otlp\.headers=/d' \
        -e '/-Dotel\.traces\.exporter=/d' \
        -e '/-Dotel\.metrics\.exporter=/d' \
        -e '/-Dotel\.logs\.exporter=/d' \
        -e '/-Dotel\.exporter\.otlp\.endpoint=/d' \
        -e '/-Dotel\.exporter\.otlp\.protocol=/d' \
        "$DOMAIN_XML" > "${DOMAIN_XML}.tmp"

    # Now add the new configuration line after the javaagent line
    sed -e "/-javaagent.*opentelemetry-javaagent\.jar/a\\
        <jvm-options>-Dotel.javaagent.configuration-file=classpath:otel.properties</jvm-options>" \
        "${DOMAIN_XML}.tmp" > "$DOMAIN_XML"

    rm "${DOMAIN_XML}.tmp"
    echo "✓ Updated ${domain}"
done

echo ""
echo "=========================================="
echo "Migration Complete!"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  • Removed 7 individual OTEL JVM options per domain"
echo "  • Added 1 configuration file pointer per domain"
echo "  • Kept javaagent option unchanged"
echo ""
echo "Backups saved with extension: .backup-${BACKUP_DATE}"
echo ""
echo "Next steps:"
echo "1. Rebuild all services with the new property files"
echo "2. Restart all domains"
echo "3. Verify telemetry"
echo ""
echo "To rebuild services, run:"
echo "  cd app/scripts"
echo "  ./rebuild-all-services.sh"
