#!/usr/bin/env bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd -P)

iface="${iface:-enp0s8}"
cluster_ips="192.168.55.31,192.168.55.32,192.168.55.33"
IFS=',' read -r -a iparr <<< ${cluster_ips}
hadoop_home="${hadoop_home:-/opt/hadoop}"
ver="${ver:-3.3.5}"


while [ $# -gt 0 ]; do
    case "$1" in
        --iface|-i)
            iface="$2"
            shift
            ;;
        --hadoop-home)
            hadoop_home="$2"
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
    # hadoop_home="/opt/hadoop"
    mkdir -p "${hadoop_home}"
    chown -R hduser:hadoop "${hadoop_home}"
    echo "install hadoop .............."
    gosu hduser bash -c "curl -f#SL https://mirrors.ustc.edu.cn/apache/hadoop/common/hadoop-${ver}/hadoop-${ver}.tar.gz | tar -xz --strip-components 1 --directory ${hadoop_home}"

    cat > /etc/profile.d/myhadoop.sh <<EOF
export HADOOP_HOME=${hadoop_home}
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
EOF

    /bin/cp -r -v /vagrant/configs/hadoop/* "${hadoop_home}"

    mkdir -p /data/hadoop/tmp
    chown -R hduser:hadoop /data/hadoop
    chmod -R a+w /data/hadoop

}










fun_system && fun_install

