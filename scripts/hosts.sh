#!/usr/bin/env bash


sed -i '/^127\.0\.2\.1/d' /etc/hosts

for k in {0..2}; do
    for i in {0..9}; do
        ip="192.168.56.1${k}${i}"
        if ! grep "${ip}" /etc/hosts >/dev/null 2>&1 ; then
            echo "${ip} vm1${k}${i}" >> /etc/hosts
        fi
    done
done