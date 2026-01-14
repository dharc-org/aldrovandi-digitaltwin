# Aldrovandi Ecosystem

Docker stack for the Aldrovandi DigitalTwin project.

**Services:**
- **Fuseki**: SPARQL endpoint with chad-kg dataset
- **MELODY**: Dashboard API (Python/Flask + Gunicorn)
- **ATON**: 3D Framework (Node.js)
- **Apache**: Reverse Proxy con SSL (HTTPS)

---

## Setup on INTEL processors

### 1. Add the data

- TTL files in `./data/`:
  - `chad_kg.ttl`
  - `chad-ap.ttl`

- Aldrovandi contents in `./aton-content/`

### 2. Configure the environment
```bash
cp .env.example .env
```

Edit `.env` based on your setup:

| Mode | SERVER_HOST |
|------|-------------|
| KIOSK (local) | `127.0.0.1` |
| VR (headset) | Your LAN IP (es: `192.168.1.100`) |

### 3. Build and start
```bash
docker compose build --no-cache
docker compose up -d
```

### Access URLs

**KIOSK:** https://127.0.0.1/a/aldrovandi/?usebackup=true&mode=kiosk

**VR Mode:** https://YOUR_LAN_IP/a/aldrovandi/?usebackup=true

### Switching between modes

To switch from KIOSK to VR (or vice versa):

1. Edit `SERVER_HOST` in `.env`
2. Restart containers:
```bash
docker compose down
docker compose up -d
```

---

## Setup on ARM processors (Apple Silicon, Raspberry Pi)

### 1. Add the data

- TTL files in `./data/`:
  - `chad_kg.ttl`
  - `chad-ap.ttl`

- Aldrovandi contents in `./aton-content/`

### 2. Configure the environment
```bash
cp .env.example .env
```

Edit `.env` - same configuration as Intel (see table above).

### 3. Build and start
```bash
docker compose -f docker-compose-arm.yml build --no-cache
docker compose -f docker-compose-arm.yml up -d
```

Access URLs and mode switching are identical to Intel setup.

---

## Other documentation

- Offline installation: `./docs/offline-installation.md`
- Useful commands: `./docs/useful-cmd.md`