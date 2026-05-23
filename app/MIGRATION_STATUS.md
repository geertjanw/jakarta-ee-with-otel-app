# Migration Status Report

**Date:** 2026-05-23  
**Migration:** OpenTelemetry config from domain.xml to service resources

## ✅ Completed Steps

1. **Created property files** in all services:
   - ✓ `gateway/src/main/resources/otel.properties`
   - ✓ `order/src/main/resources/otel.properties`
   - ✓ `inventory/src/main/resources/otel.properties`
   - ✓ `payment/src/main/resources/otel.properties`
   - ✓ `notification/src/main/resources/otel.properties`

2. **Updated domain.xml** files:
   - ✓ Removed 7 individual OTEL JVM options
   - ✓ Added `- Dotel.javaagent.configuration-file=classpath:otel.properties`
   - ✓ Kept javaagent option
   - ✓ Backups created

3. **Rebuilt all services**:
   - ✓ All 5 WAR files rebuilt
   - ✓ Property files included in WARs (`WEB-INF/classes/otel.properties`)

4. **Restarted services**:
   - ✓ All 5 domains started successfully
   - ✓ All services responding on their ports

## ❌ Issue Discovered

**Problem:** OpenTelemetry Java agent cannot read properties from WAR file classpath.

**Evidence:**
```
[otel.javaagent] ERROR - Failed to export logs. 
The request could not be executed.
Trying to connect to: http://localhost:4318
```

**Root Cause:**  
The Java agent initializes **before** the WAR is deployed, so `classpath:otel.properties` refers to the JVM classpath, not the application classpath. The property file inside the WAR (`WEB-INF/classes/`) is not visible to the agent at initialization time.

## 🔧 Solution Options

### Option A: External Properties File (RECOMMENDED)

Place `otel.properties` in a location accessible to the JVM:

**1. Create shared config directory:**
```bash
mkdir -p /path/to/your/project/otel-config
```

**2. Copy property files:**
```bash
cp app/gateway/src/main/resources/otel.properties otel-config/gateway-otel.properties
cp app/order/src/main/resources/otel.properties otel-config/order-otel.properties
# ... etc for all services
```

**3. Update domain.xml to point to external file:**
```xml
<jvm-options>-javaagent:/path/to/opentelemetry-javaagent.jar</jvm-options>
<jvm-options>-Dotel.javaagent.configuration-file=file:/path/to/project/otel-config/gateway-otel.properties</jvm-options>
```

**Pros:**
- ✅ Works with Java agent initialization
- ✅ Still version controlled (separate config repo)
- ✅ Easy to update without rebuilding

**Cons:**
- ❌ Config not bundled with WAR
- ❌ Need to sync config files to deployment environment

---

### Option B: Environment Variables (BEST FOR THIS CASE)

Keep domain.xml minimal, use environment variables:

**1. Update domain.xml to remove config-file option:**
```xml
<jvm-options>-javaagent:/path/to/opentelemetry-javaagent.jar</jvm-options>
```

**2. Use startup script with environment variables:**
```bash
# Set from config.json
export OTEL_SERVICE_NAME="api-gateway"
export OTEL_EXPORTER_OTLP_ENDPOINT="https://ingress.europe-west4.gcp.dash0.com:4317"
export OTEL_EXPORTER_OTLP_PROTOCOL="grpc"
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer ...,Dash0-Dataset=app-20260522-02"
export OTEL_TRACES_EXPORTER="otlp"
export OTEL_METRICS_EXPORTER="otlp"
export OTEL_LOGS_EXPORTER="otlp"

asadmin start-domain gateway-domain
```

**Pros:**
- ✅ Works perfectly with Java agent
- ✅ Single source of truth (`config.json`)
- ✅ No separate config files needed
- ✅ Easy to change dataset (update config.json only)

**Cons:**
- ❌ Requires wrapper script to set variables

---

### Option C: Rollback to domain.xml

Revert to original configuration:

```bash
# Restore backups
for domain in gateway-domain order-domain inventory-domain payment-domain notification-domain; do
    cp glassfish8/glassfish/domains/${domain}/config/domain.xml.backup-* \
       glassfish8/glassfish/domains/${domain}/config/domain.xml
done

# Restart domains
pkill -9 -f glassfish
cd app/scripts && ./start-all-services.sh
```

**Pros:**
- ✅ Known working configuration
- ✅ Immediate fix

**Cons:**
- ❌ Back to original problem (config in domain.xml)

---

## 📋 Recommendation

**Implement Option B (Environment Variables)** because:

1. ✅ Solves the Java agent classpath issue
2. ✅ Achieves the goal (config not in domain.xml)
3. ✅ Single source of truth (`app/data/config.json`)
4. ✅ Change dataset in 1 place
5. ✅ Simplest domain.xml (just javaagent path)

This is actually **Solution #2** from `ARCHITECTURE_ALTERNATIVES.md`.

## 🔄 Next Steps

**To complete migration:**

1. Create `start-with-otel-env.sh` script that:
   - Reads `app/data/config.json`
   - Sets environment variables
   - Starts each domain with correct `OTEL_SERVICE_NAME`

2. Update domain.xml files:
   - Remove `-Dotel.javaagent.configuration-file` line
   - Keep only `-javaagent` line

3. Test and verify telemetry

**Would you like me to implement Option B now?**

---

## 📚 Lessons Learned

1. **Java agent initialization timing:**  
   The Java agent runs before WAR deployment, so it can't access resources inside the WAR file.

2. **Classpath vs Application path:**  
   `classpath:` in agent config refers to JVM classpath, not application classpath.

3. **Properties file location matters:**  
   For Java agent config, files must be:
   - External to the application (file system)
   - On the JVM classpath (bootstrap/system)
   - Or use environment variables (best for Docker/cloud)

4. **Environment variables are more portable:**  
   For containerized/cloud deployments, environment variables are the standard approach.

---

## 📊 Current System State

- **Domains:** All 5 running ✓
- **Services:** All 5 responding ✓
- **Telemetry:** NOT sending (config not loaded) ✗
- **Configuration:** Properties in WAR but not accessible to agent ⚠️

**System is functional but telemetry is not working.**

To restore telemetry immediately:
```bash
# Rollback
for domain in gateway-domain order-domain inventory-domain payment-domain notification-domain; do
    cp glassfish8/glassfish/domains/${domain}/config/domain.xml.backup-20260523-150252 \
       glassfish8/glassfish/domains/${domain}/config/domain.xml
done
pkill -9 -f glassfish && sleep 3
cd app/scripts && ./start-all-services.sh
```
