# Nginx Configuration for Aldrovandi Digital Twin

This guide explains how to configure Nginx as a reverse proxy to route traffic through Varnish for caching in production, with conditional routing for VR mode.

## Architecture

```
Browser → Nginx:443 (SSL) → 
    ├─ Normal mode → Varnish:8085 (cache) → ATON:8081
    └─ VR mode (?mode=vr) → ATON:8083 (HTTPS direct, bypass cache)
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
ATON_PORT=8081
ATON_VR_PORT=8083

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

**Key variables**: 
- `VARNISH_PORT=8085` must match the port in Nginx configuration below
- `ATON_VR_PORT=8083` is the HTTPS port for VR mode

## Nginx Configuration

Create `/etc/nginx/sites-available/projects`:

```nginx
server {
    server_name projects.vidilab.unibo.it;
    root /var/www/vidilab;
    index index.html;

    # Pass Varnish cache headers to browser
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

    # ATON framework resources
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

    # Aldrovandi project paths (with VR mode routing)
    location /a/aldrovandi/ {
        # Default: route through Varnish cache
        set $backend "http://127.0.0.1:8085";
        
        # VR Mode: bypass cache, direct to ATON HTTPS
        if ($arg_mode = "vr") {
            set $backend "https://127.0.0.1:8083";
        }
        
        proxy_pass $backend/a/aldrovandi/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Disable SSL verification for self-signed certificate
        proxy_ssl_verify off;
    }

    location /aldrovandi/ {
        # Default: route through Varnish cache
        set $backend "http://127.0.0.1:8085";
        
        # VR Mode: bypass cache, direct to ATON HTTPS
        if ($arg_mode = "vr") {
            set $backend "https://127.0.0.1:8083";
        }
        
        proxy_pass $backend/a/aldrovandi/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Disable SSL verification for self-signed certificate
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

## VR Mode Routing Logic

The configuration uses conditional routing based on the `mode` query parameter:

**Normal access** (cached via Varnish):
```
https://projects.vidilab.unibo.it/aldrovandi/
→ Nginx → Varnish:8085 → ATON:8081
```

**VR Mode access** (direct HTTPS, bypasses cache):
```
https://projects.vidilab.unibo.it/aldrovandi/?mode=vr
→ Nginx → ATON:8083 (HTTPS)
```

The `proxy_ssl_verify off` directive is required because ATON uses a self-signed certificate for internal communication.

## Apply Configuration

```bash
# Backup existing configuration
sudo cp /etc/nginx/sites-available/projects /etc/nginx/sites-available/projects.backup

# Test configuration
sudo nginx -t

# Apply changes
sudo systemctl reload nginx
```

## Verify Routing

**Test normal mode (should show cache headers):**
```bash
curl -I https://projects.vidilab.unibo.it/aldrovandi/
```

Look for:
- `X-Cache: HIT` or `X-Cache: MISS` (Varnish headers)

**Test VR mode (should bypass cache):**
```bash
curl -I https://projects.vidilab.unibo.it/aldrovandi/?mode=vr
```

No `X-Cache` headers = direct ATON connection.

## Troubleshooting

### SSL verification error

If you see errors like `SSL certificate problem: self signed certificate`:

Verify `proxy_ssl_verify off;` is present in both `/aldrovandi/` locations.

### VR mode not routing correctly

Check Nginx error logs:
```bash
sudo tail -f /var/log/nginx/error.log
```

Verify ATON HTTPS is running:
```bash
docker compose logs aton | grep "HTTPS ATON"
```

Should see:
```
HTTPS ATON up and running!
- OFFLINE: https://localhost:8083
```