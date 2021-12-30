# syntax=docker/dockerfile:1.3-labs

ARG UBUNTU_VERSION="21.04"
ARG OSX_SDK="MacOSX11.3.sdk"
ARG OSX_SDK_URL="https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/${OSX_SDK}.tar.xz"
ARG OSX_CROSS_COMMIT="d904031e7e3faa8a23c21b319a65cc915dac51b3"
#ARG LLVM_MINGW_URL="https://github.com/mstorsjo/llvm-mingw/releases/download/20210816/llvm-mingw-20210816-msvcrt-ubuntu-18.04-x86_64.tar.xz"

ARG GO_VERSION="1.17.5"

FROM ubuntu:${UBUNTU_VERSION} AS base
RUN export DEBIAN_FRONTEND="noninteractive" \
  && apt-get update \
  && apt-get install --no-install-recommends -y \
    autoconf \
    automake \
    autotools-dev \
    bash \
    bc \
    binutils-multiarch \
    binutils-multiarch-dev \
    build-essential \
    bzr \
    ca-certificates \
    clang \
    cmake \
    cpio \
    crossbuild-essential-amd64 \
    crossbuild-essential-arm64 \
    crossbuild-essential-armel \
    crossbuild-essential-armhf \
    crossbuild-essential-i386 \
    crossbuild-essential-mips \
    crossbuild-essential-mipsel \
    crossbuild-essential-mips64 \
    crossbuild-essential-mips64el \
    crossbuild-essential-ppc64el \
    crossbuild-essential-riscv64 \
    crossbuild-essential-s390x \
    curl \
    devscripts \
    g++ \
    g++-mingw-w64 \
    gcc \
    gcc-mingw-w64 \
    gdb \
    git \
    libgmp-dev \
    libmpc-dev \
    libmpfr-dev \
    libssl-dev \
    libtool \
    libxml2-dev \
    llvm-dev \
    lzma-dev \
    make \
    mercurial \
    musl-tools \
    multistrap \
    patch \
    pkg-config \
    swig \
    texinfo \
    tzdata \
    uuid-dev \
    xz-utils \
    zip \
    zlib1g-dev \
  && apt-get -y autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && ln -sf /usr/include/asm-generic /usr/include/asm

FROM base as osxcross
WORKDIR /osxcross
ARG OSX_CROSS_COMMIT
ARG OSX_SDK
ARG OSX_SDK_URL
RUN git clone https://github.com/tpoechtrager/osxcross.git . && git reset --hard $OSX_CROSS_COMMIT
COPY patches/lcxx.patch .
RUN patch -p1 < lcxx.patch \
  && curl -sSL "$OSX_SDK_URL" -o "./tarballs/$OSX_SDK.tar.xz" \
  && OSX_VERSION_MIN=10.10 UNATTENDED=1 ENABLE_COMPILER_RT_INSTALL=1 TARGET_DIR=/usr/local/osxcross ./build.sh

FROM base AS golang
RUN apt-get update && apt-get install --no-install-recommends -y jq
WORKDIR /golang
RUN curl -m30 --retry 5 --retry-connrefused --retry-delay 5 -sSL "https://go.dev/dl/?mode=json&include=all" -o "dist.json"
ARG GO_VERSION
ARG TARGETOS
ARG TARGETARCH
ARG GO_DIST_FILE="go${GO_VERSION}.${TARGETOS}-${TARGETARCH}.tar.gz"
ARG GO_DIST_URL="https://golang.org/dl/${GO_DIST_FILE}"
ENV GOPATH="/go"
ENV PATH="$GOPATH/bin:/usr/local/go/bin:$PATH"
RUN <<EOT
SHA256=$(cat dist.json | jq -r ".[] | select(.version==\"go$GO_VERSION\") | .files[] | select(.filename==\"$GO_DIST_FILE\").sha256")
curl -sSL "$GO_DIST_URL.asc" -o "go.tgz.asc"
curl -sSL "$GO_DIST_URL" -o "go.tgz"
echo "$SHA256 *go.tgz" | sha256sum -c -
tar -C /usr/local -xzf go.tgz
go version
EOT

FROM base
COPY --from=osxcross /usr/local/osxcross /usr/local/osxcross
COPY --from=golang /usr/local/go /usr/local/go

ENV GOROOT="/usr/local/go"
ENV GOPATH="/go"
ARG GO_VERSION
ENV GO_VERSION=${GO_VERSION}

ENV PATH="$GOPATH/bin:/usr/local/go/bin:/usr/local/osxcross/bin:$PATH"
ENV LD_LIBRARY_PATH="/usr/local/osxcross/lib:$LD_LIBRARY_PATH"
COPY rootfs /

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
RUN goxx-bootstrap
