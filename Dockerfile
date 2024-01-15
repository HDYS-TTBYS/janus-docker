# Base Image Amazon Linux2
FROM amazonlinux:2

# OS Update
RUN yum update -y

# Required library installation
RUN yum install -y jansson-devel \
    openssl-devel libsrtp-devel glib2-devel \
    opus-devel libogg-devel libcurl-devel pkgconfig \
    libconfig-devel libtool autoconf automake texi2html texinfo

# Install the command used for installation
RUN yum install -y wget vim git curl make procps-ng

# libmicrohttpd GNU libmicrohttpd は、HTTP サーバーを別のアプリケーションの一部として簡単に実行できるようにする小さな C ライブラリです。
RUN cd /opt/ && mkdir janus
RUN cd /opt/janus/ && git clone https://git.gnunet.org/libmicrohttpd.git && \
    cd libmicrohttpd && \
    mkdir build && \
    cd build && \
    ../bootstrap && \
    ../configure --prefix=/usr && \
    make && \
    make install

# libnice 対話型接続確立 (ICE) 用の RFC 5245 を実装する NAT トラバーサル ライブラリである
RUN yum -y install python3-pip
RUN amazon-linux-extras install python3.8 -y
RUN yum install -y python38-devel
RUN yes | pip3.8 install --upgrade pip 
RUN yes | pip install setuptools --upgrade
RUN yes | pip3 install meson
RUN yes | pip3 install ninja
RUN yum install -y gcc gcc-c++
RUN cd /opt/janus/ && wget https://github.com/Kitware/CMake/releases/download/v3.23.4/cmake-3.23.4.tar.gz && \
    tar xvf cmake-3.23.4.tar.gz && cd cmake-3.23.4 && mkdir build && cd build && ../configure --prefix=/opt/janus/cmake/3.23.4 && \
    make && make install
RUN PATH="/opt/janus/cmake-3.23.4/build/bin:$PATH"
RUN cd /opt/janus/ && \
    git clone https://gitlab.freedesktop.org/libnice/libnice && \
    cd ./libnice && \
    meson --prefix=/usr build && ninja -C build && ninja -C build install

# libsrtp このパッケージは、Secure Real-time Transport Protocol (SRTP)、Universal Security Transform (UST)、およびサポートする暗号化カーネルの実装を提供します。
RUN cd /opt/janus/ && \
    wget https://github.com/cisco/libsrtp/archive/v2.3.0.tar.gz && \
    tar xfv v2.3.0.tar.gz && \
    cd libsrtp-2.3.0 && \
    ./configure --prefix=/usr --enable-openssl --libdir=/usr/lib64 && \
    make shared_library && make install

# usrsctp SCTP は、IP または UDP 上で実行されるマルチホーミングを直接サポートするメッセージ指向の信頼性の高いトランスポート プロトコルで、v4 と v6 の両方のバージョンをサポートします。
RUN cd /opt/janus/&& \
    git clone https://github.com/sctplab/usrsctp && \
    cd ./usrsctp && \
    ./bootstrap && \
    ./configure --prefix=/usr --disable-programs --disable-inet --disable-inet6 --libdir=/usr/lib64 && \
    make && make install

# document
RUN yum install -y doxygen graphviz

# env
# 動的ライブラリ(libmicrohttpdなど)を参照できるようにする
RUN export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/local/lib/pkgconfig"
# 共有ライブラリへのpathを設定する
RUN export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

# Install the Janus server itself
RUN export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/local/lib/pkgconfig" && \
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib && \
    cd /opt/janus/ && \
    git clone https://github.com/meetecho/janus-gateway.git && \
    cd janus-gateway && \
    sh autogen.sh && \
    ./configure --prefix=/opt/janus --enable-rest --enable-docs && \
    make && \
    make install && \
    make configs

# Set up Janus Demo client
# node,npm
RUN amazon-linux-extras install -y epel
RUN yum install -y libuv --disableplugin=priorities
RUN yum install -y nodejs npm

# Simple WEB server (local-web-server) installation
RUN npm install -g local-web-server -y

# Set Janus launch shell
RUN cd /opt/janus/janus-gateway/ && \
    touch run_janus.sh && \
    echo "#!/bin/sh" >>run_janus.sh && \
    echo "/opt/janus/bin/janus &" >>run_janus.sh && \
    echo "cd /opt/janus/janus-gateway/html" >>run_janus.sh && \
    echo "ws" >>run_janus.sh && \
    chmod 755 run_janus.sh

# 設定ファイルをコピー
ADD etc/janus/* /opt/janus/etc/janus

# 証明書をコピー
ADD etc/ssl/cert/127.0.0.1_CRT.crt /etc/ssl/certs
ADD etc/ssl/private/127.0.0.1_CRT.pem /etc/ssl/private

EXPOSE 8000 8088 8089 7088

USER root

CMD ["/opt/janus/janus-gateway/run_janus.sh"]