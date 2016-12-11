#!/bin/bash
DIR=`dirname "$0"`
docker build $DIR/.. -f $DIR/../Dockerfile -t pgaertig/haproxy:latest
