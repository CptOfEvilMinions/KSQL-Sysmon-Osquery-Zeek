# Osquery-Zeek-Kafka

## .env
This dockcer stack is pinned to certain versions in `.env`
```
CONFLUENT_VERSION=5.5.0
ROOT_LOGLEVEL=ERROR
LOGSTASH_VERSION=7.7.0
NGINX_VERSION=1.18.0-alpine
SPLUNK_VERSION=8.0.3-debian
```

## Generate TLS certificates
1. `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout conf/ssl/docker.key -out conf/ssl/docker.crt`
1. `openssl dhparam -out conf/ssl/dhparam.pem 2048`

## Build pipeline and spin up stack
1. `docker-compose build`
1. `docker-compose up -d`

## Recommended system requirements
### Zeek server
* 4 CPU cores
* 4GBs of RAM
* 40GBs of HDD

### Windows 10 client
* 2 CPU cores
* 4 GBs of RAM
* 40GBs of HDD

### Logging server
* 4 CPU cores
* 12GBs of ram
* 60 GBs of HDD

## References
* [Github - CptOfEvilMinions/MyLoggingPipeline](https://github.com/CptOfEvilMinions/MyLoggingPipeline)