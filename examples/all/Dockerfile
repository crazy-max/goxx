# syntax=docker/dockerfile:1-labs

ARG GOXX_BASE
ARG PLATFORMS="linux/386 linux/amd64 linux/arm64 linux/arm/v5 linux/arm/v6 linux/arm/v7 linux/mips linux/mipsle linux/mips64 linux/mips64le linux/ppc64le linux/riscv64 linux/s390x windows/386 windows/amd64"

FROM --platform=$BUILDPLATFORM $GOXX_BASE AS base
ARG PLATFORMS
RUN <<EOT
export GOXX_SKIP_APT_PORTS=1
goxx-apt-get update
for p in $PLATFORMS; do
  TARGETPLATFORM=$p goxx-apt-get install -y binutils gcc g++ pkg-config
done
EOT
