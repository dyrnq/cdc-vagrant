#!/usr/bin/env bash
# shellcheck disable=SC2034
proxy="http://192.168.6.111:8118"
PREFIX="/opt/localrepo"
doris_ver="1.1.4"




INFO() {
    # https://github.com/koalaman/shellcheck/issues/1593
    # shellcheck disable=SC2039
    /bin/echo -e "\e[104m\e[97m[INFO]\e[49m\e[39m ${*}"
}

WARNING() {
    # shellcheck disable=SC2039
    /bin/echo >&2 -e "\e[101m\e[97m[WARNING]\e[49m\e[39m ${*}"
}

ERROR() {
    # shellcheck disable=SC2039
    /bin/echo >&2 -e "\e[101m\e[97m[ERROR]\e[49m\e[39m ${*}"
}