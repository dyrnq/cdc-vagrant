#!/usr/bin/env bash



mkdir -p /opt/flink-cdc
cat >/opt/flink-cdc/docker-compose.yml<<EOF
services:
  doris-fe:
    image: dyrnq/doris:2.1.7
    hostname: doris-fe
    network_mode: host
    environment:
      - TZ=Asia/Shanghai
      - RUN_MODE=fe
      - ENABLE_FQDN_MODE=false
      - FE_SERVERS=fe1:192.168.56.211:9010
      - FE_ID=1
  doris-be:
    image: dyrnq/doris:2.1.7
    hostname: doris-be
    network_mode: host
    environment:
      - TZ=Asia/Shanghai
      - RUN_MODE=be
      - ENABLE_FQDN_MODE=false
      - FE_SERVERS=fe1:192.168.56.211:9010
      - BE_ADDR=192.168.56.211:9050
  mysql:
    image: debezium/example-mysql:1.1
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=123456
      - MYSQL_USER=mysqluser
      - MYSQL_PASSWORD=mysqlpw
      - TZ=Asia/Shanghai
    volumes:
      - /etc/timezone:/etc/timezone:ro
EOF
