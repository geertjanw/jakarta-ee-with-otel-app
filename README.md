# Jakarta EE with OpenTelemetry Application

A production-ready Jakarta EE application with 5 microservices, fully instrumented with OpenTelemetry for distributed tracing in Dash0.

## Quick Start (5 minutes)

### 1. Copy configuration template
- `cd app/data`
- `cp config.template.json config.json`

### 2. Edit with your Dash0 credentials

Replace:
- `YOUR_DATASET_NAME`
- `YOUR_REGION`
- `YOUR_AUTH_TOKEN_HERE`
- All paths in the "paths" section

### 3. Generate OpenTelemetry configs
- `cd ../scripts`
 `./generate-otel-properties.sh`

### 4. Build all services
`./rebuild-all-services.sh`

### 5. Start services
`./start-all-services.sh`

### 6. Verify telemetry
`./verify-telemetry.sh`

### 7. Test the setup
`./test-separate-services.sh`

### 8. Generate traffic for Dash0
`./traffic-moderate.sh`

**For detailed script documentation, see [app/scripts/README.md](app/scripts/README.md)**

---

## Architecture

```
┌──────────────┐
│  API Gateway │  Port 8080
└──────┬───────┘
       │
       ▼
┌──────────────┐        ┌─────────────────┐
│ Order Service│───────▶│ Inventory Service│  Port 8082
│  Port 8081   │        └─────────────────┘
└──────┬───────┘
       │
       ├────────▶┌──────────────────┐
       │         │ Payment Service   │  Port 8083
       │         └──────────────────┘
       │
       └────────▶┌─────────────────────┐
                 │ Notification Service│  Port 8084
                 └─────────────────────┘
```

### Five Independent Services

Each service runs in its own GlassFish domain with a unique service name for Dash0:

| Service | Port | Context | OpenTelemetry Service Name |
|---------|------|---------|----------------------------|
| API Gateway | 8080 | `/gateway` | `api-gateway` |
| Order Service | 8081 | `/order` | `order-service` |
| Inventory Service | 8082 | `/inventory` | `inventory-service` |
| Payment Service | 8083 | `/payment` | `payment-service` |
| Notification Service | 8084 | `/notification` | `notification-service` |

### Request Flow

```
Client → POST /gateway/api/orders
  ↓ (50-100ms)
Gateway → POST /order/api/orders
  ↓ (100-200ms)
Order Service → 3 parallel calls:
  ├→ POST /inventory/api/check (50-150ms)
  ├→ POST /payment/api/process (100-300ms)
  └→ POST /notification/api/send (80-200ms)

Total: ~400-800ms end-to-end
Complete distributed trace in Dash0!
```

---

## Service Endpoints

- Gateway: http://localhost:8080/gateway/api
- Order: http://localhost:8081/order/api
- Inventory: http://localhost:8082/inventory/api
- Payment: http://localhost:8083/payment/api
- Notification: http://localhost:8084/notification/api

### Health Checks

```bash
curl http://localhost:8080/gateway/api/health
curl http://localhost:8081/order/api/health      # No health endpoint
curl http://localhost:8082/inventory/api/health
curl http://localhost:8083/payment/api/health
curl http://localhost:8084/notification/api/health
```

### Create Order

```bash
curl -X POST http://localhost:8080/gateway/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "product": "laptop",
    "quantity": 1,
    "amount": 1299.99,
    "customer": "test@example.com"
  }'
```

---

## Configuration Strategy

### Overview

The project uses a **template-based configuration strategy** where secrets are kept out of git while maintaining a clear setup process for new developers.

### Files Summary

| File | In Git? | Contains Secrets? | Purpose |
|------|---------|-------------------|---------|
| `config.template.json` | Yes | No | Template with placeholders |
| `config.json` | No | Yes | Actual credentials (local only) |
| `otel.properties.template` | Yes | No | Template for OTel config |
| `otel.properties` | No | Yes | Generated from config.json |
| `generate-otel-properties.sh` | Yes | No | Generator script |

### Configuration File Structure

```json
{
  "paths": {
    "projectRoot": "/absolute/path/to/your/project",
    "glassfishBase": "/absolute/path/to/glassfish8",
    "otelAgent": "/absolute/path/to/opentelemetry-javaagent.jar"
  },
  "dash0": {
    "dataset": "YOUR_DATASET_NAME",
    "endpoint": "https://ingress.YOUR_REGION.gcp.dash0.com:4317",
    "protocol": "grpc",
    "authorization": "Bearer YOUR_AUTH_TOKEN_HERE"
  },
  "services": [...]
}
```

### Path Configuration

All user-specific and environment-specific paths are configured in `app/data/config.json`:

| Field | Purpose | Example |
|-------|---------|---------|
| `projectRoot` | Root directory of the project | `/Users/yourname/projects/jakarta-ee-with-otel-app` |
| `glassfishBase` | GlassFish installation directory | `/Users/yourname/projects/jakarta-ee-with-otel-app/glassfish8` |
| `otelAgent` | OpenTelemetry Java agent JAR | `/Users/yourname/projects/jakarta-ee-with-otel-app/opentelemetry-javaagent.jar` |

### Workflow

#### 1. Initial Setup (Once per developer)

```bash
# Clone repository
git clone <repo>

# Copy template and add credentials
cd app/data
cp config.template.json config.json
vim config.json  # Add actual Dash0 credentials and paths

# Generate property files
cd ../scripts
./generate-otel-properties.sh

# Build and deploy
./rebuild-all-services.sh
./start-all-services.sh
```

#### 2. Daily Workflow - Change Dataset or Credentials

```bash
# Edit config (single source of truth)
vim app/data/config.json

# Regenerate properties
cd app/scripts
./generate-otel-properties.sh

# Rebuild and deploy
./rebuild-all-services.sh
pkill -9 -f glassfish && ./start-all-services.sh
```

#### 3. Test Traffic

```bash
cd app/scripts

# Moderate load (500 requests)
./traffic-moderate.sh

# Stress test (2000 requests)
./traffic-stress.sh

# Continuous (until Ctrl+C)
./traffic-continuous.sh
```

### Security Model

**What's Protected:**
1. **Dash0 Authorization Token** - Never committed to git, stored only in local `config.json`
2. **Dataset Names** - May contain environment info (dev/staging/prod), kept out of git for flexibility

**What's in Git:**
1. **Structure (Templates)** - Shows developers what to configure, no actual secrets
2. **Generator Script** - Logic for creating config files, no hardcoded credentials

---

## Dash0 Observability

### Configuration

**Dataset:** Configured in `app/data/config.json`  
**Endpoint:** `https://ingress.europe-west4.gcp.dash0.com:4317`  
**Protocol:** gRPC (OTLP)

Configuration files:
```
glassfish8/glassfish/domains/gateway-domain/config/domain.xml
glassfish8/glassfish/domains/order-domain/config/domain.xml
glassfish8/glassfish/domains/inventory-domain/config/domain.xml
glassfish8/glassfish/domains/payment-domain/config/domain.xml
glassfish8/glassfish/domains/notification-domain/config/domain.xml
```

OpenTelemetry is configured via JVM options in domain.xml files.

### What Gets Sent to Dash0

**Distributed Traces:**
- Complete request flow across all 5 services
- Parent-child span relationships
- HTTP method, path, status codes
- Request/response timing
- Trace context propagation

**JVM Metrics:**
- `jvm_memory_used_bytes` - Memory usage per pool
- `jvm_gc_duration_seconds` - GC pause times
- `jvm_threads_count` - Thread counts
- `jvm_classes_loaded` - Class loading

**HTTP Server Metrics:**
- `http_server_request_duration_seconds` - Request latency
- Request counts by method and status code
- Error rates per service

### View in Dash0 Web UI

1. Go to **https://app.dash0.com**
2. Select dataset: Check `app/data/config.json` for current dataset name
3. **Services** tab → See all 5 services with dependency map
4. **Traces** tab → View complete distributed traces
5. **Metrics** tab → Monitor JVM and HTTP metrics

### Query with CLI

```bash
# View recent spans
./dash0 spans query --from now-10m --limit 20

# View by service name
./dash0 spans query --from now-10m -o csv \
  --column service.name --column name --column http.request.method

# JVM metrics
./dash0 metrics instant --promql 'jvm_memory_used_bytes'

# HTTP request rate
./dash0 metrics instant \
  --promql 'rate(http_server_request_duration_seconds_count[5m])'

# Count total spans
./dash0 spans query --from now-1h --limit 1000 -o csv | wc -l
```

---

## Technology Stack

- **Language:** Java 21
- **Framework:** Jakarta EE 10.0.0
- **Application Server:** GlassFish 8.0.2
- **HTTP Server:** Grizzly (embedded in GlassFish)
- **REST API:** JAX-RS (Jakarta REST)
- **Build Tool:** Maven 3.8+
- **Observability:** OpenTelemetry Java Agent 2.28.0
- **Monitoring Platform:** Dash0

### Automatic Instrumentation

The OpenTelemetry Java agent automatically instruments:
- Grizzly HTTP server
- JAX-RS REST endpoints
- JAX-RS Client (service-to-service calls)
- Thread context propagation
- JVM runtime metrics

**No code changes required!**

---

## Setup Details

### Prerequisites

- Java 21 (Temurin recommended)
- Maven 3.8+
- GlassFish 8.0.2 (included)
- OpenTelemetry Java Agent (included)

### Manual Setup Steps

If automated scripts don't work, follow these manual steps:

#### 1. Stop All GlassFish Processes

```bash
pkill -f glassfish
sleep 3
```

#### 2. Add OpenTelemetry Agent to Each Domain

```bash
GLASSFISH_BASE="/path/to/your/project/glassfish8"
OTEL_AGENT="/path/to/your/project/opentelemetry-javaagent.jar"

# For each domain, add JVM option (only needed once per domain)
$GLASSFISH_BASE/bin/asadmin --port 4848 create-jvm-options \
  "-javaagent\\:$OTEL_AGENT"

# Repeat for ports: 4849, 4850, 4851, 4852
```

#### 3. Start Each Domain

```bash
cd /path/to/your/project

# Start all domains
for domain in gateway-domain order-domain inventory-domain payment-domain notification-domain; do
    ./glassfish8/bin/asadmin start-domain \
        --domaindir ./glassfish8/glassfish/domains $domain &
done

# Wait 2-3 minutes for startup
```

#### 4. Verify Domains are Running

```bash
for port in 8080 8081 8082 8083 8084; do
  echo -n "Port $port: "
  curl -s http://localhost:$port/ > /dev/null && echo "✓" || echo "✗"
done
```

#### 5. Deploy Services

```bash
cd app

# Deploy to each domain
./glassfish8/bin/asadmin --port 4848 deploy --force=true gateway/target/gateway.war
./glassfish8/bin/asadmin --port 4849 deploy --force=true order/target/order.war
./glassfish8/bin/asadmin --port 4850 deploy --force=true inventory/target/inventory.war
./glassfish8/bin/asadmin --port 4851 deploy --force=true payment/target/payment.war
./glassfish8/bin/asadmin --port 4852 deploy --force=true notification/target/notification.war
```

---

## Troubleshooting

### "config.json not found" Error

```bash
❌ ERROR: config.json not found!

First time setup required:
  1. cd app/data
  2. cp config.template.json config.json
  3. Edit config.json with your Dash0 credentials and paths
```

### Domains Won't Start

Check logs:
```bash
tail -100 glassfish8/glassfish/domains/<domain-name>/logs/server.log
```

Common issues:
- Port already in use: `lsof -i :<port>` then `kill -9 <pid>`
- KeyTool timeout during domain creation
- Java version mismatch

### No Data in Dash0

Verify OpenTelemetry agent is loaded:
```bash
ps aux | grep "javaagent.*opentelemetry" | grep -v grep
```

Should show the agent path for each domain.

Check dataset configuration:
```bash
# View configured dataset
cat app/data/config.json | grep dataset

# Verify domain.xml files match
grep "Dash0-Dataset" glassfish8/glassfish/domains/*/config/domain.xml
```

Generate test traffic:
```bash
cd app/scripts
./test-separate-services.sh
./generate-traffic.sh
```

Wait 30-60 seconds, then query:
```bash
./dash0 spans query --from now-5m --limit 10
```

### Service Communication Errors

Verify all services are running:
```bash
for port in 8080 8081 8082 8083 8084; do
  curl -s http://localhost:$port/ | head -1
done
```

Check service URLs are correct in code:
- Gateway calls Order on port 8081
- Order calls Inventory (8082), Payment (8083), Notification (8084)

### Port Conflicts

If ports are in use:
```bash
# Find process using port
lsof -i :8080

# Kill process
kill -9 <PID>
```

### Path Doesn't Exist

If scripts fail with "No such file or directory":

**Check your paths:**
```bash
# View current config
cat app/data/config.json | grep -A 5 '"paths"'

# Verify paths exist
ls -ld /your/glassfishBase/path
ls -f /your/otelAgent/path
```

**Fix config:**
```bash
vim app/data/config.json
# Update paths to actual locations
```

**Note:** Always use absolute paths, not relative paths in `config.json`.

### Secrets Accidentally Committed

If config.json was committed:
```bash
# Remove from git, keep local
git rm --cached app/data/config.json

# Verify .gitignore blocks it
git check-ignore -v app/data/config.json

# Commit the removal
git commit -m "Remove config.json from tracking"

# IMPORTANT: Secret is still in git history!
# For real credentials, consider:
# - Revoking and rotating the token
# - Using git-filter-repo to rewrite history
```

---

## Project Structure

```
jakarta-ee-with-otel-app/
├── README.md                      # This file
├── dash0                          # Dash0 CLI tool
├── opentelemetry-javaagent.jar   # OpenTelemetry agent
│
├── glassfish8/                    # GlassFish 8.0.2
│   └── glassfish/domains/
│       ├── gateway-domain/        # Port 8080, admin 4848
│       ├── order-domain/          # Port 8081, admin 4849
│       ├── inventory-domain/      # Port 8082, admin 4850
│       ├── payment-domain/        # Port 8083, admin 4851
│       └── notification-domain/   # Port 8084, admin 4852
│
└── app/                 # Application code
    ├── data/                      # Configuration data
    │   ├── config.json            # Centralized config (dataset, services, ports)
    │   └── README.md              # Configuration documentation
    │
    ├── gateway/                   # API Gateway service
    │   ├── src/main/java/...
    │   ├── pom.xml
    │   └── target/gateway.war
    │
    ├── order/                     # Order orchestration
    │   ├── src/main/java/...
    │   ├── pom.xml
    │   └── target/order.war
    │
    ├── inventory/                 # Stock management
    │   ├── src/main/java/...
    │   ├── pom.xml
    │   └── target/inventory.war
    │
    ├── payment/                   # Payment processing
    │   ├── src/main/java/...
    │   ├── pom.xml
    │   └── target/payment.war
    │
    ├── notification/              # Async notifications
    │   ├── src/main/java/...
    │   ├── pom.xml
    │   └── target/notification.war
    │
    └── scripts/                   # Management scripts
        ├── README.md              # Comprehensive script documentation
        ├── start-all-services.sh  # Start all domains
        ├── verify-telemetry.sh    # Verify Dash0 connection
        ├── test-separate-services.sh  # Test E2E flow
        ├── test-microservices.sh  # Detailed JSON test
        ├── traffic-confirm-dataset.sh  # Dataset confirmation (100 requests)
        ├── traffic-moderate.sh    # Moderate load (500 requests)
        ├── traffic-continuous.sh  # Continuous background traffic
        ├── traffic-stress.sh      # Stress test (2000 requests)
        └── traffic-varied.sh      # Mixed patterns (450 requests)
```

---

## Performance Characteristics

- **Throughput:** ~5-10 orders/second (with simulated delays)
- **Latency:** 400-800ms end-to-end
- **Success Rate:** ~90-95% (payment service has 5% failure rate)
- **Service Calls:** 5 per successful order
- **Trace Spans:** 5-6 spans per order

## Service Details

### API Gateway
- **Responsibilities:** Entry point, request routing, enrichment
- **Endpoints:** 
  - `GET /api/health`
  - `POST /api/orders`
  - `GET /api/orders/{orderId}`
- **Processing Time:** 50-100ms

### Order Service
- **Responsibilities:** Business logic coordinator, orchestrates other services
- **Endpoints:**
  - `POST /api/orders` - Orchestrates inventory, payment, notification
  - `GET /api/orders/{orderId}`
- **Processing Time:** 100-200ms
- **Dependencies:** Inventory, Payment, Notification

### Inventory Service
- **Responsibilities:** Stock management, inventory reservation
- **Endpoints:**
  - `POST /api/check` - Check and reserve inventory
  - `GET /api/stock/{product}`
  - `GET /api/health`
- **Initial Stock:** laptop: 50, phone: 100, tablet: 30, monitor: 25
- **Processing Time:** 50-150ms

### Payment Service
- **Responsibilities:** Payment processing, transaction management
- **Endpoints:**
  - `POST /api/process` - Process payment
  - `GET /api/transaction/{transactionId}`
  - `GET /api/health`
- **Success Rate:** 95% (90% for amounts > $1000)
- **Processing Time:** 100-300ms

### Notification Service
- **Responsibilities:** Send notifications (email, SMS), async processing
- **Endpoints:**
  - `POST /api/send` - Send notification
  - `GET /api/notifications/{orderId}`
  - `GET /api/health`
- **Processing Time:** 80-200ms (async, doesn't block)

---

## Team Collaboration

### For New Team Members

**What's in git:**
```
app/data/config.template.json          ✓ Template with placeholders
app/*/src/main/resources/*.template    ✓ Property templates
app/scripts/generate-otel-properties.sh ✓ Generator script
```

**What's NOT in git (you create locally):**
```
app/data/config.json                   ✗ Your credentials
app/*/src/main/resources/otel.properties ✗ Generated files
```

### Getting Credentials

New team members need:
1. **Dash0 account access**
2. **Authorization token** (from Dash0 dashboard)
3. **Dataset name** (from team documentation)

Share these via secure channels (1Password, Vault, etc.), not in code.

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Deploy

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Generate config from secrets
        env:
          DASH0_TOKEN: ${{ secrets.DASH0_TOKEN }}
          DASH0_DATASET: ${{ secrets.DASH0_DATASET }}
        run: |
          # Create config.json from template
          jq '.dash0.authorization = "Bearer '"$DASH0_TOKEN"'" | 
              .dash0.dataset = "'"$DASH0_DATASET"'"' \
            app/data/config.template.json > app/data/config.json
      
      - name: Generate OTel properties
        run: cd app/scripts && ./generate-otel-properties.sh
      
      - name: Build services
        run: cd app/scripts && ./rebuild-all-services.sh
```

---

## Security Best Practices

**DO:**
- Store credentials in secure vaults (1Password, HashiCorp Vault, AWS Secrets Manager)
- Use environment variables in CI/CD
- Rotate tokens regularly
- Use different datasets for dev/staging/production

**DON'T:**
- Commit `config.json` to git
- Share credentials in Slack/email
- Use production credentials in development
- Check generated `otel.properties` files into git

---

## Summary

This application architecture demonstrates:

* **Distributed Tracing** - Complete trace context propagation across all 5 services  
* **Service Dependency Mapping** - Visualize service relationships in Dash0  
* **Automatic Instrumentation** - Zero code changes required  
* **JVM & HTTP Metrics** - Real-time performance monitoring  
* **Production-Ready** - Proper error handling, simulated failures  
* **Secure Configuration** - Template-based secret management
* **Portable Setup** - Configurable paths for any environment

Perfect for demonstrating Dash0's distributed tracing and observability capabilities with Jakarta EE applications!

---

**Configuration:** `app/data/config.json`  
**View in Dash0:** https://app.dash0.com
