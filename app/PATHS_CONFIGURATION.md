# Paths Configuration

**Updated:** 2026-05-23  
**Status:** ✅ All paths now configurable

## Overview

All user-specific and environment-specific paths have been moved to `app/data/config.json`. No hardcoded paths remain in scripts or documentation (except as examples).

---

## Configuration

### config.json Structure

```json
{
  "paths": {
    "projectRoot": "/absolute/path/to/your/project",
    "glassfishBase": "/absolute/path/to/glassfish8",
    "otelAgent": "/absolute/path/to/opentelemetry-javaagent.jar"
  },
  "dash0": { ... },
  "services": [ ... ]
}
```

### Path Descriptions

| Field | Purpose | Example |
|-------|---------|---------|
| `projectRoot` | Root directory of the project | `/Users/yourname/projects/dash0stuff2` |
| `glassfishBase` | GlassFish installation directory | `/Users/yourname/projects/dash0stuff2/glassfish8` |
| `otelAgent` | OpenTelemetry Java agent JAR | `/Users/yourname/projects/dash0stuff2/opentelemetry-javaagent.jar` |

---

## Scripts Updated

All scripts now read paths from `config.json`:

### 1. start-all-services.sh
**What it reads:**
- `glassfishBase` → To locate `bin/asadmin` and `glassfish/domains/`

**Before:**
```bash
GLASSFISH_BASE="/Users/geertjan/Documents/GitHub/dash0stuff2/glassfish8"
```

**After:**
```bash
CONFIG_FILE="$(cd "$(dirname "$0")/.." && pwd)/data/config.json"
GLASSFISH_BASE=$(grep -o '"glassfishBase": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
```

---

### 2. verify-telemetry.sh
**What it reads:**
- `glassfishBase` → To locate domain.xml files for verification

**Before:**
```bash
GLASSFISH_BASE="/Users/geertjan/Documents/GitHub/dash0stuff2/glassfish8/glassfish"
```

**After:**
```bash
CONFIG_FILE="$(cd "$(dirname "$0")/.." && pwd)/data/config.json"
GLASSFISH_BASE=$(grep -o '"glassfishBase": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
```

---

### 3. migrate-domains-to-properties.sh
**What it reads:**
- `glassfishBase` → To locate and backup domain.xml files
- `otelAgent` → For javaagent path (if needed)

**Before:**
```bash
GLASSFISH_BASE="/Users/geertjan/Documents/GitHub/dash0stuff2/glassfish8/glassfish"
AGENT_PATH="/Users/geertjan/Documents/GitHub/dash0stuff2/opentelemetry-javaagent.jar"
```

**After:**
```bash
CONFIG_FILE="$(cd "$(dirname "$0")/.." && pwd)/data/config.json"
GLASSFISH_BASE=$(grep -o '"glassfishBase": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
AGENT_PATH=$(grep -o '"otelAgent": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
```

---

## Documentation Updated

All documentation now uses generic paths:

### Files Changed
- ✅ `app/scripts/README.md` - Prerequisites section
- ✅ `app/CONFIGURATION_STRATEGY.md` - Git verification examples
- ✅ `app/MIGRATION_STATUS.md` - External properties examples
- ✅ `app/data/README.md` - Added paths section documentation

### Before
```bash
tail -f /Users/geertjan/Documents/GitHub/dash0stuff2/glassfish8/glassfish/domains/gateway-domain/logs/server.log
```

### After
```bash
# Replace <path> with your glassfishBase from config.json
tail -f <path>/glassfish/domains/gateway-domain/logs/server.log
```

---

## Template Files

### config.template.json

```json
{
  "paths": {
    "projectRoot": "/absolute/path/to/your/project",
    "glassfishBase": "/absolute/path/to/your/project/glassfish8",
    "otelAgent": "/absolute/path/to/opentelemetry-javaagent.jar"
  },
  "dash0": {
    "dataset": "YOUR_DATASET_NAME",
    "endpoint": "https://ingress.YOUR_REGION.gcp.dash0.com:4317",
    "protocol": "grpc",
    "authorization": "Bearer YOUR_AUTH_TOKEN_HERE"
  },
  "services": [ ... ]
}
```

**Placeholders to replace:**
- `projectRoot` → Your actual project path
- `glassfishBase` → Your actual GlassFish path
- `otelAgent` → Your actual agent JAR path
- `YOUR_DATASET_NAME` → Your Dash0 dataset
- `YOUR_REGION` → Your Dash0 region
- `YOUR_AUTH_TOKEN_HERE` → Your Dash0 token

---

## Setup Process

### First Time

```bash
# 1. Copy template
cd app/data
cp config.template.json config.json

# 2. Edit paths and credentials
vim config.json
# Update ALL fields including paths section

# 3. Test configuration
cd ../scripts
./generate-otel-properties.sh  # Should work without errors
```

### Verification

```bash
# Test path extraction
CONFIG_FILE="../data/config.json"
grep -o '"glassfishBase": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4
# Should output your GlassFish path

grep -o '"otelAgent": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4
# Should output your agent JAR path
```

---

## Benefits

### ✅ Portability
- Copy project to new location → update config.json → everything works
- Different developers can have different paths
- Works on any OS (Windows, Mac, Linux) with absolute paths

### ✅ Team Collaboration
- No merge conflicts from hardcoded paths
- Each developer configures their own `config.json`
- Template shows exactly what needs configuration

### ✅ CI/CD Ready
```yaml
# GitHub Actions example
- name: Generate config
  env:
    PROJECT_ROOT: ${{ github.workspace }}
  run: |
    cat > app/data/config.json <<EOF
    {
      "paths": {
        "projectRoot": "$PROJECT_ROOT",
        "glassfishBase": "$PROJECT_ROOT/glassfish8",
        "otelAgent": "$PROJECT_ROOT/opentelemetry-javaagent.jar"
      },
      ...
    }
    EOF
```

### ✅ No Hardcoded Usernames
- Before: `/Users/geertjan/...` in every script
- After: Read from config, works for any user

---

## Migration Summary

### Removed Hardcoded Paths

**From Scripts:**
- ❌ `/Users/geertjan/Documents/GitHub/dash0stuff2/glassfish8`
- ❌ `/Users/geertjan/Documents/GitHub/dash0stuff2/opentelemetry-javaagent.jar`

**From Documentation:**
- ❌ `/Users/geertjan/.../glassfish8/glassfish/domains/.../logs/server.log`
- ❌ `/Users/geertjan/.../domains/*/config/domain.xml`

### Added Configuration

**In config.json:**
- ✅ `paths.projectRoot`
- ✅ `paths.glassfishBase`
- ✅ `paths.otelAgent`

**In config.template.json:**
- ✅ Same fields with placeholder values

---

## Troubleshooting

### Config File Not Found

```bash
❌ ERROR: config.json not found at /path/to/project/app/data/config.json
Run: cd ../data && cp config.template.json config.json
```

**Solution:**
```bash
cd app/data
cp config.template.json config.json
vim config.json  # Add your paths
```

---

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

---

### Relative vs Absolute Paths

**❌ Don't use relative paths:**
```json
{
  "paths": {
    "glassfishBase": "../glassfish8"  // ← Will break!
  }
}
```

**✅ Use absolute paths:**
```json
{
  "paths": {
    "glassfishBase": "/Users/yourname/project/glassfish8"
  }
}
```

---

## Future Enhancements

### Option 1: Auto-detect Paths

```bash
# Could add to scripts
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GLASSFISH_BASE="${PROJECT_ROOT}/glassfish8"
```

**Pros:** No configuration needed  
**Cons:** Assumes standard layout

### Option 2: Environment Variables

```bash
export GLASSFISH_BASE="/path/to/glassfish8"
export OTEL_AGENT="/path/to/agent.jar"
```

**Pros:** Standard approach  
**Cons:** Need to set before running scripts

### Current Approach: Best Balance

- ✓ Explicit configuration
- ✓ Single source of truth
- ✓ Works for any layout
- ✓ Documented in one place

---

## Summary

**All paths are now configurable in `config.json`**

✅ No hardcoded paths in scripts  
✅ No hardcoded paths in documentation  
✅ Template shows what to configure  
✅ Scripts validate config exists  
✅ Portable across developers and environments  

**One file to configure, everything works.**
