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
    apt install -y openjdk-11-jdk && java -version && break;
done

timedatectl set-timezone "Asia/Shanghai"

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
EOF

}

fun_install(){

mkdir -p /opt/zookeeper/logs/
mkdir -p /opt/zookeeper/data/

curl -fsSL http://mirrors.tencent.com/apache/zookeeper/zookeeper-3.8.0/apache-zookeeper-3.8.0-bin.tar.gz | tar -xvz --strip-components 1 --directory /opt/zookeeper


local _index="0";
for i in "${!iparr[@]}"; do
   if [[ "${iparr[$i]}" = "${ip4}" ]]; then
       _index="${i}";
       break;
   fi
done


cat > /opt/zookeeper/conf/zoo.cfg <<EOF
tickTime=2000
dataDir=/opt/zookeeper/data
dataLogDir=/opt/zookeeper/logs
clientPort=2181
initLimit=10
syncLimit=5
4lw.commands.whitelist=*
EOF
# server.1=192.168.33.181:2888:3888
# server.2=192.168.33.182:2888:3888
# server.3=192.168.33.183:2888:3888


for i in "${!iparr[@]}"; do
    local str=""
    str="server.$((i+1))=${iparr[$i]}:2888:3888"
    echo "${str}" >> /opt/zookeeper/conf/zoo.cfg
done

local _index="0";
for i in "${!iparr[@]}"; do
   if [[ "${iparr[$i]}" = "${ip4}" ]]; then
       _index="${i}";
       break;
   fi
done

echo "$((_index+1))" > /opt/zookeeper/data/myid



cat >/lib/systemd/system/zookeeper.service<<EOF
[Unit]
Description=zookeeper.service
After=network.target
[Service]
Type=forking

WorkingDirectory=/opt/zookeeper
Environment=ZOO_LOG4J_PROP=INFO,ROLLINGFILE
Environment=ZOOPIDFILE=/var/run/zookeeper.pid
ExecStart=/opt/zookeeper/bin/zkServer.sh start
ExecStop=/opt/zookeeper/bin/zkServer.sh stop
ExecReload=/opt/zookeeper/bin/zkServer.sh restart

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
if systemctl is-active zookeeper &>/dev/null; then
    systemctl restart zookeeper
else
    systemctl enable --now zookeeper
fi
systemctl status -l zookeeper --no-pager

}

fun_system && fun_install