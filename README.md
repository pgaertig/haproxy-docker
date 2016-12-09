# haproxy-docker
Freshly compiled HA-proxy 1.7.0 docker container

## Features:

 - HA-proxy v1.7.0 with OpenSSL 1.0.2 stable
 - logging provided with syslog redirection to stdio/console
 - graceful restart on configuration file change (on volume)

## Usage

To build the latest compilation as local docker image run `./utils/docker_build.sh` script.

