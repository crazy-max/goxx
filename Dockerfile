# syntax=docker/dockerfile:1.3-labs

ARG UBUNTU_VERSION="21.04"
ARG OSXCROSS_VERSION="11.3"
ARG GO_VERSION="1.17.5"

FROM --platform=$BUILDPLATFORM alpine AS godist
RUN apk --update --no-cache add ca-certificates curl
RUN curl -m30 --retry 5 --retry-connrefused --retry-delay 5 -sSL "https://go.dev/dl/?mode=json&include=all" -o "/godist.json"

FROM ubuntu:${UBUNTU_VERSION} AS base
RUN export DEBIAN_FRONTEND="noninteractive" \
  && apt-get update \
  && apt-get install --no-install-recommends -y \
    autoconf \
    automake \
    bash \
    bc \
    binutils-multiarch \
    build-essential \
    bzr \
    ca-certificates \
    clang \
    cmake \
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
    gcc \
    g++-mingw-w64 \
    gcc-mingw-w64 \
    gdb \
    git \
    libssl-dev \
    libtool \
    llvm \
    lzma \
    make \
    mercurial \
    multistrap \
    pkg-config \
    swig \
    texinfo \
    tzdata \
    uuid \
    zip \
  && apt-get -y autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && ln -sf /usr/include/asm-generic /usr/include/asm

FROM base AS golang
RUN apt-get update && apt-get install --no-install-recommends -y jq
WORKDIR /golang
COPY --from=godist /godist.json .
ARG GO_VERSION
ARG TARGETOS
ARG TARGETARCH
ENV GOPATH="/go"
ENV PATH="$GOPATH/bin:/usr/local/go/bin:$PATH"
RUN <<EOT
GO_DIST_FILE=go${GO_VERSION%.0}.${TARGETOS}-${TARGETARCH}.tar.gz
GO_DIST_URL=https://golang.org/dl/${GO_DIST_FILE}
SHA256=$(cat godist.json | jq -r ".[] | select(.version==\"go${GO_VERSION%.0}\") | .files[] | select(.filename==\"$GO_DIST_FILE\").sha256")
curl -sSL "$GO_DIST_URL.asc" -o "go.tgz.asc"
curl -sSL "$GO_DIST_URL" -o "go.tgz"
echo "$SHA256 *go.tgz" | sha256sum -c -
tar -C /usr/local -xzf go.tgz
go version
EOT

FROM crazymax/osxcross:${OSXCROSS_VERSION} AS osxcross
FROM base
COPY --from=osxcross /osxcross /osxcross
COPY --from=golang /usr/local/go /usr/local/go

ENV GOROOT="/usr/local/go"
ENV GOPATH="/go"
ARG GO_VERSION
ENV GO_VERSION=${GO_VERSION}

ENV PATH="$GOPATH/bin:/usr/local/go/bin:/osxcross/bin:$PATH"
ENV LD_LIBRARY_PATH="/osxcross/lib:$LD_LIBRARY_PATH"
COPY rootfs /
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
