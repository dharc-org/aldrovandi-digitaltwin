# Nginx Configuration for Aldrovandi Digital Twin

This guide explains how to configure Nginx as a reverse proxy in front of the Docker stack.

## Architecture
```
Browser → Nginx:443 (SSL) → Apache:443 (SSL) → ATON/MELODY
```

## Production Environment (.env)

Update your `.env` file with production settings:
```bash
SERVER_HOST=projects.vidilab.unibo.it

# Ports (internal Docker)
FUSEKI_PORT=3030
```

## Nginx Configuration

Create `/etc/nginx/sites-available/aldrovandi`:
```nginx
server {
    server_name projects.vidilab.unibo.it;

    # MELODY API
    location /aldrovandi/melody/ {
        proxy_pass https://127.0.0.1:443/melody/;
        proxy_ssl_verify off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # ATON main app
    location /aldrovandi/ {
        proxy_pass https://127.0.0.1:443/a/aldrovandi/;
        proxy_ssl_verify off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # ATON framework resources
    location /res/ {
        proxy_pass https://127.0.0.1:443/res/;
        proxy_ssl_verify off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /dist/ {
        proxy_pass https://127.0.0.1:443/dist/;
        proxy_ssl_verify off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /vendors/ {
        proxy_pass https://127.0.0.1:443/vendors/;
        proxy_ssl_verify off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # SSL configuration (Let's Encrypt)
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

## Access URLs

**KIOSK:** `https://projects.vidilab.unibo.it/aldrovandi/?usebackup=true&mode=kiosk`

**VR Mode:** `https://projects.vidilab.unibo.it/aldrovandi/?usebackup=true`

## Apply Configuration
```bash
# Test configuration
sudo nginx -t

# If test passes, apply changes
sudo systemctl reload nginx
```