# Nginx Configuration for Aldrovandi Digital Twin

This guide explains how to configure Nginx as a reverse proxy to route traffic directly to ATON HTTPS (port 8083) in production, bypassing Varnish cache.

## Architecture

```
Browser → Nginx:443 (SSL) → ATON:8083 (HTTPS direct)
                          ↘ MELODY:5010 (HTTP)
```

**Benefits:**
- Simplified setup (no Varnish layer)
- Direct HTTPS connection enables WebXR/VR features
- Single routing path for all traffic

## Production Environment (.env)

Update your `.env` file with these production settings:

```bash
# --- PRODUCTION CONFIGURATION (with nginx) ---
SERVER_HOST=projects.vidilab.unibo.it
BASE_PATH=/aldrovandi
MELODY_PATH=/melodycall
MELODY_PUBLIC_PORT=443

# Service ports (internal Docker)
FUSEKI_PORT=3030
MELODY_PORT=5010
ATON_PORT=8080      # HTTP (not used in production)
ATON_VR_PORT=8083   # HTTPS (used by Nginx)

# NOTE: Varnish not used in this configuration

# ============================================
# RESOURCES - FUSEKI (SPARQL Endpoint)
# ============================================
FUSEKI_CPU_LIMIT=2
FUSEKI_CPU_RESERVATION=2
FUSEKI_MEM_LIMIT=8G
FUSEKI_MEM_RESERVATION=6G

# Java Heap (must be lower than or equal to MEM_LIMIT)
FUSEKI_JAVA_XMX=3g
FUSEKI_JAVA_XMS=2g

# ============================================
# RESOURCES - MELODY (Dashboard API)
# ============================================
MELODY_CPU_LIMIT=1
MELODY_CPU_RESERVATION=1
MELODY_MEM_LIMIT=2G
MELODY_MEM_RESERVATION=2G

# ============================================
# RESOURCES - ATON (3D Framework)
# ============================================
ATON_CPU_LIMIT=4
ATON_CPU_RESERVATION=4
ATON_MEM_LIMIT=8G
ATON_MEM_RESERVATION=4G
```

**Key variable**: `ATON_VR_PORT=8083` is the HTTPS port that Nginx will proxy to.

## Nginx Configuration

Create `/etc/nginx/sites-available/projects`:

```nginx
server {
    server_name projects.vidilab.unibo.it;
    root /var/www/vidilab;
    index index.html;

    # MELODY API
    location /aldrovandi/melodycall/ {
        proxy_pass http://127.0.0.1:5010/melody/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # MELODY static files
    location /melody/static/ {
        proxy_pass http://127.0.0.1:5010/melody/static/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # ATON framework resources
    location /res/ {
        proxy_pass https://127.0.0.1:8083/res/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_ssl_verify off;
    }

    location /dist/ {
        proxy_pass https://127.0.0.1:8083/dist/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_ssl_verify off;
    }

    location /vendors/ {
        proxy_pass https://127.0.0.1:8083/vendors/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_ssl_verify off;
    }

    # Aldrovandi project - Direct to ATON HTTPS
    location /a/aldrovandi/ {
        proxy_pass https://127.0.0.1:8083/a/aldrovandi/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_ssl_verify off;
    }

    location /aldrovandi/ {
        proxy_pass https://127.0.0.1:8083/a/aldrovandi/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_ssl_verify off;
    }

    # SSL configuration
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/projects.vidilab.unibo.it/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/projects.vidilab.unibo.it/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name projects.vidilab.unibo.it;
    return 301 https://$host$request_uri;
}
```

## Configuration Notes

**Why `proxy_ssl_verify off`?**
- ATON:8083 uses a self-signed certificate for internal communication
- Nginx must disable SSL verification for the backend connection
- The external connection (browser → Nginx) still uses valid Let's Encrypt certificate

**No Varnish Cache:**
- This configuration prioritizes simplicity and WebXR compatibility
- All traffic goes directly to ATON HTTPS backend
- For future caching needs, consider adding Varnish between Nginx and ATON:8080 (HTTP)

## Apply Configuration

```bash
# Backup existing configuration
sudo cp /etc/nginx/sites-available/projects /etc/nginx/sites-available/projects.backup

# Edit configuration
sudo nano /etc/nginx/sites-available/projects
# (paste the configuration above)

# Test configuration
sudo nginx -t

# If test passes, apply changes
sudo systemctl reload nginx
```
