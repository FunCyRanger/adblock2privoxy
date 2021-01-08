FROM alpine

# integrate privoxy with adb-files
EXPOSE 8118
HEALTHCHECK --interval=30s --timeout=3s CMD nc -z localhost 8118
RUN apk --no-cache --update add privoxy wget ca-certificates sed bash && \
    cd /etc/privoxy && \
    wget https://raw.githubusercontent.com/FunCyRanger/adblock2privoxy/master/privoxy/ab2p.action && \
    wget https://raw.githubusercontent.com/FunCyRanger/adblock2privoxy/master/privoxy/ab2p.filter && \
    wget https://raw.githubusercontent.com/FunCyRanger/adblock2privoxy/master/privoxy/ab2p.system.action && \
    wget https://raw.githubusercontent.com/FunCyRanger/adblock2privoxy/master/privoxy/ab2p.system.filter && \
    sed -i'' 's/127\.0\.0\.1:8118/0\.0\.0\.0:8118/' /etc/privoxy/config && \
    sed -i'' 's/enable-edit-actions\ 0/enable-edit-actions\ 1/' /etc/privoxy/config && \
    sed -i'' 's/#max-client-connections/max-client-connections/' /etc/privoxy/config && \
    sed -i'' 's/accept-intercepted-requests\ 0/accept-intercepted-requests\ 1/' /etc/privoxy/config && \ 
    sed -i'' 's/#debug/debug/' /etc/privoxy/config && \	
    echo 'actionsfile ab2p.system.action' >> /etc/privoxy/config && \
    echo 'actionsfile ab2p.action' >> /etc/privoxy/config && \
    echo 'filterfile ab2p.system.filter' >> /etc/privoxy/config && \
    echo 'filterfile ab2p.filter' >> /etc/privoxy/config
RUN chown privoxy.privoxy /etc/privoxy/*
ENTRYPOINT ["privoxy"]
CMD ["--no-daemon","--user","privoxy","/etc/privoxy/config"]

# add installation of apache2
# modify httpd-conf 4 privoxy
RUN apk --no-cache --update add apache2 && \
    sed -i'' 's/#LoadModule rewrite_module/LoadModule rewrite_module/' /usr/local/apache2/conf/httpd.conf && \
    echo ' \
<VirtualHost *:80> \
      #ab2p css domain name (optional, should be equal to --domainCSS parameter) ( \
      ServerName my-apache4privoxy \
      \
      #root = --webDir parameter value  \
      DocumentRoot /usr/local/apache2/htdocs \
      \
      RewriteEngine on \
      \
      # first reverse domain names order \
      RewriteRule ^/([^/]*?)\.([^/.]+)(?:\.([^/.]+))?(?:\.([^/.]+))?(?:\.([^/.]+))?(?:\.([^/.]+))?(?:\.([^/.]+))?(?:\.([^/.]+))?(?:\.([^/.]+)$ \
      # then try to get CSS for current domain \
      # if it is unavailable - get CSS for parent domain \
      RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f \
      RewriteRule (^.*/+)[^/]+/+ab2p.css$ $1ab2p.css [N] \
</VirtualHost>' > /usr/local/apache2/conf/httpd.conf
RUN httpd-foreground

# get css files from repo
RUN apk --no-cache --update add git
RUN git clone https://github.com/FunCyRanger/adblock2privoxy.git -b genfiles /tmp/adblock2privoxy
RUN ls /tmp/adblock2privoxy
RUN mkdir /usr/local/apache2/htdocs/css
RUN cp -R /tmp/adblock2privoxy/css/ /usr/local/apache2/htdocs/css
RUN rm -R /tmp/adblock2privoxy
RUN chmod 777 -R /usr/local/apache2/htdocs
