FROM ubuntu:wily

RUN apt-get update && apt-get install -y \
    autoconf automake autopoint bash bison bzip2 flex gettext\
    git g++ gperf intltool libffi-dev libgdk-pixbuf2.0-dev \
    libtool libltdl-dev libssl-dev libxml-parser-perl make \
    openssl p7zip-full patch perl pkg-config python ruby scons \
    sed unzip wget xz-utils g++-multilib libc6-dev-i386 libtool-bin

RUN git clone https://github.com/mxe/mxe.git

RUN cd mxe && make gcc -j32
