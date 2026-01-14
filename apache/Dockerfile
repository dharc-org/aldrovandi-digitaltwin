FROM httpd:2.4-alpine

# Installa openssl per certificati e gettext per envsubst
RUN apk add --no-cache openssl gettext

# Abilita moduli necessari
RUN sed -i \
    -e 's/#LoadModule ssl_module/LoadModule ssl_module/' \
    -e 's/#LoadModule socache_shmcb_module/LoadModule socache_shmcb_module/' \
    -e 's/#LoadModule proxy_module/LoadModule proxy_module/' \
    -e 's/#LoadModule proxy_http_module/LoadModule proxy_http_module/' \
    -e 's/#LoadModule rewrite_module/LoadModule rewrite_module/' \
    -e 's/#LoadModule headers_module/LoadModule headers_module/' \
    /usr/local/apache2/conf/httpd.conf

# Copia config e entrypoint
COPY httpd-ssl.conf /usr/local/apache2/conf/extra/httpd-ssl.conf.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Includi config SSL nel httpd.conf
RUN echo "Include conf/extra/httpd-ssl.conf" >> /usr/local/apache2/conf/httpd.conf

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
CMD ["httpd-foreground"]