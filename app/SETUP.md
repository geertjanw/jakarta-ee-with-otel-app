# Project Setup Guide

## First Time Setup

### 1. Configure Dash0 Credentials

The project uses a centralized configuration file that **contains secrets** and is **excluded from git**.

```bash
# Navigate to data folder
cd app/data

# Copy the template
cp config.template.json config.json

# Edit with your actual credentials
# Replace these placeholders:
#   - YOUR_DATASET_NAME        → e.g., "app-20260522-02"
#   - YOUR_REGION              → e.g., "europe-west4"
#   - YOUR_AUTH_TOKEN_HERE     → Your Dash0 Bearer token
```

**Example config.json:**
```json
{
  "dash0": {
    "dataset": "my-app-production",
    "endpoint": "https://ingress.europe-west4.gcp.dash0.com:4317",
    "protocol": "grpc",
    "authorization": "Bearer auth_abc123xyz..."
  },
  "services": [...]
}
```

### 2. Generate OpenTelemetry Configuration

The OTel property files are generated from `config.json`:

```bash
cd app/scripts
./generate-otel-properties.sh
```

This creates `otel.properties` in each service's `src/main/resources/` folder.

**Output:**
```
✓ Created gateway/src/main/resources/otel.properties
✓ Created order/src/main/resources/otel.properties
✓ Created inventory/src/main/resources/otel.properties
✓ Created payment/src/main/resources/otel.properties
✓ Created notification/src/main/resources/otel.properties
```

### 3. Build All Services

```bash
cd app/scripts
./rebuild-all-services.sh
```

This builds all 5 services and includes the generated `otel.properties` files in the WAR files.

### 4. Start Services

```bash
./start-all-services.sh
```

### 5. Verify Telemetry

```bash
./verify-telemetry.sh
```

---

## Files Excluded from Git

These files contain secrets and are automatically excluded:

- ✓ `app/data/config.json` - Contains Dash0 credentials
- ✓ `app/*/src/main/resources/otel.properties` - Generated from config.json

**Template files** are committed to git:
- ✓ `app/data/config.template.json` - Template with placeholders
- ✓ `app/*/src/main/resources/otel.properties.template` - Template for each service

---

## Changing Configuration

### To Change Dataset or Credentials

1. **Edit config.json:**
   ```bash
   cd app/data
   vim config.json
   # Update dataset, endpoint, or authorization
   ```

2. **Regenerate property files:**
   ```bash
   cd ../scripts
   ./generate-otel-properties.sh
   ```

3. **Rebuild services:**
   ```bash
   ./rebuild-all-services.sh
   ```

4. **Restart domains:**
   ```bash
   pkill -9 -f glassfish
   ./start-all-services.sh
   ```

5. **Verify:**
   ```bash
   ./verify-telemetry.sh
   ```

**Note:** Only steps 1-2 modify source files. Steps 3-5 deploy the changes.

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

### Sharing Configuration (Without Secrets)

**Good:** Share the structure
```bash
# Share this (safe, no secrets)
cat app/data/config.template.json
```

**Bad:** Don't commit secrets
```bash
# Never do this!
git add app/data/config.json  # ← This is blocked by .gitignore
```

### Getting Credentials

New team members need:
1. **Dash0 account access**
2. **Authorization token** (from Dash0 dashboard)
3. **Dataset name** (from team documentation)

Share these via secure channels (1Password, Vault, etc.), not in code.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     config.json (secrets)                    │
│                  ⚠️  Excluded from git                       │
└────────────────────────────┬────────────────────────────────┘
                             │
                  [generate-otel-properties.sh]
                             │
                             ↓
        ┌────────────────────┴────────────────────┐
        │                                         │
        ↓                                         ↓
  otel.properties                           otel.properties
  (gateway)                                 (order, inventory...)
  ⚠️  Excluded from git                     ⚠️  Excluded from git
        │                                         │
        ↓                                         ↓
  [mvn package]                             [mvn package]
        │                                         │
        ↓                                         ↓
  gateway.war                               order.war, etc.
  (WEB-INF/classes/otel.properties)        (WEB-INF/classes/otel.properties)
```

---

## Troubleshooting

### "config.json not found" Error

```bash
❌ ERROR: config.json not found!

First time setup required:
  1. cd app/data
  2. cp config.template.json config.json
  3. Edit config.json with your Dash0 credentials
```

**Solution:** Follow the setup steps in section 1.

---

### Properties Not Generated

If `otel.properties` files aren't created:

```bash
# Check config.json exists and is valid JSON
cat app/data/config.json | python3 -m json.tool

# Run generator with explicit path
cd app/scripts
bash -x ./generate-otel-properties.sh  # Shows debug output
```

---

### Credentials in Git Accidentally

If you accidentally committed secrets:

```bash
# Remove from git but keep locally
git rm --cached app/data/config.json

# Verify it's in .gitignore
grep "config.json" .gitignore

# Commit the removal
git commit -m "Remove config.json from git (contains secrets)"

# Important: The secret is still in git history!
# Contact your security team if this contains real credentials
```

---

## CI/CD Integration

### In CI Pipeline

Set credentials as environment variables:

```yaml
# Example: GitHub Actions
env:
  DASH0_DATASET: ${{ secrets.DASH0_DATASET }}
  DASH0_ENDPOINT: ${{ secrets.DASH0_ENDPOINT }}
  DASH0_TOKEN: ${{ secrets.DASH0_TOKEN }}

steps:
  - name: Generate config
    run: |
      cat > app/data/config.json <<EOF
      {
        "dash0": {
          "dataset": "$DASH0_DATASET",
          "endpoint": "$DASH0_ENDPOINT",
          "protocol": "grpc",
          "authorization": "Bearer $DASH0_TOKEN"
        },
        "services": [...]
      }
      EOF
  
  - name: Generate OTel properties
    run: cd app/scripts && ./generate-otel-properties.sh
  
  - name: Build services
    run: cd app/scripts && ./rebuild-all-services.sh
```

---

## Security Best Practices

✅ **DO:**
- Store credentials in secure vaults (1Password, HashiCorp Vault, AWS Secrets Manager)
- Use environment variables in CI/CD
- Rotate tokens regularly
- Use different datasets for dev/staging/production

❌ **DON'T:**
- Commit `config.json` to git
- Share credentials in Slack/email
- Use production credentials in development
- Check generated `otel.properties` files into git

---

## Summary

**Single source of truth:** `app/data/config.json`  
**Generated files:** `app/*/src/main/resources/otel.properties`  
**Both excluded from git:** Contains secrets  
**Templates in git:** Show structure, no secrets  

To get started: **Copy template → Edit credentials → Generate properties → Build → Deploy**
