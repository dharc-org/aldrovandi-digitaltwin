vcl 4.1;

import std;

# Backend ATON (3D Framework)
backend aton {
    .host = "aton";
    .port = "8080";
    .connect_timeout = 5s;
    .first_byte_timeout = 60s;
    .between_bytes_timeout = 30s;
}

# Backend MELODY (Dashboard API)
backend melody {
    .host = "melody";
    .port = "5000";
    .connect_timeout = 5s;
    .first_byte_timeout = 30s;
    .between_bytes_timeout = 10s;
}

# Selezione backend basata su URL
sub vcl_recv {
    # Health check endpoint
    if (req.url == "/varnish-health") {
        return (synth(200, "OK"));
    }
    
    # Route /melody/* verso MELODY backend
    if (req.url ~ "^/melody") {
        set req.backend_hint = melody;
    } else {
        set req.backend_hint = aton;
    }
    
    # Normalizza Accept-Encoding per migliorare cache hit rate
    if (req.http.Accept-Encoding) {
        if (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elsif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            unset req.http.Accept-Encoding;
        }
    }
    
    # Rimuovi cookies per risorse statiche (permette caching)
    if (req.url ~ "\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|gltf|glb|obj|mtl|bin|hdr|mp3|mp4|webm|ogg|json)(\?.*)?$") {
        unset req.http.Cookie;
        return (hash);
    }
    
    # Non cachare richieste con autenticazione
    if (req.http.Authorization) {
        return (pass);
    }
    
    # Cachea GET e HEAD
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }
    
    return (hash);
}

# Gestione risposta dal backend
sub vcl_backend_response {
    # Cache lunga per risorse statiche (7 giorni)
    if (bereq.url ~ "\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)(\?.*)?$") {
        set beresp.ttl = 7d;
        set beresp.grace = 1d;
        unset beresp.http.Set-Cookie;
        set beresp.http.Cache-Control = "public, max-age=604800";
        return (deliver);
    }
    
    # Cache molto lunga per assets 3D (14 giorni) - sono pesanti e cambiano raramente
    if (bereq.url ~ "\.(gltf|glb|obj|mtl|bin|hdr)(\?.*)?$") {
        set beresp.ttl = 14d;
        set beresp.grace = 2d;
        unset beresp.http.Set-Cookie;
        set beresp.http.Cache-Control = "public, max-age=1209600";
        return (deliver);
    }
    
    # Cache per audio/video (7 giorni)
    if (bereq.url ~ "\.(mp3|mp4|webm|ogg|wav)(\?.*)?$") {
        set beresp.ttl = 7d;
        set beresp.grace = 1d;
        unset beresp.http.Set-Cookie;
        set beresp.http.Cache-Control = "public, max-age=604800";
        return (deliver);
    }
    
    # Cache breve per JSON API e chiamate MELODY (5 minuti)
    # ESCLUSI i file statici sotto /melody/static/ che hanno già il loro TTL
    if (bereq.url ~ "^/melodycall" || (bereq.url ~ "/api/" && bereq.url !~ "/static/")) {
        set beresp.ttl = 5m;
        set beresp.grace = 1m;
        # NON rimuovere Set-Cookie per API (potrebbe contenere session data)
        # Gli header Access-Control-* vengono preservati automaticamente
        return (deliver);
    }
    
    # Cache breve per HTML (1 minuto)
    if (beresp.http.Content-Type ~ "text/html") {
        set beresp.ttl = 1m;
        set beresp.grace = 30s;
    }
    
    # Non cachare errori
    if (beresp.status >= 400) {
        set beresp.ttl = 0s;
        set beresp.uncacheable = true;
    }
    
    return (deliver);
}

# Aggiunge header per debug
sub vcl_deliver {
    # Header per vedere se è cache HIT o MISS
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
    } else {
        set resp.http.X-Cache = "MISS";
    }
    
    # Rimuovi header interni di Varnish (opzionale, per sicurezza)
    unset resp.http.X-Varnish;
    unset resp.http.Via;
    
    return (deliver);
}

# Health check response
sub vcl_synth {
    if (resp.status == 200 && resp.reason == "OK") {
        set resp.http.Content-Type = "text/plain";
        synthetic("Varnish OK");
        return (deliver);
    }
}
