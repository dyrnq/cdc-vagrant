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
        --hostname-prefix)
            hostname_prefix="$2"
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


timedatectl set-timezone "Asia/Shanghai"

groupadd -r hadoop --gid=4000 || true
useradd -m -g hadoop --uid=4000 --shell=/bin/bash hduser || true
echo "hduser:ppp" | sudo chpasswd
if [ -d /etc/sudoers.d ] ; then
    echo "hduser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/hduser
else
    grep "hduser" /etc/sudoers || echo "hduser ALL=(ALL) NOPASSWD:ALL" /etc/sudoers
fi


gosu hduser bash -c "ssh-keygen -t rsa -b 4096 -N '' -m PEM <<<$'\ny\n'"
gosu hduser bash -c "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"
gosu hduser bash -c "chmod 600 ~/.ssh/authorized_keys"
## 拷贝证书到其他hadoop集群机器

sed -i "s@.*PasswordAuthentication.*@PasswordAuthentication yes@g" /etc/ssh/sshd_config
systemctl restart sshd

sleep 4s;

for e in "${iparr[@]}" ;do
    if [ "$e" = "$ip4" ]; then
        continue
    else
        (


        while true; do
            sleep 2s && echo "wait for ${e} 22" && nc -nvz "${e}" 22 && break
        done


        while true; do


cat > /tmp/auto_ssh_copy_id.sh << EOF
set timeout -1;
spawn ssh-copy-id -p 22 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null hduser@${e};
expect {
    *(yes/no)* {send -- yes\r;exp_continue;}
    *assword:* {send -- ppp\r;exp_continue;}
    eof        {exit 0;}
}
EOF


            echo "ssh-copy-id $e" && sleep 2s && gosu hduser expect -f /tmp/auto_ssh_copy_id.sh && break;
        done
        )
    fi   
done

for e in "${iparr[@]}" ;do
    tmpn=$(echo -n "${e}" | awk -F "." '{print $NF}');
    sed -i "/$tmpn/d" /etc/hosts
    grep "${e}" /etc/hosts || echo "${e}" "$hostname_prefix${tmpn}" >> /etc/hosts;
done


cat /etc/hosts


}
fun_install(){
    hadoop_home="/opt/hadoop"
    mkdir -p ${hadoop_home}
    chown -R hduser:hadoop ${hadoop_home}
    echo "install hadoop .............."
    gosu hduser bash -c "curl -fsSL https://mirrors.ustc.edu.cn/apache/hadoop/common/hadoop-3.3.4/hadoop-3.3.4.tar.gz | tar -xz --strip-components 1 --directory ${hadoop_home}"

    cat > /etc/profile.d/myhadoop.sh <<EOF
export HADOOP_HOME=${hadoop_home}
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
EOF

    /bin/cp -r /vagrant/configs/hadoop/* ${hadoop_home}

    mkdir -p /data/hadoop/tmp
    chown -R hduser:hadoop /data/hadoop
    chmod -R a+w /data/hadoop

}










fun_system && fun_install

