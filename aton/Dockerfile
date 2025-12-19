# Dockerfile per ATON Framework
FROM node:20-slim

LABEL maintainer="OpenCitations Team"
LABEL description="ATON 3D Framework con progetto Aldrovandi"

# Installa dipendenze di sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clona il framework ATON
RUN git clone --depth 1 https://github.com/phoenixbf/aton.git

WORKDIR /app/aton

# Clona il progetto Aldrovandi nella cartella wapps
RUN cd wapps && \
    git clone --depth 1 https://github.com/MarcelloMassidda/aldrovandi.git

# Crea la cartella content per i volumi
RUN mkdir -p /app/aton/wapps/aldrovandi/content

# Installa dipendenze npm
RUN npm install

# Copia script di avvio e configurazione
COPY entrypoint.sh /entrypoint.sh
COPY patch-sparql.js /patch-sparql.js
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
