# Configuration Data

This folder contains centralized configuration used by all scripts and documentation.

## ⚠️ Initial Setup Required

**First time setup:**

1. Copy the template file:
   ```bash
   cp config.template.json config.json
   ```

2. Edit `config.json` and replace placeholder values:
   
   **Paths section:**
   - `projectRoot` → Absolute path to your project directory
   - `glassfishBase` → Absolute path to your GlassFish installation
   - `otelAgent` → Absolute path to opentelemetry-javaagent.jar
   
   **Dash0 section:**
   - `YOUR_DATASET_NAME` → Your Dash0 dataset (e.g., `app-20260522-02`)
   - `YOUR_REGION` → Your Dash0 region (e.g., `europe-west4`)
   - `YOUR_AUTH_TOKEN_HERE` → Your Dash0 authorization token

3. **Important:** `config.json` is excluded from git (contains secrets)

## config.json

Central configuration file for the microservices system and Dash0 integration.

**⚠️ This file contains secrets and is not committed to git.**

### Structure

```json
{
  "paths": {
    "projectRoot": "/absolute/path/to/your/project",
    "glassfishBase": "/absolute/path/to/glassfish8",
    "otelAgent": "/absolute/path/to/opentelemetry-javaagent.jar"
  },
  "dash0": {
    "dataset": "app-20260522-02",
    "endpoint": "https://ingress.europe-west4.gcp.dash0.com:4317",
    "protocol": "grpc",
    "authorization": "Bearer auth_Fgue028KvZLGWmhLK1AiHUAslIWVeun7"
  },
  "services": [
    {
      "name": "api-gateway",
      "domain": "gateway-domain",
      "port": 8080,
      "adminPort": 4848
    },
    ...
  ]
}
```

### Fields

#### paths section
- **projectRoot**: Root directory of the project (used by scripts for relative path resolution)
- **glassfishBase**: GlassFish installation directory (contains bin/, glassfish/domains/, etc.)
- **otelAgent**: Full path to the OpenTelemetry Java agent JAR file

#### dash0 section
- **dataset**: The Dash0 dataset name where telemetry data is sent
- **endpoint**: The OTLP endpoint URL for Dash0
- **protocol**: The protocol used (grpc)
- **authorization**: The authorization header with bearer token

#### services array
Each service has:
- **name**: OpenTelemetry service name (e.g., "api-gateway")
- **domain**: GlassFish domain name (e.g., "gateway-domain")
- **port**: HTTP port where the service listens
- **adminPort**: GlassFish admin console port

### Usage

All scripts in `../scripts/` automatically read from this file:

```bash
# Scripts parse the config file like this:
CONFIG_FILE="$(dirname "$0")/../data/config.json"
DATASET=$(grep -o '"dataset": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
```

### Changing the Dataset

To change the Dash0 dataset:

1. **Edit this file** - Update the `"dataset"` value in `config.json`

2. **Update domain.xml files** - Change the dataset in all 5 GlassFish domain configurations:
   ```bash
   # Location: glassfish8/glassfish/domains/*/config/domain.xml
   # Find this line in each domain.xml:
   -Dotel.exporter.otlp.headers=Authorization=Bearer ...,Dash0-Dataset=app-20260522-02
   
   # Replace with new dataset name
   ```

3. **Restart services**:
   ```bash
   cd ../scripts
   pkill -9 -f glassfish
   ./start-all-services.sh
   ```

4. **Verify**:
   ```bash
   ./verify-telemetry.sh
   ```

All scripts will automatically use the new dataset name from `config.json`. No script modifications needed!

### Benefits of Centralized Configuration

- **Single source of truth** - One place to check/update the dataset  
- **Consistency** - All scripts use the same value  
- **Easy maintenance** - Change once, affects all scripts  
- **Documentation** - Clear structure shows all services and ports  
- **No hardcoding** - Scripts dynamically read current values
