#!/bin/bash
ABSDIR=$(dirname `readlink -f $0`)
docker run -it --rm -v $ABSDIR/example:/haproxy-data -p 8080:8080 pgaertig/haproxy:latest
