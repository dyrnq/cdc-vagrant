#!/usr/bin/env bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd -P)

iface="${iface:-enp0s8}"
cluster_ips="192.168.55.31,192.168.55.32,192.168.55.33"
IFS=',' read -r -a iparr <<< ${cluster_ips}
hostname_prefix="vm"



while [ $# -gt 0 ]; do
    case "$1" in
        --iface|-i)
            iface="$2"
            shift
            ;;
        --cluster-ips|--ips)
            cluster_ips="$2"
            IFS=',' read -r -a iparr <<< ${cluster_ips}
            shift
            ;;
        --*)
            echo "Illegal option $1"
            ;;
    esac
    shift $(( $# > 0 ? 1 : 0 ))
done

ip4=$(/sbin/ip -o -4 addr list "${iface}" | awk '{print $4}' |cut -d/ -f1 | head -n1);

fun_install() {


# for e in "${iparr[@]}" ;do
#     tmpn=$(echo -n "${e}" | awk -F "." '{print $NF}');
#     sed -i "/$tmpn/d" /etc/hosts
#     grep "${e}" /etc/hosts || echo "${e}" "$hostname_prefix${tmpn}" >> /etc/hosts;
# done


mkdir -p /opt/minio/data/data1
mkdir -p /opt/minio/data/data2

docker volume create --name my_volume1 --opt type=none --opt device=/opt/minio/data/data1 --opt o=bind 2>/dev/null || true
docker volume create --name my_volume2 --opt type=none --opt device=/opt/minio/data/data2 --opt o=bind 2>/dev/null || true


cat > /opt/minio/docker-compose.yml <<EOF
version: '3.7'

services:
  minio:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 5s
      timeout: 2s
      retries: 3
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    container_name: minio
    #image: quay.io/minio/minio:RELEASE.2022-11-29T23-40-49Z
    image: minio/minio:RELEASE.2022-11-29T23-40-49Z
    command: server --console-address ":9001" http://vm{116...119}/data{1...2}
    restart: always
    network_mode: "host"
    volumes:
      - my_volume1:/data1
      - my_volume2:/data2
volumes:
  my_volume1:
    external: true
    name: my_volume1
  my_volume2:
    external: true
    name: my_volume2

EOF

pushd /opt/minio >/dev/null 2>&1 || exit 0
    docker compose up -d
popd || exit 0
}

fun_install