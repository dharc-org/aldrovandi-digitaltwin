# Dockerfile per MELODY Dashboard
FROM python:3.11-slim

LABEL maintainer="OpenCitations Team"
LABEL description="MELODY Dashboard per Aldrovandi (Polifonia Project)"

# Installa dipendenze di sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clona il repository MELODY dal branch specifico
RUN git clone --depth 1 --branch api-url-to-html \
    https://github.com/polifonia-project/dashboard.git melody

WORKDIR /app/melody

# Installa dipendenze Python
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir gunicorn || \
    pip install --no-cache-dir flask requests sparqlwrapper rdflib pyyaml

# Copia script di avvio
COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 5000

ENV FLASK_APP=app.py
ENV FLASK_ENV=production

ENTRYPOINT ["/entrypoint.sh"]
