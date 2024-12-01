#!/usr/bin/env bash


SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd -P)


remove_flag=""
DETACHED=${DETACHED:-}
while [ $# -gt 0 ]; do
    case "$1" in
        --detached|-d)
            DETACHED=1
            ;;
         --remove|-r)
            remove_flag="1";
            ;;
         --rr|-rr)
            remove_flag="2"
            ;;
        --*)
            echo "Illegal option $1"
            ;;
    esac
    shift $(( $# > 0 ? 1 : 0 ))
done


is_detached() {
    if [ -z "$DETACHED" ]; then
        return 1
    else
        return 0
    fi
}



if [ "$remove_flag" = "1" ]; then
    echo "will remove all containers, docker-compose down"
    docker compose down
elif [ "$remove_flag" = "2" ]; then
    echo "will remove all containers and data, docker-compose down --volumes"
    docker compose down --volumes
else

  if is_detached; then
      docker compose up -d
  else
      docker compose up
  fi

fi




