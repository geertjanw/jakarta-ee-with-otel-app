# Microservices Management Scripts

This folder contains shell scripts for managing and testing the GlassFish microservices architecture with Dash0 observability.

## Quick Start

cd app/scripts

### 1. Start all services
./start-all-services.sh

### 2. Verify telemetry is flowing
./verify-telemetry.sh

### 3. Test the system
./test-separate-services.sh

### 4. Generate traffic
./traffic-moderate.sh

## Architecture Overview

The system consists of 5 microservices running on separate GlassFish domains:

| Service | Domain | HTTP Port | Admin Port | Purpose |
|---------|--------|-----------|------------|---------|
| api-gateway | gateway-domain | 8080 | 4848 | Entry point, routes requests |
| order-service | order-domain | 8081 | 4849 | Order management |
| inventory-service | inventory-domain | 8082 | 4850 | Stock management |
| payment-service | payment-domain | 8083 | 4851 | Payment processing |
| notification-service | notification-domain | 8084 | 4852 | Event notifications |

**Dash0 Configuration:**
- Dataset: Configured in `app/data/config.json`
- Endpoint: `https://ingress.europe-west4.gcp.dash0.com:4317`
- Protocol: OTLP over gRPC
- OpenTelemetry Java Agent: v2.28.0

**Configuration Management:**
All scripts read the current dataset and service configuration from `../data/config.json`. To change the dataset, update the JSON file and restart services.

## Scripts Overview

| Category | Script | Volume/Type | Purpose |
|----------|--------|-------------|---------|
| **Management** | `start-all-services.sh` | - | Start all 5 GlassFish domains |
| **Verification** | `verify-telemetry.sh` | 10 test requests | Verify Dash0 telemetry connections |
| **Verification** | `test-separate-services.sh` | E2E test | Test all microservices end-to-end |
| **Verification** | `test-microservices.sh` | Detailed test | Detailed test with JSON output |
| **Traffic** | `traffic-confirm-dataset.sh` | 100 requests | Confirm dataset configuration |
| **Traffic** | `traffic-moderate.sh` | 500 requests | Moderate controlled load |
| **Traffic** | `traffic-continuous.sh` | Continuous | Background traffic until stopped |
| **Traffic** | `traffic-stress.sh` | 2000 requests | High-volume stress test |
| **Traffic** | `traffic-varied.sh` | 450 requests | Mixed traffic patterns |

## Scripts Usage Guide

### 1. Service Management

#### `start-all-services.sh`
**Purpose:** Start all 5 GlassFish domains in parallel  
**Usage:**
```bash
./start-all-services.sh
```
**When to use:** First step after system restart or when all services are stopped  
**What it does:**
- Starts all 5 domains in parallel
- Waits 15 seconds for startup
- Verifies each service is responding on its HTTP port
- Shows admin and HTTP ports for each service

**Expected output:** All services show ✓ status

---

### 2. Testing & Verification

#### `verify-telemetry.sh`
**Purpose:** Verify OpenTelemetry agents are loaded and data is flowing to Dash0  
**Usage:**
```bash
./verify-telemetry.sh
```
**When to use:** To confirm all services are sending telemetry to Dash0  
**What it does:**
- Checks OpenTelemetry agent is loaded in all 5 domains
- Verifies active TCP connections to Dash0 endpoint (port 4317)
- Reads dataset configuration from all domain.xml files
- Tests health endpoints on all 5 services
- Sends 10 test requests
- Reports connection status before and after traffic

**Expected output:** "✓ CONFIRMED: Data is flowing to Dash0" with 5+ active connections

---

#### `test-separate-services.sh`
**Purpose:** Comprehensive E2E test of all microservices  
**Usage:**
```bash
./test-separate-services.sh
```
**When to use:** After starting services or to verify the full system is working  
**What it does:**
- Tests health endpoints for all 5 services
- Creates a test order through the gateway
- Verifies distributed tracing across all services
- Confirms order flow: gateway → order → inventory → payment → notification

**Expected output:** All health checks pass (✓) and order is created successfully

---

#### `test-microservices.sh`
**Purpose:** Detailed E2E test with order tracking  
**Usage:**
```bash
./test-microservices.sh
```
**When to use:** When you need detailed JSON responses from each service  
**What it does:**
- Tests health endpoints
- Creates an order with specific product data (laptop)
- Fetches order details
- Checks inventory stock levels
- Retrieves notification status for the order

**Dependencies:** Requires `jq` for JSON parsing  
**Expected output:** Detailed JSON responses from each service

---

### 3. Traffic Generation

All traffic generation scripts follow the `traffic-*` naming pattern and send different types of load to test Dash0 observability.

#### `traffic-confirm-dataset.sh`
**Purpose:** Confirm dataset configuration with controlled load  
**Usage:**
```bash
./traffic-confirm-dataset.sh
```
**When to use:** After changing dataset configuration to verify Dash0 integration  
**Traffic pattern:** 100 requests in batches of 20  
**What it does:**
- Sends 100 test requests with varied product/quantity combinations
- Runs 20 concurrent requests at a time
- Uses random products: laptop, phone, tablet, monitor, keyboard
- Shows progress every 20 requests

**Expected output:** "✓ 100 confirmation requests sent to dataset: app-20260522-02"

---

#### `traffic-moderate.sh`
**Purpose:** Generate moderate traffic in controlled batches  
**Usage:**
```bash
./traffic-moderate.sh
```
**When to use:** To generate substantial telemetry data for testing Dash0 dashboards  
**Traffic pattern:** 500 requests (10 batches of 50)  
**What it does:**
- Sends 500 total requests in controlled batches
- Uses 10 different products
- 2-second pause between batches
- Shows progress after each batch

**Expected output:** "Traffic generation complete! Sent 500 requests to Dash0."

---

#### `traffic-continuous.sh`
**Purpose:** Generate continuous background traffic until stopped  
**Usage:**
```bash
./traffic-continuous.sh
# Press Ctrl+C to stop
```
**When to use:** For long-running observability tests or demos  
**Traffic pattern:** Continuous bursts of 20 requests with random delays  
**What it does:**
- Runs indefinitely until manually stopped (Ctrl+C)
- Sends bursts of 20 requests
- Random 1-5 second delays between bursts
- Timestamps each batch
- Uses 15 different products

**Expected output:** Continuous timestamp-prefixed progress (e.g., "13:45:23 - Total requests: 240")

---

#### `traffic-stress.sh`
**Purpose:** High-volume stress test  
**Usage:**
```bash
./traffic-stress.sh
```
**When to use:** For load testing or generating large datasets in Dash0  
**Traffic pattern:** 2000 requests (40 batches of 50)  
**What it does:**
- Sends 2000 total requests rapidly
- Uses 20 different products
- Minimal delays between batches (1 second)
- Designed to test system capacity and performance

**Expected output:** "Massive load complete - 2000 requests sent!"

---

#### `traffic-varied.sh`
**Purpose:** Generate diverse request patterns for realistic testing  
**Usage:**
```bash
./traffic-varied.sh
```
**When to use:** To create realistic telemetry patterns showing different operation types  
**Traffic pattern:** ~450 mixed requests across multiple endpoints  
**What it does:**
1. 100 health check requests to gateway
2. 200 order creation requests with varied quantities
3. 100 direct service calls (bypassing gateway)
4. 50 order retrieval attempts (mix of valid/invalid IDs)

**Expected output:** "Varied traffic generation complete! Total: ~450 requests with different patterns"

---

## Recommended Usage Order

### Initial Setup & Testing
```bash
# 1. Start all services
./start-all-services.sh

# 2. Verify Dash0 telemetry is flowing
./verify-telemetry.sh

# 3. Verify services are working
./test-separate-services.sh

# 4. Confirm Dash0 dataset integration
./traffic-confirm-dataset.sh
```

### Regular Testing
```bash
# Quick health check and E2E test
./test-separate-services.sh

# Detailed testing with JSON output
./test-microservices.sh

# Verify telemetry connections
./verify-telemetry.sh
```

### Traffic Generation (choose based on need)
```bash
# Dataset confirmation (100 requests)
./traffic-confirm-dataset.sh

# Moderate controlled load (500 requests)
./traffic-moderate.sh

# Long-running background traffic (continuous)
./traffic-continuous.sh

# High-volume stress test (2000 requests)
./traffic-stress.sh

# Realistic mixed patterns (450 requests)
./traffic-varied.sh
```

## Prerequisites

- **GlassFish 8.0.2** - Path configured in `app/data/config.json` (`paths.glassfishBase`)
- **OpenTelemetry Java Agent** - Path configured in `app/data/config.json` (`paths.otelAgent`)
- **jq** (for test-microservices.sh): `brew install jq`
- **curl** (standard on macOS)
- **config.json** - Copy from `config.template.json` and configure paths
- All 5 domain configurations must have OpenTelemetry properly configured in their `domain.xml`

## Troubleshooting

### Services won't start
```bash
# Check if ports are already in use
lsof -i :8080-8084

# Kill existing GlassFish processes
pkill -9 -f glassfish

# Try starting again
./start-all-services.sh
```

### Dash0 not receiving data
```bash
# Verify gRPC connections to Dash0
lsof -i :4317

# Should show multiple ESTABLISHED connections
# Each service maintains a connection to ingress.europe-west4.gcp.dash0.com:4317
```

### Check domain logs
```bash
# View logs for a specific domain (replace <path> with your glassfishBase from config.json)
tail -f <path>/glassfish/domains/<domain-name>/logs/server.log
```

### Test individual service
```bash
# Replace <port> and <service> with actual values
curl -s http://localhost:<port>/<service>/api/health
```

## Dataset Information

**Configuration File:** `app/data/config.json`

**To change dataset:**
1. Edit `app/data/config.json` and update the `"dataset"` value
2. Regenerate properties: `cd app/scripts && ./generate-otel-properties.sh`
3. Rebuild services: `./rebuild-all-services.sh`
4. Restart all domains: `pkill -9 -f glassfish && ./start-all-services.sh`

All scripts automatically read the dataset value from `config.json`, so no script changes are needed.

## Service Call Flow

Typical request flow through the microservices:

```
Client Request
    ↓
api-gateway (port 8080)
    ↓
order-service (port 8081)
    ├→ inventory-service (port 8082) ← Check stock
    ├→ payment-service (port 8083) ← Process payment
    └→ notification-service (port 8084) ← Send confirmation
```

All inter-service communication is automatically traced by OpenTelemetry and sent to Dash0 for visualization.

## Notes

- All scripts assume execution from the `scripts` directory
- Traffic generation scripts use random data for testing
- Health endpoints return different JSON structures per service
- Order creation may fail with "Insufficient inventory" - this is expected behavior for testing error scenarios
- OpenTelemetry traces capture the full request flow including errors
