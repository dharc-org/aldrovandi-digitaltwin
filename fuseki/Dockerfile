# Dockerfile per Apache Jena Fuseki
FROM eclipse-temurin:21-jre-jammy

LABEL maintainer="OpenCitations Team"
LABEL description="Apache Jena Fuseki SPARQL Server per Aldrovandi"

# Versione Fuseki
ARG FUSEKI_VERSION=5.3.0
ARG FUSEKI_HOME=/fuseki

# Installa dipendenze
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Scarica e installa Fuseki
WORKDIR /tmp
RUN curl -L -o fuseki.zip \
    "https://archive.apache.org/dist/jena/binaries/apache-jena-fuseki-${FUSEKI_VERSION}.zip" \
    && unzip fuseki.zip \
    && mv apache-jena-fuseki-${FUSEKI_VERSION} ${FUSEKI_HOME} \
    && rm fuseki.zip

# Crea directory necessarie
RUN mkdir -p ${FUSEKI_HOME}/databases \
    && mkdir -p ${FUSEKI_HOME}/configuration

# Copia lo script di avvio
COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

# Copia la configurazione del dataset
COPY config.ttl ${FUSEKI_HOME}/configuration/chad-kg.ttl

WORKDIR ${FUSEKI_HOME}

EXPOSE 3030

ENTRYPOINT ["/entrypoint.sh"]
