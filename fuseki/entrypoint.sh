#!/bin/bash
set -e

FUSEKI_HOME=/fuseki
DATA_DIR=/staging
DB_DIR=${FUSEKI_HOME}/databases/chad-kg
MARKER_FILE=${DB_DIR}/.data_loaded

echo "=== Aldrovandi Fuseki SPARQL Server ==="

# Avvia Fuseki in background per caricare i dati
echo "Avvio Fuseki..."
${FUSEKI_HOME}/fuseki-server --config=${FUSEKI_HOME}/configuration/chad-kg.ttl &
FUSEKI_PID=$!

# Aspetta che Fuseki sia pronto
echo "Attendo che Fuseki sia pronto..."
until curl -s http://localhost:3030/$/ping > /dev/null 2>&1; do
    sleep 2
done
echo "Fuseki è pronto!"

# Carica i dati solo se non già caricati
if [ ! -f "$MARKER_FILE" ]; then
    echo "Prima esecuzione - carico i dati TTL..."
    
    # Carica chad_kg.ttl se esiste
    if [ -f "${DATA_DIR}/chad_kg.ttl" ]; then
        echo "Caricamento chad_kg.ttl..."
        curl -X POST "http://localhost:3030/chad-kg/data" \
            -H "Content-Type: text/turtle" \
            --data-binary "@${DATA_DIR}/chad_kg.ttl"
        echo " OK"
    else
        echo "ATTENZIONE: ${DATA_DIR}/chad_kg.ttl non trovato"
    fi
    
    # Carica chad-ap.ttl se esiste
    if [ -f "${DATA_DIR}/chad-ap.ttl" ]; then
        echo "Caricamento chad-ap.ttl..."
        curl -X POST "http://localhost:3030/chad-kg/data" \
            -H "Content-Type: text/turtle" \
            --data-binary "@${DATA_DIR}/chad-ap.ttl"
        echo " OK"
    else
        echo "ATTENZIONE: ${DATA_DIR}/chad-ap.ttl non trovato"
    fi
    
    # Crea marker per evitare ricaricamento
    mkdir -p ${DB_DIR}
    touch ${MARKER_FILE}
    echo "Dati caricati con successo!"
else
    echo "Dati già presenti, skip caricamento."
fi

echo "=== Fuseki pronto su http://localhost:3030 ==="
echo "SPARQL endpoint: http://localhost:3030/chad-kg/sparql"

# Attendi il processo Fuseki
wait $FUSEKI_PID
