# haproxy-docker
All-inclusive HAProxy 1.7.8 docker container with graceful reload, stdio logging, Lua and more

## Features:

 - HAProxy v1.7.8
 - LibreSSL 2.5.0 (static)
 - SLZ - zlib/gzip-compatible fast stateless compression (static)
 - Lua 5.3.3 scripting
 - logging provided with syslog redirection to stdio/console
 - graceful restart on configuration file change (on volume)

## General usage

Here is the pattern to run the image:

    docker run -v <path-to-dir-with-haproxy.cfg>:/haproxy-data \
               -p <hostPort>:<haproxy:port> -p <other-hostPort>:<other-haproxy:port> \
               -e CONFIG_FILE=haproxy.cfg \
               pgaertig/haproxy:latest

Please consult tags to pin to fixed version instead of `latest` which may change in the feature. The `/haproxy-data` is the only directory which should be mounted as volume. 
You should put `haproxy.cfg` there, which will be monitored of any changes including timestamp change caused by simply `touch`ing the file.

The image and containers do not expose any port by default because these are up to user's haproxy configuration. To expose a custom port use standard `docker` command line options (`-p`).

To alter the default configuration file name just pass the new name with `CONFIG_FILE` environment variable when running a container.
The container itself runs the `haproxy` server as `root` user however you can reduce the rights by `haproxy` configuration settings. For your convenience the `haproxy` user and group is created with uid/gid defined by DATA_USER_ID/DATA_GROUP_ID environment variables. By default `haproxy`'s uid/gid are 1000/1000.

## Example usage

The following script starts an example ephemeral container in the interactive mode:

    ./utils/docker_run_example.sh

You can see the proxied content of info.cern.ch at <http://127.0.0.1:8080/> and statistics are exposed at <http://127.0.0.1:8080/stats/haproxy>.

The proxy is initialized with configuration at `utils/example` directory which was attached as volume to containers `/haproxy-data` directory. Now you can check reload in action just by touching the config file:

    touch ./utils/example/haproxy.cfg

Above or any change to the file should initiate graceful HA-proxy reload sequence. The activity is reported on interactive console or container log:

    2016/12/09 17:28:17 <container> Config ./haproxy.cfg update event received, diff: 
    8c8
    <   stats refresh 10s
    ---
    >   stats refresh 5s
    2016/12/09 17:28:17 <container> Checking updated config
    Configuration file is valid
    2016/12/09 17:28:17 <container> Check OK, restarting haproxy
    2016/12/09 17:28:17 <local0,notice> Proxy fe_app started.
    2016/12/09 17:28:17 <local0,notice> Proxy be_app_stable started.
    2016/12/09 17:28:17 <local0,waining> Stopping frontend fe_app in 0 ms.
    2016/12/09 17:28:17 <local0,waining> Stopping backend be_app_stable in 0 ms.
    2016/12/09 17:28:17 <local0,waining> Proxy fe_app stopped (FE: 0 conns, BE: 0 conns).
    2016/12/09 17:28:17 <local0,waining> Proxy be_app_stable stopped (FE: 0 conns, BE: 0 conns).
    2016/12/09 17:28:17 <container> Successfuly restarted haproxy

In case of any error in the updated config the container stays safe with the old working configuration:

    2016/12/09 17:25:11 <container> Config ./haproxy.cfg update event received, diff: 
    2c2
    <   mode http
    ---
    >   mode garbage
    2016/12/09 17:25:11 <container> Checking updated config
    [ALERT] 343/172511 (34) : parsing [./haproxy.cfg:2] : unknown proxy mode 'garbage'.
    [ALERT] 343/172511 (34) : Error(s) found in configuration file : ./haproxy.cfg
    [ALERT] 343/172511 (34) : Parsing [./haproxy.cfg:17]: failed to parse log-format : format variable 'Tq' is reserved for HTTP mode.
    [WARNING] 343/172511 (34) : config : 'stats' statement ignored for frontend 'fe_app' as it requires HTTP mode.
    [WARNING] 343/172511 (34) : config : 'stats' statement ignored for backend 'be_app_stable' as it requires HTTP mode.
    [ALERT] 343/172511 (34) : Fatal errors found in configuration.
    2016/12/09 17:25:11 <container> Check failed, no restart performed, haproxy will continue to use the old working config. Please fix the new config file.
    2016/12/09 17:25:19 <local0,info> 10.0.2.33:36128 [09/Dec/2016:17:25:19.783] fe_app be_app_stable/upstream_server 0/0/14/15/29 304 137 - - ---- 1/1/0/1/0 0/0 {-,"",""} "GET / HTTP/1.1"

By the way in th above console output you can see the log entry printed by haproxy via `syslog-stdout` bridge. The bridge is started in parallel to haproxy  and to make use of it you can setup logging in haproxy config this way:

    log 127.0.0.1:1514 local0 debug

Refer to [haproxy configuration manual](www.haproxy.org/download/1.7/doc/configuration.txt) for details.
    
## Build

If you want to build the latest compilation as local docker image invoke the script:

    ./utils/docker_build.sh

It downloads sources of HAProxy and OpenSSL but also temporarly various Debian packages to compile them. The built image will be tagged as `pgaertig/haproxy:latest`.

## Credits & licenses

Development of this project is sponsored by [KurierPlikow.pl](https://kurierplikow.pl).

This project and docker image is licensed under permisive MIT License, see `LICENSE` file for more details. The following packages used by this software:

- haproxy, <http://www.haproxy.org/>, GNU General Public License Version 2
- LibreSSL, <https://github.com/libressl/libressl/blob/master/src/LICENSE>
- syslog GO package, https://github.com/ziutek/syslog, Copyright (c) 2012, Michal Derkacz, three-clause BSD License: <https://github.com/ziutek/syslog/blob/master/LICENSE>

