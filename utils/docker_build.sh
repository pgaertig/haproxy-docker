#!/bin/bash
DIR=`dirname "$0"`
IMAGE_NAME="${IMAGE_NAME:-pgaertig/haproxy:latest}"
docker build $DIR/.. -f $DIR/../Dockerfile -t $IMAGE_NAME
