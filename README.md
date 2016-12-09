# haproxy-docker
Freshly compiled HA-proxy 1.7.0 docker container with simple graceful reload and proper logging

## Features:

 - HA-proxy v1.7.0 with OpenSSL 1.0.2 stable
 - logging provided with syslog redirection to stdio/console
 - graceful restart on configuration file change (on volume)

## Usage

To build the latest compilation as local docker image invoke the script
  
    ./utils/docker_build.sh

It downloads HA-proxy, OpenSSL and temporarly various Debian packages to compile them. Once image is ready the following script starts an example
ephemeral container in the interactive mode:

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

Refer to (haproxy configuration manual)[www.haproxy.org/download/1.7/doc/configuration.txt] for details.
    
