#!/usr/bin/env bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd -P)

iface="${iface:-enp0s8}"
cluster_ips="192.168.55.31,192.168.55.32,192.168.55.33"
IFS=',' read -r -a iparr <<< ${cluster_ips}



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


fun_system() {
while true; do
    sed -i.bak 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list;
    apt update -y;
    apt install -y openjdk-11-jdk gosu jq expect && java -version && break;
done
}

fun_install(){
    flink_home="/opt/flink"
    mkdir -p ${flink_home}
    chown -R hduser:hadoop ${flink_home}
    echo "install flink .............."
    gosu hduser bash -c "curl -fsSL https://mirrors.sustech.edu.cn/apache/flink/flink-1.20.0/flink-1.20.0-bin-scala_2.12.tgz | tar -xz --strip-components 1 --directory ${flink_home}"
    gosu hduser bash -c "mkdir -p ${flink_home}/plugins/flink-s3 && /bin/cp --force ${flink_home}/opt/flink-s3-fs-presto*.jar ${flink_home}/plugins/flink-s3"
    cat > /etc/profile.d/myflink.sh <<EOF
export FLINK_HOME=${flink_home}
export PATH=\$PATH:\$FLINK_HOME/bin:\$FLINK_HOME/sbin
EOF
    /bin/cp -r -v /vagrant/configs/flink/* ${flink_home}

    sed -i.bak \
        -e "s@.*rest\.address:.*@rest.address: $ip4@g" \
        -e "s@.*rest\.bind-address:.*@rest.bind-address: 0.0.0.0@" \
        -e "s@.*taskmanager\.host:.*@taskmanager.host: $ip4@" \
        -e "s@.*taskmanager\.bind-host:.*@taskmanager.bind-host: 0.0.0.0@" \
        -e "s@.*jobmanager\.rpc\.address:.*@jobmanager.rpc.address: $ip4@" \
        -e "s@.*jobmanager\.bind-host:.*@jobmanager.bind-host: 0.0.0.0@" \
        -e "s@_MINIO_VIP_@$ip4@" \
        ${flink_home}/conf/flink-conf.yaml
    

    # taskmanager.bind-host: localhost    
    # taskmanager.host: localhost
    # jobmanager.rpc.address: localhost
    # jobmanager.bind-host: localhost
    # rest.address: localhost
    # rest.bind-address: localhost

}


fun_system && fun_install