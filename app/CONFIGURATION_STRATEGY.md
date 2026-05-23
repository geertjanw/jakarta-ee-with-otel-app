# Configuration Strategy: Template-Based Secret Management

**Date:** 2026-05-23  
**Status:** ✅ Implemented

## Overview

The project uses a **template-based configuration strategy** where secrets are kept out of git while maintaining a clear setup process for new developers.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Git Repository (Public)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ✓ app/data/config.template.json          (no secrets)         │
│  ✓ app/*/src/main/resources/*.template     (no secrets)        │
│  ✓ app/scripts/generate-otel-properties.sh (generator)         │
│  ✓ .gitignore                              (blocks secrets)     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                  Local Machine (Private)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ✗ app/data/config.json                   (contains secrets)   │
│  ✗ app/*/src/main/resources/otel.properties (generated)        │
│                                                                  │
│  [Generated from config.json at build time]                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Files Summary

| File | In Git? | Contains Secrets? | Purpose |
|------|---------|-------------------|---------|
| `config.template.json` | ✅ Yes | ❌ No | Template with placeholders |
| `config.json` | ❌ No | ⚠️ Yes | Actual credentials (local only) |
| `otel.properties.template` | ✅ Yes | ❌ No | Template for OTel config |
| `otel.properties` | ❌ No | ⚠️ Yes | Generated from config.json |
| `generate-otel-properties.sh` | ✅ Yes | ❌ No | Generator script |

---

## Workflow

### 1. Initial Setup (Once per developer)

```bash
# Clone repository
git clone <repo>

# Copy template and add credentials
cd app/data
cp config.template.json config.json
vim config.json  # Add actual Dash0 credentials

# Generate property files
cd ../scripts
./generate-otel-properties.sh

# Build and deploy
./rebuild-all-services.sh
./start-all-services.sh
```

### 2. Regular Development

**Developer changes dataset:**

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

**Generator script handles:**
- ✅ Reading `config.json`
- ✅ Extracting dataset, endpoint, auth token
- ✅ Creating `otel.properties` for each service
- ✅ Validating config exists (fails if missing)

---

## Security Model

### What's Protected

1. **Dash0 Authorization Token**
   ```json
   "authorization": "Bearer auth_Fgue028KvZLGWmhLK1AiHUAslIWVeun7"
   ```
   - Never committed to git
   - Stored only in local `config.json`

2. **Dataset Names**
   ```json
   "dataset": "app-20260522-02"
   ```
   - May contain environment info (dev/staging/prod)
   - Kept out of git for flexibility

### What's in Git

1. **Structure (Templates)**
   ```json
   "authorization": "Bearer YOUR_AUTH_TOKEN_HERE"
   "dataset": "YOUR_DATASET_NAME"
   ```
   - Shows developers what to configure
   - No actual secrets

2. **Generator Script**
   - Logic for creating config files
   - No hardcoded credentials

---

## Benefits

### ✅ Security
- Secrets never committed to git
- No risk of accidental exposure
- Easy to rotate credentials (update one file)

### ✅ Developer Experience
- Clear setup instructions
- Template shows exactly what's needed
- Single command to generate configs
- No manual editing of 5 different files

### ✅ Maintainability
- Single source of truth (`config.json`)
- Change dataset in one place
- Generated files stay in sync
- Scripts work across all services

### ✅ Team Collaboration
- New team members follow template
- No secrets in pull requests
- CI/CD uses environment variables
- Different configs per environment

---

## Comparison with Alternatives

| Approach | Secrets in Git? | Manual Config? | Single Source? |
|----------|----------------|----------------|----------------|
| **Hardcoded in domain.xml** | ✗ Yes | ✗ Manual (5 files) | ✗ No |
| **Template + Generated** | ✅ No | ✅ Automated | ✅ Yes |
| **Environment Variables** | ✅ No | ✅ Automated | ✅ Yes |
| **External Config Server** | ✅ No | ✅ Automated | ✅ Yes |

Our approach (**Template + Generated**) balances:
- Security (secrets out of git)
- Simplicity (no external dependencies)
- Developer experience (clear templates)
- Flexibility (easy to change)

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
      
      - name: Deploy
        run: # Deploy WAR files
```

---

## Git Configuration

### .gitignore Entries

```gitignore
# Sensitive configuration
app/data/config.json
app/*/src/main/resources/otel.properties
```

### Verification

```bash
# Check files are properly ignored
cd /path/to/your/project
git status --ignored

# Should show:
# !! app/data/config.json
# !! app/gateway/src/main/resources/otel.properties
# ... (other services)
```

---

## Migration from Previous Approach

### Before (domain.xml with hardcoded values)

```xml
<!-- In each domain.xml: -->
<jvm-options>-Dotel.service.name=api-gateway</jvm-options>
<jvm-options>-Dotel.exporter.otlp.headers=Authorization=Bearer auth_...,Dash0-Dataset=app-20260522-02</jvm-options>
<jvm-options>-Dotel.traces.exporter=otlp</jvm-options>
<!-- ... 5 more options ... -->
```

**Problems:**
- ❌ Secrets in git
- ❌ Hard to change (5 files)
- ❌ Not DRY (repeated config)

### After (template + generated)

**In git:**
```json
// config.template.json
{
  "dash0": {
    "authorization": "Bearer YOUR_AUTH_TOKEN_HERE"
  }
}
```

**Local only:**
```json
// config.json (generated from template)
{
  "dash0": {
    "authorization": "Bearer auth_actual_token_here"
  }
}
```

**Generated at build time:**
```properties
# otel.properties (in each service)
otel.exporter.otlp.headers=Bearer auth_actual_token_here,Dash0-Dataset=app-20260522-02
```

**Benefits:**
- ✅ No secrets in git
- ✅ Single file to change
- ✅ Automated generation

---

## Troubleshooting

### Config Not Found

```bash
❌ ERROR: config.json not found!
```

**Solution:** Run initial setup
```bash
cd app/data
cp config.template.json config.json
vim config.json  # Add credentials
```

### Properties Not Generated

**Check generator script ran:**
```bash
cd app/scripts
./generate-otel-properties.sh

# Should show:
# ✓ Created gateway/src/main/resources/otel.properties
# ✓ Created order/src/main/resources/otel.properties
# ...
```

### Secrets Accidentally Committed

**If config.json was committed:**
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

## Future Enhancements

### Option 1: Environment Variable Approach

Instead of property files, use env vars:

```bash
# Set from config.json
export OTEL_EXPORTER_OTLP_HEADERS="Bearer $TOKEN,Dash0-Dataset=$DATASET"
asadmin start-domain gateway-domain
```

**Pros:** No property files needed, runtime config  
**Cons:** Requires startup script changes

### Option 2: External Config Service

Use Spring Cloud Config or similar:

**Pros:** Centralized, runtime updates  
**Cons:** Additional infrastructure

### Current Approach: Just Right

Template + generator approach is:
- ✓ Simple (no external dependencies)
- ✓ Secure (secrets out of git)
- ✓ Flexible (easy to customize)
- ✓ Standard (familiar to developers)

---

## Summary

**Strategy:** Template-based configuration with build-time generation  
**Security:** Secrets never in git, only in local files  
**Workflow:** Copy template → Edit → Generate → Build  
**Single Source:** `config.json` drives all configuration  
**Developer Friendly:** Clear templates, automated generation  

**Result:** Secure, maintainable, and easy to use configuration management.
