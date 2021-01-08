FROM alpine

# integrate privoxy with adb-files
EXPOSE 8118
HEALTHCHECK --interval=30s --timeout=3s CMD nc -z localhost 8118
RUN apk --no-cache --update add privoxy wget ca-certificates sed bash && \
    cd /etc/privoxy && \
    wget https://raw.githubusercontent.com/FunCyRanger/adblock2privoxy/genfiles/privoxy/ab2p.action && \
    wget https://raw.githubusercontent.com/FunCyRanger/adblock2privoxy/genfiles/privoxy/ab2p.filter && \
    wget https://raw.githubusercontent.com/FunCyRanger/adblock2privoxy/genfiles/privoxy/ab2p.system.action && \
    wget https://raw.githubusercontent.com/FunCyRanger/adblock2privoxy/genfiles/privoxy/ab2p.system.filter && \
    sed -i'' 's/127\.0\.0\.1:8118/0\.0\.0\.0:8118/' /etc/privoxy/config && \
    sed -i'' 's/enable-edit-actions\ 0/enable-edit-actions\ 1/' /etc/privoxy/config && \
    sed -i'' 's/#max-client-connections/max-client-connections/' /etc/privoxy/config && \
    sed -i'' 's/accept-intercepted-requests\ 0/accept-intercepted-requests\ 1/' /etc/privoxy/config && \ 
    sed -i'' 's/#debug/debug/' /etc/privoxy/config && \	
    echo 'actionsfile ab2p.system.action' >> /etc/privoxy/config && \
    echo 'actionsfile ab2p.action' >> /etc/privoxy/config && \
    echo 'filterfile ab2p.system.filter' >> /etc/privoxy/config && \
    echo 'filterfile ab2p.filter' >> /etc/privoxy/config && \
    chown privoxy.privoxy /etc/privoxy/*

# add installation of apache2
# modify httpd-conf 4 privoxy
RUN apk add apache2 && \
    sed -i'' 's/#LoadModule rewrite_module/LoadModule rewrite_module/' /etc/apache2/httpd.conf && \
    echo -E '<VirtualHost *:80>'  >> /etc/apache2/httpd.conf  && \
    echo -E '  ServerName my-apache4privoxy'  >> /etc/apache2/httpd.conf  && \
    echo -E '  DocumentRoot /var/www/localhost/htdocs'  >> /etc/apache2/httpd.conf  && \
    echo -E '  RewriteEngine on'  >> /etc/apache2/httpd.conf  && \
    echo -E '  RewriteRule ^/([^/]*?)\.([^/.]+)(?:\.([^/.]+))?(?:\.([^/.]+))?(?:\.([^/.]+))?(?:\.([^/.]+))?(?:\.([^/.]+))?(?:\.([^/.]+))?(?:\.([^/.]+))?/ab2p.css$ /$9/$8/$7/$6/$5/$4/$3/$2/$1/ab2p.css [N]'  >> /etc/apache2/httpd.conf  && \
    echo -E '  RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f'  >> /etc/apache2/httpd.conf  && \
    echo -E '  RewriteRule (^.*/+)[^/]+/+ab2p.css$ $1ab2p.css [N]'  >> /etc/apache2/httpd.conf  && \
    echo -E '</VirtualHost>' >> /etc/apache2/httpd.conf  && \
    apk add git && \
    git clone https://github.com/FunCyRanger/adblock2privoxy.git -b genfiles /tmp/adblock2privoxy && \
    mv /tmp/adblock2privoxy/css/ /var/www/localhost/htdocs/privoxy && \
    rm -R /tmp/adblock2privoxy && \
    chmod 777 -R /var/www/localhost/htdocs/ && \
    apk del git wget && \
    echo -E 'privoxy --user privoxy /etc/privoxy/config' >> /usr/bin/start.sh && \
    echo -E 'httpd' >> /usr/bin/start.sh && \
    chmod 750 /usr/bin/start.sh && \
    /bin/sh -c /usr/bin/start.sh
ENTRYPOINT ["/bin/sh -c"]
CMD ["/usr/bin/start.sh"]
