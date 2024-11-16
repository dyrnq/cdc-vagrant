#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd -P)
wait4x_image="${wait4x_image:-atkrad/wait4x:2.12}"
mysql5_image="${mysql5_image:-mysql:5.7.41}"

pushd "${SCRIPT_DIR}"/../flink-cdc-doris || exit 1



ulimit -n 655350 || true

# ./launch.sh -d








docker run \
--network host \
--rm \
--name='wait4x' \
${wait4x_image} mysql root@tcp\(127.0.0.1:9030\)/ --interval 1s --timeout 3600s && \
docker compose exec doris-fe mysql -uroot -P9030 -h127.0.0.1 -e "show backends; show frontends;"
docker compose exec doris-fe mysql -uroot -P9030 -h127.0.0.1 -e "CREATE DATABASE app_db;"


docker run \
--network host \
--rm \
--name='wait4x' \
${wait4x_image} mysql root:123456@tcp\(127.0.0.1:3306\)/ --interval 1s --timeout 3600s && \
docker run \
-it \
--rm \
--network host \
-v "$(pwd)":/vagrant \
${mysql5_image} mysql --host 127.0.0.1 --user root --password=123456 --loose-default-character-set=utf8 -e "source /vagrant/mysql.sql;"


popd || exit 1