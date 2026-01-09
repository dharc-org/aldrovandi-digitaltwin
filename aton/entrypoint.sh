#!/bin/bash
set -e

echo "=== ATON Framework - Aldrovandi ==="

# Configura endpoint SPARQL se necessario
if [ -n "$SPARQL_ENDPOINT" ]; then
    echo "Configurazione SPARQL endpoint: $SPARQL_ENDPOINT"
    
    # Esegui il patch per aggiornare l'endpoint nei file JS
    node /patch-sparql.js "$SPARQL_ENDPOINT" || true
fi

# Verifica contenuti
if [ -d "/app/aton/wapps/aldrovandi/content" ]; then
    CONTENT_COUNT=$(find /app/aton/wapps/aldrovandi/content -type f 2>/dev/null | wc -l)
    echo "Contenuti Aldrovandi trovati: $CONTENT_COUNT file"
else
    echo "ATTENZIONE: cartella content vuota - inserisci i contenuti di Marcello"
fi

# Sostituisci URL MELODY hardcoded con IP server (per chiamate dal browser)
if [ -n "$SERVER_HOST" ]; then
    echo "Configurazione URL MELODY..."
    
    # Usa MELODY_PUBLIC_PORT se definita, altrimenti MELODY_PORT
    PUBLIC_PORT="${MELODY_PUBLIC_PORT:-$MELODY_PORT}"
    
    # Base path (es: /aldrovandi) - default vuoto
    BASE_PATH="${BASE_PATH:-}"
    
    # Path endpoint MELODY (default: /melody, con nginx: /melodycall)
    MELODY_PATH="${MELODY_PATH:-/melody}"
    
    # Se la porta è 443, usa https senza porta
    # Se la porta è 80, usa http senza porta
    # Altrimenti usa http con porta esplicita
    if [ "$PUBLIC_PORT" = "443" ]; then
        MELODY_URL="https://${SERVER_HOST}${BASE_PATH}${MELODY_PATH}"
        echo "URL MELODY (HTTPS): ${MELODY_URL}"
    elif [ "$PUBLIC_PORT" = "80" ]; then
        MELODY_URL="http://${SERVER_HOST}${BASE_PATH}${MELODY_PATH}"
        echo "URL MELODY (HTTP): ${MELODY_URL}"
    else
        MELODY_URL="http://${SERVER_HOST}:${PUBLIC_PORT}${BASE_PATH}${MELODY_PATH}"
        echo "URL MELODY: ${MELODY_URL}"
    fi
    
    # Sostituisci in tutti i file js, json, html
    # Sostituisce http://127.0.0.1:5000/melody con il nuovo URL
    find /app/aton/wapps/aldrovandi \( -name "*.js" -o -name "*.json" -o -name "*.html" \) -exec \
        sed -i "s|http://127.0.0.1:5000/melody|${MELODY_URL}|g" {} \;
    echo "URL sostituiti in $(find /app/aton/wapps/aldrovandi \( -name "*.js" -o -name "*.json" -o -name "*.html" \) | wc -l) file"
fi


#uncomment per nginx reverse proxy
# FILES=$(find /app/aton/wapps/aldrovandi \( -name "*.js" -o -name "*.json" -o -name "*.html" \))

# for file in $FILES; do
#     # Pattern 1: http://127.0.0.1:5000/melody -> MELODY_URL
#     sed -i "s|http://127.0.0.1:5000/melody|${MELODY_URL}|g" "$file"
    
#     # Pattern 2: http://localhost:5000/melody -> MELODY_URL
#     sed -i "s|http://localhost:5000/melody|${MELODY_URL}|g" "$file"
    
#     # Pattern 3: Rimuovi :5010 da qualsiasi URL che contiene melodycall
#     sed -i "s|http://\([^:]*\):5010\(${BASE_PATH}${MELODY_PATH}\)|https://\1\2|g" "$file"
    
#     # Pattern 4: Rimuovi http:// e sostituisci con https:// per il dominio pubblico
#     sed -i "s|http://${SERVER_HOST}${BASE_PATH}${MELODY_PATH}|${MELODY_URL}|g" "$file"
    
#     # Pattern 5: localhost:5000/melody (senza http/https)
#     sed -i "s|localhost:5000/melody|${SERVER_HOST}${BASE_PATH}${MELODY_PATH}|g" "$file"
    
#     # Pattern 6: qualsiasi riferimento a :5010 seguito da aldrovandi/melodycall
#     sed -i "s|:5010/aldrovandi/melodycall|/aldrovandi/melodycall|g" "$file"
# done
# echo "Creazione symlink per case-insensitivity GLB/glb..."
# CONTENT_DIR="/app/aton/wapps/aldrovandi/content"

# if [ -d "$CONTENT_DIR" ]; then
#     cd "$CONTENT_DIR"
    
#     # Per ogni .glb crea symlink .GLB se non esiste
#     find . -name "*.glb" -type f | while read f; do
#         base=$(basename "$f")
#         target="${f%.glb}.GLB"
#         if [ ! -e "$target" ]; then
#             ln -s "$base" "$target" 2>/dev/null && echo "  Link: $target -> $base"
#         fi
#     done

#     # Per ogni .GLB crea symlink .glb se non esiste  
#     find . -name "*.GLB" -type f | while read f; do
#         base=$(basename "$f")
#         target="${f%.GLB}.glb"
#         if [ ! -e "$target" ]; then
#             ln -s "$base" "$target" 2>/dev/null && echo "  Link: $target -> $base"
#         fi
#     done
    
#     echo "Symlink case-insensitivity completati"
# fi




# ============================================
# PATCH BUG FIX per main.js
# ============================================
MAINJS="/app/aton/wapps/aldrovandi/js/main.js"

if [ -f "$MAINJS" ]; then
    echo "Applicazione patch bug fix a main.js..."
    
    # FIX 1: Null check per suiButton_PPaudio.setIcon (evita crash in non-VR)
    # Solo per chiamate a funzione, non assegnazioni
    sed -i 's/APP\.suiButton_PPaudio\.setIcon(/APP.suiButton_PPaudio \&\& APP.suiButton_PPaudio.setIcon(/g' "$MAINJS"
    
    # FIX 2: Null check per CloseObject_SUIBtn.setIcon
    sed -i 's/APP\.CloseObject_SUIBtn\.setIcon(/APP.CloseObject_SUIBtn \&\& APP.CloseObject_SUIBtn.setIcon(/g' "$MAINJS"
    
    # FIX 3: Wrap playCurrentAudio SUI update in if block
    # Trasforma: let iconPath = APP._audio.paused ? X : Y; APP.suiButton_PPaudio.setIcon(iconPath);
    # In un blocco con guard
    sed -i 's/let iconPath = APP\._audio\.paused/if (!APP._audio) return; let iconPath = APP._audio.paused/g' "$MAINJS"
    
    echo "Patch applicati a main.js"
else
    echo "ATTENZIONE: main.js non trovato, patch non applicati"
fi

echo "Avvio ATON su porta 8080 (production)..."
echo "Accedi a: http://localhost:8080/a/aldrovandi"

# Avvia ATON in production mode
export NODE_ENV=production
exec npm start
