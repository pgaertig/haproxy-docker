# haproxy-docker
All-inclusive HAProxy 2.7 docker container with graceful reload, HTTP/3, Lua and more

[![Docker Pulls](https://badgen.net/docker/pulls/pgaertig/haproxy?icon=docker&label=pulls)](https://hub.docker.com/r/pgaertig/haproxy/tags)

## Features:

 - HAProxy v2.7.3
 - LibreSSL 3.6 (static)
 - SLZ - zlib/gzip-compatible fast stateless compression (static)
 - HTTP/3 & QUIC support enabled (experimental)
 - Lua 5.4 scripting
 - logging to stdout (built-in since 1.8)
 - graceful restart on configuration file change (on volume)

## General usage

Here is the pattern to run the image from the command line:

    docker run -v <path-to-dir-with-haproxy.cfg>:/haproxy-data \
               -p <hostPort>:<haproxy:port> -p <other-hostPort>:<other-haproxy:port> \
               -e CONFIG_FILE=haproxy.cfg \
               -e EXTRA_WATCH_FILES=/haproxy-data/certs \
               pgaertig/haproxy:latest

### Image version
For production deployment please consult GH tags or [Docker Hub tags](https://hub.docker.com/r/pgaertig/haproxy/tags) to pin to fixed version instead of `latest` which will change in the feature.

### Volumes
Although image doesn't define any volumes you should provide the configuration by mounting 
`/haproxy-data`. Alternatively you can extend the image within your own docker project and `ADD` command
 to staticaly embed config into `/haproxy-data`.

### Ports
The image and containers do not expose any port by default because these are up to your haproxy configuration. To expose a custom port use standard `docker` command line options (`-p`).

### Environment variables

- `CONFIG_FILE`, default: `haproxy.cfg` 

   This is main configuration file which is provided to haproxy executable as parameter.
   The file is monitored for any changes including timestamp change (e.g. by `touch`ing the file) and in case of
   a change the haproxy reloads the config.
     
- `EXTRA_WATCH_FILES`, default: empty

   You can provide additional list of files or directories which should be monitored for changes.
   The directories are watche recursively which means any change to nested files or subdirectories will trigger
   haproxy config reload. It is convenient to set this variable to `/haproxy-data` to notice any change to
   config and dependent files however make sure the changes won't trigger excessive 

- `DATA_USER_ID`, default: 1000
- `DATA_GROUP_ID`, default: 1000

   For your convenience the `haproxy` user and group is created with uid/gid defined by these variables.
   The container itself starts the `haproxy` server as `root` user however you can reduce the process privileges with these configuration settings:
        
        global
          user haproxy
          group haproxy
          
## Quick run demo

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

By the way in th above console output you can see the log entry printed by haproxy via stdout:

    log stdout format raw daemon debug

Refer to [haproxy configuration manual](https://docs.haproxy.org/2.7/configuration.html) for details.

## Forking and building your own

Please feel free to fork this repo and contribute PRs. You can build and run the docker image under your own GitHub handle:

    IMAGE_NAME=your_handle/haproxy:latest ./utils/docker_build.sh
    IMAGE_NAME=your_handle/haproxy:latest ./utils/docker_run_example.sh

## Latest build details

    Running on: Linux 5.17.1-051701-generic #202203280950 SMP PREEMPT Mon Mar 28 09:59:31 UTC 2022 x86_64
    Build options :
    TARGET  = linux-glibc
    CPU     = native
    CC      = cc
    CFLAGS  = -O2 -march=native -g -Wall -Wextra -Wundef -Wdeclaration-after-statement -Wfatal-errors -Wtype-limits -Wshift-negative-value -Wshift-overflow=2 -Wduplicated-cond -Wnull-dereference -fwrapv -Wno-address-of-packed-member -Wno-unused-label -Wno-sign-compare -Wno-unused-parameter -Wno-clobbered -Wno-missing-field-initializers -Wno-cast-function-type -Wno-string-plus-int -Wno-atomic-alignment -DLIBRESSL_HAS_QUIC
    OPTIONS = USE_PCRE=1 USE_PCRE_JIT=1 USE_THREAD=1 USE_STATIC_PCRE=1 USE_LINUX_TPROXY=1 USE_LINUX_SPLICE=1 USE_LIBCRYPT=1 USE_CRYPT_H=1 USE_GETADDRINFO=1 USE_OPENSSL=1 USE_LUA=1 USE_SLZ=1 USE_TFO=1 USE_NS=1 USE_QUIC=1
    DEBUG   = -DDEBUG_STRICT -DDEBUG_MEMORY_POOLS
    
    Feature list : -51DEGREES +ACCEPT4 +BACKTRACE -CLOSEFROM +CPU_AFFINITY +CRYPT_H -DEVICEATLAS +DL -ENGINE +EPOLL -EVPORTS +GETADDRINFO -KQUEUE +LIBCRYPT +LINUX_SPLICE +LINUX_TPROXY +LUA -MEMORY_PROFILING +NETFILTER +NS -OBSOLETE_LINKER +OPENSSL -OPENSSL_WOLFSSL -OT +PCRE -PCRE2 -PCRE2_JIT +PCRE_JIT +POLL +PRCTL -PROCCTL -PROMEX -PTHREAD_EMULATION +QUIC +RT +SHM_OPEN +SLZ +STATIC_PCRE -STATIC_PCRE2 -SYSTEMD +TFO +THREAD +THREAD_DUMP +TPROXY -WURFL -ZLIB
    
    Default settings :
    bufsize = 16384, maxrewrite = 1024, maxpollevents = 200
    
    Built with multi-threading support (MAX_TGROUPS=16, MAX_THREADS=256, default=16).
    Built with OpenSSL version : LibreSSL 3.6.2
    Running on OpenSSL version : LibreSSL 3.6.2
    OpenSSL library supports TLS extensions : yes
    OpenSSL library supports SNI : yes
    OpenSSL library supports : TLSv1.0 TLSv1.1 TLSv1.2 TLSv1.3
    Built with Lua version : Lua 5.4.2
    Built with network namespace support.
    Support for malloc_trim() is enabled.
    Built with libslz for stateless compression.
    Compression algorithms supported : identity("identity"), deflate("deflate"), raw-deflate("deflate"), gzip("gzip")
    Built with transparent proxy support using: IP_TRANSPARENT IPV6_TRANSPARENT IP_FREEBIND
    Built with PCRE version : 8.39 2016-06-14
    Running on PCRE version : 8.39 2016-06-14
    PCRE library supports JIT : yes
    Encrypted password support via crypt(3): yes
    Built with gcc compiler version 10.2.1 20210110
    
    Available polling systems :
    epoll : pref=300,  test result OK
    poll : pref=200,  test result OK
    select : pref=150,  test result OK
    Total: 3 (3 usable), will use epoll.
    
    Available multiplexer protocols :
    (protocols marked as <default> cannot be specified using 'proto' keyword)
    quic : mode=HTTP  side=FE     mux=QUIC  flags=HTX|NO_UPG|FRAMED
    h2 : mode=HTTP  side=FE|BE  mux=H2    flags=HTX|HOL_RISK|NO_UPG
    fcgi : mode=HTTP  side=BE     mux=FCGI  flags=HTX|HOL_RISK|NO_UPG
    <default> : mode=HTTP  side=FE|BE  mux=H1    flags=HTX
    h1 : mode=HTTP  side=FE|BE  mux=H1    flags=HTX|NO_UPG
    <default> : mode=TCP   side=FE|BE  mux=PASS  flags=
    none : mode=TCP   side=FE|BE  mux=PASS  flags=NO_UPG
    
    Available services : none
    
    Available filters :
    [BWLIM] bwlim-in
    [BWLIM] bwlim-out
    [CACHE] cache
    [COMP] compression
    [FCGI] fcgi-app
    [SPOE] spoe
    [TRACE] trace   
    
## Credits & licenses

Development of this project is sponsored by [KurierPlikow.pl](https://kurierplikow.pl).

This project and docker image is licensed under permisive MIT License, see `LICENSE` file for more details. The following packages used by this software:

- haproxy, <http://www.haproxy.org/>, GNU General Public License Version 2
- LibreSSL, <https://github.com/libressl/libressl/blob/master/src/LICENSE>
- syslog GO package, https://github.com/ziutek/syslog, Copyright (c) 2012, Michal Derkacz, three-clause BSD License: <https://github.com/ziutek/syslog/blob/master/LICENSE>

