#!/usr/bin/env bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd -P)

iface="${iface:-enp0s8}"
cluster_ips="192.168.55.31,192.168.55.32,192.168.55.33"
IFS=',' read -r -a iparr <<< ${cluster_ips}
flink_cdc_home="${flink_cdc_home:-/opt/flink-cdc}"
ver="${ver:-3.2.0}"


while [ $# -gt 0 ]; do
    case "$1" in
        --iface|-i)
            iface="$2"
            shift
            ;;
        --flink-cdc-home)
            flink_cdc_home="$2"
            shift
            ;;
        --version|--ver)
            ver="$2"
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


fun_system() {
while true; do
    sed -i.bak 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list;
    apt update -y;
    apt install -y openjdk-11-jdk gosu jq expect && java -version && break;
done
}

fun_install(){
    # flink_cdc_home="/opt/flink-cdc"
    mkdir -p "${flink_cdc_home}"
    chown -R hduser:hadoop "${flink_cdc_home}"
    echo "install flink cdc ${flink_cdc_home} .............."
    gosu hduser bash -c "curl -f#SL https://mirrors.ustc.edu.cn/apache/flink/flink-cdc-${ver}/flink-cdc-${ver}-bin.tar.gz | tar -xz --strip-components 1 --directory ${flink_cdc_home}"
    chown -R hduser:hadoop "${flink_cdc_home}"
}

fun_install_post(){

pushd "${flink_cdc_home}"/lib || exit
curl -C- -fSL -# -O https://maven.aliyun.com/repository/public/org/apache/flink/flink-cdc-pipeline-connector-doris/${ver}/flink-cdc-pipeline-connector-doris-${ver}.jar
curl -C- -fSL -# -O https://maven.aliyun.com/repository/public/org/apache/flink/flink-cdc-pipeline-connector-mysql/${ver}/flink-cdc-pipeline-connector-mysql-${ver}.jar
curl -C- -fSL -# -O https://maven.aliyun.com/repository/public/mysql/mysql-connector-java/8.0.27/mysql-connector-java-8.0.27.jar

chown -R hduser:hadoop "${flink_cdc_home}"
popd || exit

}


fun_system && fun_install && fun_install_post