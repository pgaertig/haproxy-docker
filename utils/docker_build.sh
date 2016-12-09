#!/bin/bash
DIR=`dirname "$0"`
docker build $DIR/.. -f $DIR/../Dockerfile -t haproxy:latest
