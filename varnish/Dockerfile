FROM varnish:7.4-alpine

# Copia configurazione VCL
COPY default.vcl /etc/varnish/default.vcl

# Espone porta 80
EXPOSE 80

# Avvia Varnish con 2048MB di cache (configurabile via env)
CMD ["varnishd", "-F", "-a", ":80", "-f", "/etc/varnish/default.vcl", "-s", "malloc,2048m"]
