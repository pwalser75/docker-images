# Docker Images
A collection of docker images serving as examples of common deployment scenarios.

## NGINX static
NGINX web server serving static resources (the [Angular2 Demo](https://github.com/pwalser75/angular2-demo)) using HTTPS, also redirecting HTTP requests to HTTPS.
Create image / run:

    docker build -t nginx-example:latest .
    docker run -d --name nginx-example -p 80:80 -p 443:443 --restart=always nginx-example:latest

## MySQL with data volume
MySQL database, with a persistent data volume, using Docker Compose.

Create image / run:

    docker-compose up -d

