FROM debian:stretch-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LIBRESSL_VERSION=2.5.0 \
    LIBSLZ_VERSION=v1.1.0 \
    HAPROXY_VERSION=v1.7.9

ADD syslog-stdout/ /usr/src/syslog-stdout

RUN apt-get update -yq && apt-get upgrade -yq && \
    apt-get install -yq --no-install-recommends dumb-init inotify-tools ca-certificates build-essential \
                                                git libpcre3-dev golang liblua5.3 liblua5.3-dev zlib1g-dev curl && \
    LIBSLZ_PATH=/usr/src/libslz && \
      git clone --branch=${LIBSLZ_VERSION} http://git.1wt.eu/git/libslz.git ${LIBSLZ_PATH} && \
      cd $LIBSLZ_PATH && make static && \
    LIBRESSL_PATH=/usr/src/libressl-${LIBRESSL_VERSION} && \
      curl http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz | tar xz -C /usr/src && \
      cd $LIBRESSL_PATH && ./configure --enable-shared=no --prefix=${LIBRESSL_PATH}/build && make && make install && \
    HAPROXY_PATH=/usr/src/haproxy && LIBRESSL_PATH=/usr/src/libressl-${LIBRESSL_VERSION} && LIBSLZ_PATH=/usr/src/libslz && \
      git clone --branch ${HAPROXY_VERSION} http://git.haproxy.org/git/haproxy-1.7.git/ ${HAPROXY_PATH} && \
      cd $HAPROXY_PATH && \
      make TARGET=custom CPU=native USE_PCRE=1 USE_PCRE_JIT=1 USE_LIBCRYPT=1 USE_LINUX_SPLICE=1 USE_LINUX_TPROXY=1 \
         USE_GETADDRINFO=1 USE_STATIC_PCRE=1 USE_TFO=1 \
         USE_SLZ=1 SLZ_INC=${LIBSLZ_PATH}/src SLZ_LIB=${LIBSLZ_PATH} \
         USE_OPENSSL=1 SSL_INC=${LIBRESSL_PATH}/build/include SSL_LIB=${LIBRESSL_PATH}/build/lib ADDLIB=-ldl \
         USE_LUA=1 LUA_LIB=/usr/share/lua/5.3/ LUA_INC=/usr/include/lua5.3 && \
      mv ./haproxy / && mkdir /jail && \
    export GOPATH=/usr && cd / && \
    go get github.com/ziutek/syslog && \
    go build syslog-stdout && \
    apt-get purge -yq --autoremove build-essential git libpcre3-dev golang liblua5.3-dev zlib1g-dev curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm -rf /usr/src/* /usr/share/doc /usr/share/doc-base /usr/share/man /usr/share/locale /usr/share/zoneinfo && \
    groupadd -g 1000 -o haproxy && \
    useradd --shell /usr/sbin/nologin -u 1000 -o -c "" -g 1000 haproxy --home /haproxy-data && \
    /haproxy -vv


ADD docker_entrypoint.sh /

CMD ["./docker_entrypoint.sh"]

