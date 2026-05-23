# GlassFish Installation Cleanup Analysis

**Date:** 2026-05-23  
**Location:** `glassfish8/`

## Overview

Analysis of the GlassFish installation to identify what is custom, what is default, and what can be safely removed.

---

## Directory Structure

```
glassfish8/
├── META-INF/              # Default - Maven/build metadata
├── README.txt             # Default - GlassFish documentation
├── bin/                   # Default - GlassFish binaries (asadmin, etc.)
├── glassfish/            # Main GlassFish directory
│   ├── bin/              # Default - Additional utilities
│   ├── domains/          # ⚠️  CUSTOM - Our domains are here
│   ├── lib/              # Default - GlassFish libraries
│   ├── modules/          # Default - GlassFish modules
│   └── ...
├── javadb/               # Default - Derby database
└── mq/                   # Default - Message queue

Total size: ~300-400MB
```

---

## Custom Content in `glassfish/domains/`

### ✅ Custom Domains (KEEP)

**5 Custom Domains:**
1. `gateway-domain` (admin: 4848, http: 8080)
2. `order-domain` (admin: 4849, http: 8081)
3. `inventory-domain` (admin: 4850, http: 8082)
4. `payment-domain` (admin: 4851, http: 8083)
5. `notification-domain` (admin: 4852, http: 8084)

**Each domain contains:**
- Custom `domain.xml` with OpenTelemetry configuration
- Deployed applications (gateway.war, order.war, etc.)
- Configuration files
- Generated files
- Logs

**Status:** ✅ **KEEP - Essential for the project**

---

### ⚠️ Default Domain (CAN REMOVE)

**`domain1`** - GlassFish default domain
- **Admin port:** 4848 (conflicts with gateway-domain)
- **HTTP port:** 8080 (conflicts with gateway-domain)
- **Status:** Has OpenTelemetry agent configured but not used
- **Size:** ~540K logs + domain files

**Recommendation:** ❌ **CAN BE REMOVED**

**Why:**
- Not used by the application
- Port conflicts with gateway-domain
- Was likely used for initial testing only

**How to remove:**
```bash
cd glassfish8/glassfish/domains
rm -rf domain1
```

---

### 🔧 Custom Script (KEEP OR UPDATE)

**`configure-domains.sh`**
- Located in `glassfish/domains/`
- Purpose: Script to configure ports and service names
- **Issue:** References old `asenv.conf` configuration method (now obsolete)

**Content:**
```bash
#!/bin/bash
# Configure each domain with proper ports and service names
# Updates domain.xml ports
# Updates asenv.conf service name (OBSOLETE)
```

**Recommendation:** ⚠️ **UPDATE OR REMOVE**

**Option 1 - Remove:**
```bash
rm glassfish8/glassfish/domains/configure-domains.sh
```
Domains are already configured, script is no longer needed.

**Option 2 - Update:**
Keep for documentation but add note that it's obsolete:
```bash
#!/bin/bash
# OBSOLETE: This script was used for initial domain setup
# Configuration is now done via:
#   1. domain.xml (JVM options for OpenTelemetry)
#   2. app/data/config.json (centralized configuration)
# 
# This file is kept for reference only.
```

---

## Backup Files (CAN REMOVE)

**Location:** `glassfish/domains/*/config/`

**Found 5 backup files:**
```
gateway-domain/config/domain.xml.backup-20260523-150252
order-domain/config/domain.xml.backup-20260523-150252
inventory-domain/config/domain.xml.backup-20260523-150252
payment-domain/config/domain.xml.backup-20260523-150252
notification-domain/config/domain.xml.backup-20260523-150252
```

**Size:** ~5KB each (minimal)

**Recommendation:** ⚠️ **CAN BE REMOVED AFTER VERIFICATION**

**When to remove:**
- After verifying current configuration works
- After testing telemetry with new setup
- Keep if you might need to rollback

**How to remove:**
```bash
cd glassfish8/glassfish/domains
find . -name "*.backup-*" -delete
```

---

## Log Files (CAN CLEAN)

**Location:** `glassfish/domains/*/logs/`

**Current sizes:**
```
domain1:              540K  (unused domain)
gateway-domain:       3.0M
inventory-domain:     4.0M
notification-domain:  2.1M
order-domain:         3.0M
payment-domain:       692K
-----------------------------------
Total:               ~13.3MB
```

**Recommendation:** ⚠️ **CAN BE CLEANED**

**What's safe to remove:**
- Old log files (`.log.1`, `.log.2`, etc.)
- Log files from unused domain1
- Historical logs if you don't need debugging history

**How to clean:**
```bash
# Remove old rotated logs
find glassfish8/glassfish/domains/*/logs -name "*.log.[0-9]*" -delete

# Remove domain1 logs entirely
rm -rf glassfish8/glassfish/domains/domain1/logs/*

# Or keep only recent logs (last 7 days)
find glassfish8/glassfish/domains/*/logs -name "*.log" -mtime +7 -delete
```

**Note:** Logs will regenerate when domains start.

---

## .DS_Store Files (CAN REMOVE)

**Found in:**
- `glassfish8/.DS_Store`
- `glassfish8/glassfish/domains/.DS_Store`

**Recommendation:** ❌ **REMOVE (macOS metadata)**

```bash
find glassfish8 -name ".DS_Store" -delete
```

**Add to .gitignore:**
```gitignore
# Already in .gitignore:
.DS_Store
```

---

## Summary of Removable Items

| Item | Location | Size | Safe to Remove? | Impact |
|------|----------|------|-----------------|--------|
| **domain1** | `domains/domain1/` | ~10MB | ✅ Yes | None - unused |
| **configure-domains.sh** | `domains/` | 1KB | ⚠️ Maybe | Reference only |
| **Backup files** | `domains/*/config/*.backup-*` | ~25KB | ⚠️ After testing | Can rollback if needed |
| **Log files** | `domains/*/logs/` | ~13MB | ✅ Yes | Regenerate on startup |
| **.DS_Store** | Various | ~12KB | ✅ Yes | None - macOS metadata |

**Total potential cleanup:** ~23MB+ (minimal impact)

---

## What CANNOT Be Removed

### ✅ Essential GlassFish Components

**DO NOT REMOVE:**
- `bin/` - Contains asadmin and other executables
- `glassfish/bin/` - Additional GlassFish utilities
- `glassfish/lib/` - Core libraries
- `glassfish/modules/` - GlassFish modules
- `META-INF/` - Build metadata
- `javadb/` - Derby database (may be needed)
- `mq/` - Message queue (may be needed)

### ✅ Custom Domain Directories

**DO NOT REMOVE:**
```
glassfish/domains/gateway-domain/
glassfish/domains/order-domain/
glassfish/domains/inventory-domain/
glassfish/domains/payment-domain/
glassfish/domains/notification-domain/
```

**Each domain contains:**
- `config/domain.xml` - Custom configuration with OpenTelemetry
- `applications/` - Deployed WAR files
- `config/` - Security, JVM settings
- `generated/` - Generated artifacts
- `lib/` - Domain-specific libraries
- `docroot/` - Web root
- `autodeploy/` - Hot deployment directory

### ✅ Critical Configuration Files

**In each domain's config/ directory:**
- `domain.xml` - Main configuration (✅ KEEP)
- `admin-keyfile` - Admin authentication (✅ KEEP)
- `keystore.p12` - SSL certificates (✅ KEEP)
- `cacerts.p12` - CA certificates (✅ KEEP)

---

## Recommended Cleanup Actions

### Safe Cleanup (Immediate)

```bash
cd /Users/geertjan/Documents/GitHub/dash0stuff2/glassfish8

# 1. Remove default unused domain
rm -rf glassfish/domains/domain1

# 2. Remove .DS_Store files
find . -name ".DS_Store" -delete

# 3. Clean old log files
find glassfish/domains/*/logs -name "*.log.[0-9]*" -delete

# 4. Update configure-domains.sh with obsolete notice
cat > glassfish/domains/configure-domains.sh <<'EOF'
#!/bin/bash
# OBSOLETE: This script was used for initial domain setup (May 2026)
# 
# Configuration is now managed via:
#   - app/data/config.json (centralized configuration)
#   - domain.xml (JVM options for OpenTelemetry)
#   - app/scripts/generate-otel-properties.sh (property generation)
#
# Domains are already configured. This file is kept for reference only.
EOF
```

### After Verification (Later)

```bash
# After confirming current setup works (wait 1-2 weeks)

# Remove backup files
find glassfish/domains/*/config -name "*.backup-*" -delete
```

---

## Impact of Cleanup

**Before cleanup:**
```
glassfish8/           ~300-400MB (base installation)
├── domains/          ~50-100MB (5 custom + 1 default + logs)
└── ...
```

**After cleanup:**
```
glassfish8/           ~300-400MB (base installation)
├── domains/          ~40-90MB (5 custom domains only)
└── ...
```

**Space saved:** ~10-20MB (minimal, mostly logs)

---

## Alternative: Fresh GlassFish Installation

If you want to **remove everything user-specific** from GlassFish:

### What Makes It Non-Portable

1. **Domain configurations** (custom)
2. **Deployed applications** (custom)
3. **OpenTelemetry agent path** in domain.xml (user-specific)

### Making It Portable

**Option A: Document domain creation**
- Remove all domains except templates
- Provide script to create domains from scratch
- Include in setup documentation

**Option B: Parameterize paths**
- Domain.xml references to agent already use config.json paths
- Applications are built and deployed separately
- Configuration is in config.json (already done ✅)

**Current Status:** ✅ Already mostly portable!
- Paths are in `config.json`
- Applications are in `app/` folder
- Domains can be recreated from scripts

---

## .gitignore Recommendations

Add to `.gitignore` if committing GlassFish:

```gitignore
# GlassFish domains
glassfish8/glassfish/domains/domain1/
glassfish8/glassfish/domains/*/logs/*.log
glassfish8/glassfish/domains/*/logs/*.log.[0-9]*
glassfish8/glassfish/domains/*/osgi-cache/
glassfish8/glassfish/domains/*/generated/
glassfish8/glassfish/domains/*/applications/
glassfish8/glassfish/domains/*/autodeploy/

# Backups
glassfish8/glassfish/domains/*/config/*.backup-*

# macOS
glassfish8/**/.DS_Store
```

**However:** Best practice is to **NOT commit GlassFish installation** at all.
- Users download and install GlassFish separately
- Project provides setup scripts to create domains
- Keeps repository size small

---

## Conclusion

### Can Be Removed Immediately
✅ `domain1` (unused default domain)  
✅ `.DS_Store` files (macOS metadata)  
✅ Old log files (`.log.[0-9]*`)

### Can Be Removed After Verification
⚠️ Backup files (`.backup-*`) - wait until sure current config works  
⚠️ `configure-domains.sh` - mark as obsolete or remove

### Must Keep
❌ 5 custom domains (gateway, order, inventory, payment, notification)  
❌ Core GlassFish installation (bin, lib, modules)  
❌ Configuration files (domain.xml, keystores, etc.)

### Best Practice
💡 Don't commit `glassfish8/` to git at all
- Provide installation instructions
- Provide domain setup scripts
- Keep repository lightweight

**Current setup is already well-organized!** The custom domains contain essential configuration and the structure is clean.
