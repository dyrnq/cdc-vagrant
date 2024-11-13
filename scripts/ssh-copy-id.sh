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


fun_copy_id() {

hduser_home=$(gosu hduser bash -c "eval echo ~hduser")
echo ${hduser_home}




comment="$(hostname)"
# -N new_passphrase
# -C comment


# gosu hduser bash -c "ssh-keygen -t rsa -b 4096 -N '' -m PEM -C ${comment} <<<$'\ny\n'"
# gosu hduser bash -c "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"
# gosu hduser bash -c "chmod 600 ~/.ssh/id_rsa"

gosu hduser bash -c "ssh-keygen -t ed25519 -N '' -C ${comment} <<<$'\ny\n'"
gosu hduser bash -c "chmod 600 ~/.ssh/id_ed25519"
gosu hduser bash -c "cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys"

gosu hduser bash -c "chmod 600 ~/.ssh/authorized_keys"

# https://askubuntu.com/questions/1409105/ubuntu-22-04-ssh-the-rsa-key-isnt-working-since-upgrading-from-20-04

for e in "${iparr[@]}" ;do
if [ "$e" = "$ip4" ]; then
    continue
else
(


while true; do
  sleep 2s && echo "wait for ${e} 22" && nc -nvz "${e}" 22 && break
done


while true; do

gosu hduser bash -c "ssh-keygen -R ${e} -f ~/.ssh/known_hosts";

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
}


fun_copy_id

