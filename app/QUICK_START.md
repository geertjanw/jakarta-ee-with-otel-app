# Quick Start Guide

## 🚀 First Time Setup (5 minutes)

```bash
# 1. Copy configuration template
cd app/data
cp config.template.json config.json

# 2. Edit with your Dash0 credentials
vim config.json
# Replace:
#   - YOUR_DATASET_NAME
#   - YOUR_REGION
#   - YOUR_AUTH_TOKEN_HERE

# 3. Generate OpenTelemetry configs
cd ../scripts
./generate-otel-properties.sh

# 4. Build all services
./rebuild-all-services.sh

# 5. Start services
./start-all-services.sh

# 6. Verify telemetry
./verify-telemetry.sh
```

---

## 📝 Daily Workflow

### Change Dataset or Credentials

```bash
# Edit config
vim app/data/config.json

# Regenerate + Rebuild + Restart
cd app/scripts
./generate-otel-properties.sh
./rebuild-all-services.sh
pkill -9 -f glassfish && ./start-all-services.sh
```

### Test Traffic

```bash
cd app/scripts

# Moderate load (500 requests)
./traffic-moderate.sh

# Stress test (2000 requests)
./traffic-stress.sh

# Continuous (until Ctrl+C)
./traffic-continuous.sh
```

---

## 🔍 Verify Everything Works

```bash
cd app/scripts

# Check telemetry connections
./verify-telemetry.sh

# Run E2E test
./test-separate-services.sh
```

---

## 📂 Important Files

| File | What It Is | In Git? |
|------|------------|---------|
| `app/data/config.template.json` | Template with placeholders | ✅ Yes |
| `app/data/config.json` | Your actual credentials | ❌ No (secret) |
| `app/*/src/main/resources/*.template` | OTel templates | ✅ Yes |
| `app/*/src/main/resources/otel.properties` | Generated configs | ❌ No (secret) |

---

## ⚠️ Never Commit These Files

- `app/data/config.json` - Contains your Dash0 token
- `app/*/src/main/resources/otel.properties` - Generated from config.json

These are automatically blocked by `.gitignore`

---

## 🆘 Troubleshooting

### "config.json not found"
```bash
cd app/data
cp config.template.json config.json
# Edit config.json with your credentials
```

### Services won't start
```bash
# Check ports
lsof -i :8080-8084

# Kill existing
pkill -9 -f glassfish

# Restart
cd app/scripts && ./start-all-services.sh
```

### No telemetry in Dash0
```bash
# Check connections
lsof -i :4317

# Regenerate config
cd app/scripts
./generate-otel-properties.sh
./rebuild-all-services.sh
pkill -9 -f glassfish && ./start-all-services.sh
```

---

## 📚 More Information

- **Full Setup Guide:** `app/SETUP.md`
- **Configuration Strategy:** `app/CONFIGURATION_STRATEGY.md`
- **Scripts Documentation:** `app/scripts/README.md`
- **Architecture Alternatives:** `app/ARCHITECTURE_ALTERNATIVES.md`

---

## 🎯 Quick Commands Reference

```bash
# Setup
cd app/data && cp config.template.json config.json && vim config.json

# Generate configs
cd app/scripts && ./generate-otel-properties.sh

# Build
./rebuild-all-services.sh

# Start
./start-all-services.sh

# Verify
./verify-telemetry.sh

# Test
./test-separate-services.sh

# Traffic
./traffic-moderate.sh

# Stop
pkill -9 -f glassfish
```

---

**Ready?** Start with step 1: `cd app/data && cp config.template.json config.json` 🚀
