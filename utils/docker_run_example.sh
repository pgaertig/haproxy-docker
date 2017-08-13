#!/bin/bash
ABSDIR=$(dirname `readlink -f $0`)
docker run -it --rm -v $ABSDIR/example:/haproxy-data \
           -p 8080:8080 \
           -e DATA_USER_ID=$(id --user) \
           -e DATA_GROUP_ID=$(id --group) \
           -e EXTRA_WATCH_FILES=/haproxy-data \
           pgaertig/haproxy:latest
