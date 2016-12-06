#!/bin/bash
docker run -it --rm -v /home/share/haproxy-data:/haproxy-data -p 8443:8443 --net=host haproxy:latest
