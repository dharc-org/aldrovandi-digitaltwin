# Nginx Configuration for Aldrovandi Digital Twin

This guide explains how to configure Nginx as a reverse proxy with path-based routing:
- **Normal mode** (with cache): `/aldrovandi/` → Varnish → ATON:8080
- **VR mode** (HTTPS direct): `/aldrovandi-vr/` → ATON:8083

## Architecture

```
Browser → Nginx:443 (SSL) → 
    ├─ /aldrovandi/ → Varnish:8085 (cache) → ATON:8080 (HTTP)
    └─ /aldrovandi-vr/ → ATON:8083 (HTTPS direct, no cache)
```

## Production Environment (.env)

Update your `.env` file with these production settings:

```bash
# --- PRODUCTION CONFIGURATION (with nginx) ---
SERVER_HOST=projects.vidilab.unibo.it
BASE_PATH=/aldrovandi
MELODY_PATH=/melodycall
MELODY_PUBLIC_PORT=443

# Service ports (internal Docker)
VARNISH_PORT=8085
FUSEKI_PORT=3030
MELODY_PORT=5010
ATON_PORT=8080       # HTTP (normal mode via Varnish)
ATON_VR_PORT=8083    # HTTPS (VR mode direct)

# ============================================
# RESOURCES - VARNISH (Cache Layer)
# ============================================
VARNISH_CPU_LIMIT=4
VARNISH_CPU_RESERVATION=2
VARNISH_MEM_LIMIT=8G
VARNISH_MEM_RESERVATION=4G

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

## Nginx Configuration

Create `/etc/nginx/sites-available/projects`:

```nginx
server {
    server_name projects.vidilab.unibo.it;
    root /var/www/vidilab;
    index index.html;

    # Pass Varnish cache headers to browser (only for normal mode)
    add_header X-Cache $upstream_http_x_cache always;
    add_header X-Cache-Hits $upstream_http_x_cache_hits always;

    # MELODY API (must come BEFORE /aldrovandi/)
    location /aldrovandi/melodycall/ {
        proxy_pass http://127.0.0.1:8085/melody/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # MELODY static files
    location /melody/static/ {
        proxy_pass http://127.0.0.1:8085/melody/static/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # ATON framework resources (via Varnish cache)
    location /res/ {
        proxy_pass http://127.0.0.1:8085/res/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /dist/ {
        proxy_pass http://127.0.0.1:8085/dist/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /vendors/ {
        proxy_pass http://127.0.0.1:8085/vendors/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # ============================================
    # VR MODE - Direct HTTPS to ATON:8083
    # ============================================
    location /aldrovandi-vr/ {
        proxy_pass https://127.0.0.1:8083/a/aldrovandi/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Disable SSL verification for self-signed certificate
        proxy_ssl_verify off;
    }

    location /a/aldrovandi-vr/ {
        proxy_pass https://127.0.0.1:8083/a/aldrovandi/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Disable SSL verification for self-signed certificate
        proxy_ssl_verify off;
    }

    # ============================================
    # NORMAL MODE - Via Varnish cache
    # ============================================
    location /a/aldrovandi/ {
        proxy_pass http://127.0.0.1:8085/a/aldrovandi/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /aldrovandi/ {
        proxy_pass http://127.0.0.1:8085/a/aldrovandi/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
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

## Routing Logic

**Normal Mode** (cached, optimized for web):
```
https://projects.vidilab.unibo.it/aldrovandi/
→ Nginx:443 → Varnish:8085 → ATON:8080 (HTTP)
✓ Cache enabled (fast repeat visits)
✓ No HTTPS overhead on backend
```

**VR Mode** (direct HTTPS, WebXR enabled):
```
https://projects.vidilab.unibo.it/aldrovandi-vr/
→ Nginx:443 → ATON:8083 (HTTPS direct)
✓ WebXR/VR features enabled
✓ Bypasses cache
✓ Same content as normal mode
```

Both URLs point to the same ATON content (`/a/aldrovandi/`), just different routing paths.

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