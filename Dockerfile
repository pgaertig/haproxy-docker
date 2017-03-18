FROM debian:unstable

ENV DEBIAN_FRONTEND=noninteractive

ADD syslog-stdout/ /tmp/src/syslog-stdout

RUN apt-get update -yq && apt-get upgrade -yq && \
    apt-get install -yq --no-install-recommends inotify-tools ca-certificates build-essential git libpcre3-dev golang && \
    git clone http://git.haproxy.org/git/haproxy-1.7.git/ haproxy-build && \
    git clone --depth=1 --branch=OpenSSL_1_0_2-stable git://git.openssl.org/openssl.git openssl-build && \
    cd /openssl-build && \
    ./config no-shared && \
    make && \
    cd /haproxy-build && \
    git checkout v1.7.3 && \
    make TARGET=custom CPU=native USE_PCRE=1 USE_PCRE_JIT=1 USE_LIBCRYPT=1 USE_LINUX_SPLICE=1 USE_LINUX_TPROXY=1 \
         USE_OPENSSL=1 USE_GETADDRINFO=1 USE_STATIC_PCRE=1 SSL_INC=/openssl-build/include SSL_LIB=/openssl-build ADDLIB=-ldl && \
    mv ./haproxy / && cd / && \
    export GOPATH=/tmp && \
    go get github.com/ziutek/syslog && \
    go build syslog-stdout && \
    apt-get purge -yq --autoremove build-essential git libpcre3-dev golang && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm -rf /openssl-build /haproxy-build /usr/share/doc /usr/share/doc-base /usr/share/man /usr/share/locale /usr/share/zoneinfo && \
    /haproxy -vv

ADD docker_entrypoint.sh /


ENTRYPOINT ["./docker_entrypoint.sh"]

