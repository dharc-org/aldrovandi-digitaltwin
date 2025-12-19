#!/bin/bash
set -e

echo "=== MELODY Dashboard ==="

# Configura endpoint SPARQL se passato via env
if [ -n "$SPARQL_ENDPOINT" ]; then
    echo "SPARQL Endpoint configurato: $SPARQL_ENDPOINT"
    
    # Prova a configurare il conf.py se esiste
    if [ -f "conf.py" ]; then
        sed -i "s|SPARQL_ENDPOINT.*=.*|SPARQL_ENDPOINT = \"$SPARQL_ENDPOINT\"|g" conf.py 2>/dev/null || true
    fi
fi

# Sostituisci URL hardcoded con SERVER_HOST e porta esterna
if [ -n "$SERVER_HOST" ] && [ -n "$MELODY_PORT" ]; then
    echo "Sostituzione URL hardcoded con $SERVER_HOST:$MELODY_PORT..."
    
    # Fix nei template HTML
    find /app/templates -name "*.html" -exec sed -i "s|http://127.0.0.1:5000|http://${SERVER_HOST}:${MELODY_PORT}|g" {} \; 2>/dev/null || true
    
    # Fix nei file JS
    find /app/static/js -name "*.js" -exec sed -i "s|http://127.0.0.1:5000|http://${SERVER_HOST}:${MELODY_PORT}|g" {} \; 2>/dev/null || true
    
    echo "URL sostituiti."
fi

echo "Avvio MELODY su porta 5000 come porta docker interna"

# Avvia con gunicorn (production) - porta interna 5000
exec gunicorn --bind 0.0.0.0:5000 --workers 4 --threads 4 "app:app"