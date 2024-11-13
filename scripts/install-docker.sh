#!/usr/bin/env bash

iface="enp0s8"



while [ $# -gt 0 ]; do
    case "$1" in
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


command_exists() {
    command -v "$@" > /dev/null 2>&1
}




fun_system() {

## 设置时区

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

## sysctl设置

cat > /etc/sysctl.d/mysysctl.conf << 'EOF'
fs.file-max = 52706963 
fs.inotify.max_queued_events = 16384
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches = 1048576
fs.may_detach_mounts = 1
fs.nr_open = 52706963
kernel.core_uses_pid = 1
kernel.msgmax = 65535
kernel.msgmnb = 65535 
kernel.pid_max = 4194303 
kernel.shmall = 4294967296
kernel.shmmax = 68719476736
kernel.softlockup_all_cpu_backtrace = 1
kernel.softlockup_panic = 1
#kernel.sysrq = 1
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.core.netdev_max_backlog = 16384
net.core.rmem_max = 16777216
net.core.somaxconn = 32768
net.core.wmem_max = 16777216
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.all.route_localnet = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.neigh.default.gc_stale_time = 120
net.ipv4.neigh.default.gc_thresh1 = 8192
net.ipv4.neigh.default.gc_thresh2 = 32768
net.ipv4.neigh.default.gc_thresh3 = 65536
net.ipv4.tcp_fin_timeout = 20
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_max_orphans = 32768
net.ipv4.tcp_max_syn_backlog = 8096
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_retries2 = 2
net.ipv4.tcp_rmem = 4096 12582912 16777216
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_wmem = 4096 12582912 16777216
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.netfilter.nf_conntrack_max = 25000000
net.netfilter.nf_conntrack_tcp_timeout_close = 3
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_established = 180
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 12
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
net.nf_conntrack_max = 25000000
vm.max_map_count = 262144
vm.min_free_kbytes = 262144
vm.overcommit_memory = 1
vm.panic_on_oom = 0
vm.swappiness = 0
EOF


sysctl --system

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


## 加载linux内核模块

if ! systemctl is-active systemd-modules-load.service >/dev/null 2>&1; then
    systemctl enable systemd-modules-load.service
fi

cat > /etc/modules-load.d/90-net.conf<<EOF
overlay
br_netfilter
EOF

systemctl daemon-reload && systemctl restart systemd-modules-load.service

lsmod | grep br_netfilter

}





fun_install() {

while true ; do
  apt update -y && \
  apt install -y apt-transport-https bash-completion bridge-utils ca-certificates conntrack conntrack curl difference gettext gnupg2 htop iftop iproute2 ipset iptables ipvsadm jq less locales lrzsz lsof mtr netcat net-tools nfs-common nload nmap nmap-common openssh-client procps psmisc rsync socat software-properties-common strace sysstat tar tcpdump telnet tree unzip vim wget xfsprogs xz-utils && \
  break
done




## https://docs.docker.com/engine/install/ubuntu/
mkdir -p /etc/apt/keyrings
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.sustech.edu.cn/docker-ce/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update -y && apt-cache madison docker-ce


apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# apt-get install docker-compose-plugin

mkdir -p /etc/docker && \
cat >/etc/docker/daemon.json <<EOF
{
    "live-restore": true,
    "exec-opts": ["native.cgroupdriver=systemd"],
    "registry-mirrors": [
        "https://docker.m.daocloud.io"
    ],
    "log-level": "info",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m"
    }
}
EOF
systemctl daemon-reload
if systemctl is-active docker &>/dev/null; then
    systemctl restart docker
else
    systemctl enable --now docker
fi

docker info
}


fun_system && fun_install

