#!/usr/bin/env bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd -P)

iface="${iface:-enp0s8}"
FLAG_FE=${FLAG_FE:-}
FLAG_BE=${FLAG_BE:-}
fe_role=${fe_role:-}
fe_leader=${fe_leader:-}



while [ $# -gt 0 ]; do
    case "$1" in
        --fe)
            FLAG_FE=1
            ;;
        --be)
            FLAG_BE=1
            ;;
        --fe-role)
            fe_role="$2"
            shift
            ;;
        --fe-leader)
            fe_leader="$2"
            shift
            ;;
        --iface|-i)
            iface="$2"
            shift
            ;;
        --*)
            echo "Illegal option $1"
            ;;
    esac
    shift $(( $# > 0 ? 1 : 0 ))
done

ip4=$(/sbin/ip -o -4 addr list "${iface}" | awk '{print $4}' |cut -d/ -f1 | head -n1);



is_fe() {
    if [ -z "$FLAG_FE" ]; then
        return 1
    else
        return 0
    fi
}

is_be() {
    if [ -z "$FLAG_BE" ]; then
        return 1
    else
        return 0
    fi
}


command_exists() {
    command -v "$@" > /dev/null 2>&1
}

fun_system() {
while true; do
    sed -i.bak 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list;
    apt update -y;
    apt install -y openjdk-8-jdk mysql-client-core-8.0 xz-utils && java -version && break;
done

## 关闭防火墙

systemctl is-active firewalld >/dev/null 2>&1 && systemctl disable --now firewalld
systemctl is-active dnsmasq >/dev/null 2>&1 && systemctl disable --now dnsmasq
systemctl is-active apparmor >/dev/null 2>&1 && systemctl disable --now apparmor
systemctl is-active ufw >/dev/null 2>&1 && systemctl disable --now ufw

## 关闭swap

#sed -ri 's/.*swap.*/#&/' /etc/fstab
swapoff -a && sysctl -w vm.swappiness=0
sed -ri '/^[^#]*swap/s@^@#@' /etc/fstab

## 关闭selinux

if [ -f /etc/selinux/config ]; then sed -i.bak 's@enforcing@disabled@' /etc/selinux/config; fi
command -v setenforce && setenforce 0
command -v getenforce && getenforce && sestatus

## limits 修改

cat > /etc/security/limits.conf <<'EOF'
*       soft        core        unlimited
*       hard        core        unlimited
*       soft        nproc       1000000
*       hard        nproc       1000000
*       soft        nofile      1000000
*       hard        nofile      1000000
*       soft        memlock     32000
*       hard        memlock     32000
*       soft        msgqueue    8192000
*       hard        msgqueue    8192000
root       soft        core        unlimited
root       hard        core        unlimited
root       soft        nproc       1000000
root       hard        nproc       1000000
root       soft        nofile      1000000
root       hard        nofile      1000000
root       soft        memlock     32000
root       hard        memlock     32000
root       soft        msgqueue    8192000
root       hard        msgqueue    8192000
EOF

}

wait_fe_leader(){

while true; do
    sleep 2s && echo "wait for ${fe_leader} 9030" && nc -nvz "${fe_leader}" 9030 && break
done

}

fun_fe(){
local doris_fe_download_url=""
doris_fe_download_url="https://mirrors.ustc.edu.cn/apache/doris/1.2/1.2.3-rc02/apache-doris-fe-1.2.3-bin-x86_64.tar.xz"

mkdir -p /opt/doris/fe
curl -fsSL $doris_fe_download_url | tar -xvJ --strip-components 1 --directory /opt/doris/fe

# store metadata, must be created before start FE.
# Default value is ${DORIS_HOME}/doris-meta
# meta_dir = ${DORIS_HOME}/doris-meta
# meta_delay_toleration_second = 10
meta_dir="/opt/doris-data/doris-meta"
mkdir -p $meta_dir
echo "priority_networks = ${ip4}/24" >> /opt/doris/fe/conf/fe.conf
echo "meta_dir = ${meta_dir}" >> /opt/doris/fe/conf/fe.conf


local helper=" --helper $fe_leader:9010"
if [ "${fe_role}" = "observer" ] ; then
    wait_fe_leader
    mysql -h "${fe_leader}" -P 9030 -u root <<< "ALTER SYSTEM ADD OBSERVER \"${ip4}:9010\""
elif [ "${fe_role}" = "follower" ] ; then
    wait_fe_leader
    mysql -h "${fe_leader}" -P 9030 -u root <<< "ALTER SYSTEM ADD FOLLOWER \"${ip4}:9010\""
else
    helper=""
fi

# https://doris.apache.org/zh-CN/docs/admin-manual/maint-monitor/metadata-operation?_highlight=helper#%E6%B7%BB%E5%8A%A0-fe


cat > /lib/systemd/system/doris_fe.service <<EOF
[Unit]
Description=doris service
After=network.target
[Service]
Type=simple
WorkingDirectory=/opt/doris/fe
ExecStart=/bin/bash -c "bin/start_fe.sh${helper}"
ExecStop=/bin/kill -s TERM \$MAINPID
TimeoutStartSec=30
TimeoutStopSec=20
Restart=always
RestartSec=5s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
LimitNOFILE=512000
LimitNPROC=512000
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
if systemctl is-active doris_fe &>/dev/null; then
    systemctl restart doris_fe
else
    systemctl enable --now doris_fe
fi
systemctl status -l doris_fe --no-pager

}



fun_be(){
local doris_be_download_url=""


if grep avx2 < /proc/cpuinfo ; then
    doris_be_download_url="https://mirrors.ustc.edu.cn/apache/doris/1.2/1.2.3-rc02/apache-doris-be-1.2.3-bin-x86_64.tar.xz"
else
    doris_be_download_url="https://mirrors.ustc.edu.cn/apache/doris/1.2/1.2.3-rc02/apache-doris-be-1.2.3-bin-x86_64-noavx2.tar.xz"
fi


mkdir -p /opt/doris/be

curl -fsSL -o /opt/doris/apache-doris-dependencies-bin-x86_64.tar.xz https://mirrors.ustc.edu.cn/apache/doris/1.2/1.2.3-rc02/apache-doris-dependencies-1.2.3-bin-x86_64.tar.xz

rm -rf /tmp/apache-doris-dependencies
mkdir /tmp/apache-doris-dependencies
tar -xvJf /opt/doris/apache-doris-dependencies-bin-x86_64.tar.xz --strip-components 1 --directory /tmp/apache-doris-dependencies

curl -fsSL $doris_be_download_url | tar -xvJ --strip-components 1 --directory /opt/doris/be
/bin/cp -rvf /tmp/apache-doris-dependencies/java-udf-jar-with-dependencies.jar /opt/doris/be/lib

# you can specify the storage medium of each root path, HDD or SSD
# storage_root_path = /home/disk1/doris.HDD,50;/home/disk2/doris.SSD,1;/home/disk2/doris
# Default value is ${DORIS_HOME}/storage, you should create it by hand.
# storage_root_path = ${DORIS_HOME}/storage

storage_root_path="/opt/doris-data/storage"
mkdir -p $storage_root_path
echo "priority_networks = ${ip4}/24" >> /opt/doris/be/conf/be.conf
echo "storage_root_path = ${storage_root_path}" >> /opt/doris/be/conf/be.conf



wait_fe_leader

mysql -h "${fe_leader}" -P 9030 -u root <<< "ALTER SYSTEM ADD BACKEND \"${ip4}:9050\""


cat > /lib/systemd/system/doris_be.service <<EOF
[Unit]
Description=doris service
After=network.target
[Service]
Type=simple
Environment=JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
WorkingDirectory=/opt/doris/be
ExecStart=/bin/bash -c "bin/start_be.sh"
ExecStop=/bin/kill -s TERM \$MAINPID
TimeoutStartSec=30
TimeoutStopSec=20
Restart=always
RestartSec=5s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
LimitNOFILE=512000
LimitNPROC=512000
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
if systemctl is-active doris_be &>/dev/null; then
    systemctl restart doris_be
else
    systemctl enable --now doris_be
fi
systemctl status -l doris_be --no-pager





}


fun_system
if is_fe ; then
    fun_fe
fi

if is_be ; then
    fun_be
fi

# mysql -h 192.168.56.111 -P 9030 -u root 

# show proc '/frontends' \G;
# ALTER SYSTEM DROP OBSERVER "192.168.56.102:9011";
# ALTER SYSTEM DROP OBSERVER "192.168.56.112:9011";
# ALTER SYSTEM ADD OBSERVER "192.168.56.112:9010";

# show proc '/backends' \G;
# alter system add backend "slave3:9050";
# ALTER SYSTEM ADD BACKEND "192.168.56.113:9050";


# ALTER SYSTEM DROPP BACKEND "192.168.56.115:9050";
# ALTER SYSTEM DROPP BACKEND "192.168.56.116:9050";

# https://archive.apache.org/dist/doris/1.1/1.1.4-rc01/apache-doris-be-1.1.4-bin-x86_64.tar.gz
# https://archive.apache.org/dist/doris/1.1/1.1.4-rc01/apache-doris-fe-1.1.4-bin.tar.gz
# https://doris.apache.org/zh-CN/docs/install/install-deploy