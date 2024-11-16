#!/usr/bin/env bash

docker run -it --rm --network host mysql:5.7.41 mysql --host 192.168.56.211 --user root -P9030 -e "use app_db;select * from orders;"
docker run -it --rm --network host mysql:5.7.41 mysql --host 192.168.56.211 --user root --password=123456 -e "use app_db;select * from orders;"
docker run -it --rm --network host mysql:5.7.41 mysql --host 192.168.56.211 --user root --password=123456 -e "use app_db; INSERT INTO orders VALUES (3, 66); "
docker run -it --rm --network host mysql:5.7.41 mysql --host 192.168.56.211 --user root --password=123456 -e "use app_db; INSERT INTO orders VALUES (4, 88); "
docker run -it --rm --network host mysql:5.7.41 mysql --host 192.168.56.211 --user root -P9030 -e "use app_db;select * from orders;"