# Osquery-Zeek-Kafka

## Generate TLS certificates
1. `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout conf/ssl/docker.key -out conf/ssl/docker.crt`
1. `openssl dhparam -out conf/ssl/dhparam.pem 2048`

## Build pipeline and spin up stack
1. `docker-compose build`
1. `docker-compose up -d`

## References
* [Github - CptOfEvilMinions/MyLoggingPipeline](https://github.com/CptOfEvilMinions/MyLoggingPipeline)