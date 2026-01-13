#!/bin/sh
set -e

echo "=== Apache Reverse Proxy ==="

SSL_DIR="/usr/local/apache2/ssl"
mkdir -p "$SSL_DIR"

# Genera certificato SSL self-signed se non esiste
if [ ! -f "$SSL_DIR/apache.key" ] || [ ! -f "$SSL_DIR/apache.crt" ]; then
    echo "Generazione certificato SSL self-signed..."
    
    # Usa SERVER_HOST se definito, altrimenti localhost
    CN="${SERVER_HOST:-localhost}"
    
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -keyout "$SSL_DIR/apache.key" \
        -out "$SSL_DIR/apache.crt" \
        -subj "/CN=$CN/O=Aldrovandi DigitalTwin/C=IT" \
        2>/dev/null
    
    chmod 600 "$SSL_DIR/apache.key"
    chmod 644 "$SSL_DIR/apache.crt"
    
    echo "Certificato SSL generato per: $CN"
else
    echo "Certificato SSL già presente"
fi

# Processa template httpd-ssl.conf con variabili d'ambiente
echo "Configurazione Apache..."
export SERVER_HOST="${SERVER_HOST:-localhost}"
envsubst < /usr/local/apache2/conf/extra/httpd-ssl.conf.template > /usr/local/apache2/conf/extra/httpd-ssl.conf

echo "Apache pronto"
echo "   HTTP:  porta 80  (redirect a HTTPS)"
echo "   HTTPS: porta 443"

# Avvia Apache
exec "$@"