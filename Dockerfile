FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LIBRESSL_VERSION=3.6.2 \
    LIBSLZ_VERSION=v1.2.1 \
    HAPROXY_VERSION=v2.7.3

RUN apt-get update -yq && apt-get upgrade -yq && \
    apt-get install -yq --no-install-recommends dumb-init inotify-tools ca-certificates build-essential \
                                                git libpcre3-dev liblua5.4 liblua5.4-dev zlib1g-dev curl && \
    \
    LIBSLZ_PATH=/usr/src/libslz && \
      git clone --branch=${LIBSLZ_VERSION} http://git.1wt.eu/git/libslz.git ${LIBSLZ_PATH} && \
      cd $LIBSLZ_PATH && make static && \
      \
    LIBRESSL_PATH=/usr/src/libressl-${LIBRESSL_VERSION} && \
      curl http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz | tar xz -C /usr/src && \
      cd $LIBRESSL_PATH && ./configure --enable-shared=no CFLAGS=-DLIBRESSL_HAS_QUIC --prefix=${LIBRESSL_PATH}/build && make && make install && \
      \
    HAPROXY_PATH=/usr/src/haproxy && LIBRESSL_PATH=/usr/src/libressl-${LIBRESSL_VERSION} && LIBSLZ_PATH=/usr/src/libslz && \
      git clone --branch ${HAPROXY_VERSION} http://git.haproxy.org/git/haproxy-2.7.git/ ${HAPROXY_PATH} && \
      cd $HAPROXY_PATH && \
      make TARGET=linux-glibc CPU=native USE_PCRE=1 USE_PCRE_JIT=1 USE_LIBCRYPT=1 USE_CRYPT_H=1 USE_LINUX_SPLICE=1 USE_LINUX_TPROXY=1 \
         USE_GETADDRINFO=1 USE_STATIC_PCRE=1 USE_TFO=1 USE_NS=1 USE_THREAD=1 \
         USE_QUIC=1 DEFINE='-DLIBRESSL_HAS_QUIC' \
         USE_SLZ=1 SLZ_INC=${LIBSLZ_PATH}/src SLZ_LIB=${LIBSLZ_PATH} \
         USE_OPENSSL=1 SSL_INC=${LIBRESSL_PATH}/build/include SSL_LIB=${LIBRESSL_PATH}/build/lib ADDLIB="-ldl -lpthread" \
         USE_LUA=1 LUA_LIB=/usr/share/lua/5.4/ LUA_INC=/usr/include/lua5.4 && \
      mv ./haproxy / && mkdir /jail && \
    apt-get purge -yq --autoremove build-essential git libpcre3-dev liblua5.4-dev zlib1g-dev curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm -rf /usr/src/* /usr/share/doc /usr/share/doc-base /usr/share/man /usr/share/locale /usr/share/zoneinfo && \
    groupadd -g 1000 -o haproxy && \
    useradd --shell /usr/sbin/nologin -u 1000 -o -c "" -g 1000 haproxy --home /haproxy-data && \
    /haproxy -vv


ADD docker_entrypoint.sh /

CMD ["./docker_entrypoint.sh"]

