#!/usr/bin/env bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd -P)

iface="${iface:-enp0s8}"
cluster_ips="192.168.55.31,192.168.55.32,192.168.55.33"
port="${port:-8000}"


while [ $# -gt 0 ]; do
    case "$1" in
        --iface|-i)
            iface="$2"
            shift
            ;;
        --cluster-ips|--ips|--sites)
            cluster_ips="$2"
            shift
            ;;
        --port)
            port="$2"
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
    curl -fSL -o /usr/local/bin/sidekick -# https://github.com/minio/sidekick/releases/download/v2.0.4/sidekick-linux-amd64
    chmod +x /usr/local/bin/sidekick

    mkdir -p /etc/default
    cat >/etc/default/sidekick<<EOF
# Sidekick options
SIDEKICK_OPTIONS="--health-path=/minio/health/ready --address :${port}"

# Sidekick sites
SIDEKICK_SITES="${cluster_ips}"
EOF

    cat >/lib/systemd/system/sidekick.service<<EOF
# https://github.com/minio/sidekick/blob/master/systemd-service/sidekick.service
[Unit]
Description=Sidekick
Documentation=https://github.com/minio/sidekick/blob/master/README.md
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/usr/local/bin/sidekick

[Service]
User=nobody
Group=nogroup

EnvironmentFile=/etc/default/sidekick

ExecStart=/usr/local/bin/sidekick \$SIDEKICK_OPTIONS \$SIDEKICK_SITES

# Let systemd restart this service always
Restart=always

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536

# Disable timeout logic and wait until process is stopped
TimeoutStopSec=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF


    systemctl daemon-reload
    if systemctl is-active sidekick &>/dev/null; then
        systemctl restart sidekick
    else
        systemctl enable --now sidekick
    fi
    systemctl status -l sidekick --no-pager
}


fun_install