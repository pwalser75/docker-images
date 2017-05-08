FROM nginx:alpine 
COPY default.conf /etc/nginx/conf.d/default.conf 
COPY server.crt /etc/nginx/cert.crt
COPY server.key /etc/nginx/cert.key
COPY content /usr/share/nginx/html
