[![GitHub release](https://img.shields.io/github/release/crazy-max/goxx.svg?style=flat-square)](https://github.com/crazy-max/goxx/releases/latest)
[![Build Status](https://img.shields.io/github/actions/workflow/status/crazy-max/goxx/build.yml?branch=main&label=build&logo=github&style=flat-square)](https://github.com/crazy-max/goxx/actions?query=workflow%3Abuild)
[![Test Status](https://img.shields.io/github/actions/workflow/status/crazy-max/goxx/test.yml?branch=main&label=test&logo=github&style=flat-square)](https://github.com/crazy-max/goxx/actions?query=workflow%3Atest)
[![Docker Stars](https://img.shields.io/docker/stars/crazymax/goxx?style=flat-square&logo=docker)](https://hub.docker.com/r/crazymax/goxx/)
[![Docker Pulls](https://img.shields.io/docker/pulls/crazymax/goxx?style=flat-square&logo=docker)](https://hub.docker.com/r/crazymax/goxx/)

[![Become a sponsor](https://img.shields.io/badge/sponsor-crazy--max-181717.svg?logo=github&style=flat-square)](https://github.com/sponsors/crazy-max)
[![Donate Paypal](https://img.shields.io/badge/donate-paypal-00457c.svg?logo=paypal&style=flat-square)](https://www.paypal.me/crazyws)

___

* [About](#about)
* [Projects using goxx](#projects-using-goxx)
* [Docker image](#docker-image)
* [Supported platforms](#supported-platforms)
* [Usage](#usage)
* [Build](#build)
* [Notes](#notes)
  * [MacOSX cross toolchain](#macosx-cross-toolchain)
  * [Wrappers](#wrappers)
  * [CGO](#cgo)
  * [Install cross-compilers for all platforms](#install-cross-compilers-for-all-platforms)
* [Contributing](#contributing)
* [License](#license)

## About

This repo contains a Dockerfile for building an image which can be used as a
base for building your Go project using CGO. All the necessary Go tool-chains,
C/C++ cross-compilers and platform headers/libraries can be installed with the
specially crafted [wrappers](#wrappers). This project is heavily inspired by
[`xx` project](https://github.com/tonistiigi/xx/).

## Projects using goxx

* [goreleaser-xx](https://github.com/crazy-max/goreleaser-xx)
* [xgo](https://github.com/crazy-max/xgo)

## Docker image

| Registry                                                                                        | Image                        |
|-------------------------------------------------------------------------------------------------|------------------------------|
| [Docker Hub](https://hub.docker.com/r/crazymax/goxx/)                                           | `crazymax/goxx`              |
| [GitHub Container Registry](https://github.com/users/crazy-max/packages/container/package/goxx) | `ghcr.io/crazy-max/goxx`     |

```
$ docker run --rm mplatform/mquery crazymax/goxx:latest
Image: crazymax/goxx:latest
 * Manifest List: Yes
 * Supported platforms:
   - linux/amd64
   - linux/arm64
```

## Supported platforms

| Platform             | `CC`                           | `CXX`                          |
|----------------------|--------------------------------|--------------------------------|
| `darwin/amd64`¹      | `o64-clang`                    | `o64-clang++`                  |
| `darwin/arm64`¹      | `o64-clang`                    | `o64-clang++`                  |
| `linux/386`          | `i686-linux-gnu-gcc`           | `i686-linux-gnu-g++`           |
| `linux/amd64`        | `x86_64-linux-gnu-gcc`         | `x86_64-linux-gnu-g++`         |
| `linux/arm64`        | `aarch64-linux-gnu-gcc`        | `aarch64-linux-gnu-g++`        |
| `linux/arm/v5`       | `arm-linux-gnueabi-gcc`        | `arm-linux-gnueabi-g++`        |
| `linux/arm/v6`       | `arm-linux-gnueabi-gcc`        | `arm-linux-gnueabi-g++`        |
| `linux/arm/v7`       | `arm-linux-gnueabihf-gcc`      | `arm-linux-gnueabihf-g++`      |
| `linux/mips`²        | `mips-linux-gnu-gcc`           | `mips-linux-gnu-g++`           |
| `linux/mipsle`²      | `mipsel-linux-gnu-gcc`         | `mipsel-linux-gnu-g++`         |
| `linux/mips64`²      | `mips64-linux-gnuabi64-gcc`    | `mips64-linux-gnuabi64-g++`    |
| `linux/mips64le`²    | `mips64el-linux-gnuabi64-gcc`  | `mips64el-linux-gnuabi64-g++`  |
| `linux/ppc64le`      | `powerpc64le-linux-gnu-gcc`    | `powerpc64le-linux-gnu-g++`    |
| `linux/riscv64`      | `riscv64-linux-gnu-gcc`        | `riscv64-linux-gnu-g++`        |
| `linux/s390x`        | `s390x-linux-gnu-gcc`          | `s390x-linux-gnu-g++`          |
| `windows/386`        | `i686-w64-mingw32-gcc`         | `i686-w64-mingw32-g++`         |
| `windows/amd64`      | `x86_64-w64-mingw32-gcc`       | `x86_64-w64-mingw32-g++`       |

> ¹ `darwin*` platform requires the [MacOSX cross toolchain](#macosx-cross-toolchain)
> if using CGO.
>
> ² compilers for `mips*` archs are not available with `linux/arm64` image.

## Usage

In order to use this image effectively, we will use the `docker buildx` command.
[Buildx](https://github.com/docker/buildx) is a Docker component that enables
many powerful build features. All builds executed via buildx run with
[Moby BuildKit](https://github.com/moby/buildkit) builder engine.

```dockerfile
# syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM crazymax/goxx:1.17 AS base
ENV GO111MODULE=auto
ENV CGO_ENABLED=1
WORKDIR /go/src/hello

FROM base AS build
ARG TARGETPLATFORM
RUN --mount=type=cache,sharing=private,target=/var/cache/apt \
  --mount=type=cache,sharing=private,target=/var/lib/apt/lists \
  goxx-apt-get install -y binutils gcc g++ pkg-config
RUN --mount=type=bind,source=. \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  goxx-go build -o /out/hello ./hello.go

FROM scratch AS artifact
COPY --from=build /out /

FROM scratch
COPY --from=build /out/hello /hello
ENTRYPOINT [ "/hello" ]
```

* `FROM --platform=$BUILDPLATFORM ...` command will pull an image that will
  always match the native platform of your machine (e.g., `linux/amd64`).
  `BUILDPLATFORM` is part of the [ARGs in the global scope](https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope).
* `ARG TARGETPLATFORM` is also an ARG in the global scope that will be set
  to the platform of the target that will default to your current platform or
  can be defined via the [`--platform` flag](https://docs.docker.com/engine/reference/commandline/buildx_build/#platform)
  of buildx so [`goxx-*` wrappers](#wrappers) will be able to automatically
  build against the right platform.

> More details about multi-platform builds in this [blog post](https://medium.com/@tonistiigi/faster-multi-platform-builds-dockerfile-cross-compilation-guide-part-1-ec087c719eaf).

Let's run a simple build against the `artifact` target in our Dockerfile:

```shell
# build and output content of the artifact stage that contains the binaries in ./dist
docker buildx build \
  --platform "linux/amd64,linux/arm64,linux/arm/v7,darwin/amd64" \
  --output "./dist" \
  --target "artifact" .

$ tree ./dist
./dist
├── darwin_amd64
│ ├── hello
├── linux_amd64
│ ├── hello
├── linux_arm64
│ ├── hello
├── linux_arm_v7
│ ├── hello
```

You can also create a multi-platform image in addition to the artifacts:

```shell
docker buildx build \
  --platform "linux/amd64,linux/arm64,linux/arm/v7" \
  --tag "hello:latest" \
  --push .
```

More examples can be found in the [`examples` folder](examples).

## Build

Build goxx yourself using Docker [`buildx bake`](https://github.com/docker/buildx/blob/master/docs/reference/buildx_bake.md):

```shell
git clone https://github.com/crazy-max/goxx.git goxx
cd goxx

# create docker container builder
docker buildx create --name goxx --use

# build goxx image and output to docker with goxx:local tag (default)
docker buildx bake image-local

# examples
(cd ./examples/c ; docker buildx bake artifact-all)
(cd ./examples/cpp ; docker buildx bake artifact-all)
(cd ./examples/echo ; docker buildx bake artifact-all)
(cd ./examples/gorm ; docker buildx bake artifact-all)
(cd ./examples/jq ; docker buildx bake artifact-all)
```

## Notes

### MacOSX cross toolchain

You can use the MacOSX cross toolchain provided by [`crazymax/osxcross`](https://github.com/crazy-max/docker-osxcross)
image to build against the `darwin` platform with CGO.

Using the `COPY` command:

```dockerfile
FROM --platform=$BUILDPLATFORM crazymax/osxcross:11.3 AS osxcross
FROM base AS build
COPY --from=osxcross /osxcross /osxcross
ARG TARGETPLATFORM
RUN --mount=type=bind,source=. \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  goxx-go build -o /out/hello ./hello.go
```

Or a `RUN` mount:

```dockerfile
FROM --platform=$BUILDPLATFORM crazymax/osxcross:11.3 AS osxcross
FROM base AS build
ARG TARGETPLATFORM
RUN --mount=type=bind,source=. \
  --mount=from=osxcross,target=/osxcross,src=/osxcross,rw \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  goxx-go build -o /out/hello ./hello.go
```

### Wrappers

Wrappers are a significant part of this repo to dynamically handle the build
process with a `go` wrapper named [`goxx-go`](rootfs/usr/local/bin/goxx-go) which
will automatically sets values for `GOOS`, `GOARCH`, `GOARM`, `GOMIPS`, etc. but
also `AR`, `CC`, `CXX` if building with CGO based on defined [ARGs in the global scope](https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope)
like `TARGETPLATFORM`.

It also manages debian packages for cross-compiling for non-native architectures with
[`goxx-apt-get`](rootfs/usr/local/bin/goxx-apt-get) and [`goxx-macports`](rootfs/usr/local/bin/goxx-macports)
to install MacPorts packages.

### CGO

By default, CGO is enabled in Go when compiling for native architecture and
disabled when cross-compiling. It's therefore recommended to always set
`CGO_ENABLED=0` or `CGO_ENABLED=1` when cross-compiling depending on whether
you need to use CGO or not.

### Install cross-compilers for all platforms

In some case you may want to install cross-compilers for all supported platforms
into a fat image:

```dockerfile
# syntax=docker/dockerfile:1-labs

ARG PLATFORMS="linux/386 linux/amd64 linux/arm64 linux/arm/v5 linux/arm/v6 linux/arm/v7 linux/mips linux/mipsle linux/mips64 linux/mips64le linux/ppc64le linux/riscv64 linux/s390x windows/386 windows/amd64"

FROM --platform=$BUILDPLATFORM crazymax/goxx:1.17 AS base
ARG PLATFORMS
RUN <<EOT
export GOXX_SKIP_APT_PORTS=1
goxx-apt-get update
for p in $PLATFORMS; do
  TARGETPLATFORM=$p goxx-apt-get install -y binutils gcc g++ pkg-config
done
EOT
```

> **Note**: This is not recommended for production use.

## Contributing

Want to contribute? Awesome! The most basic way to show your support is to star
the project, or to raise issues. You can also support this project by
[**becoming a sponsor on GitHub**](https://github.com/sponsors/crazy-max) or by
making a [Paypal donation](https://www.paypal.me/crazyws) to ensure this journey
continues indefinitely!

Thanks again for your support, it is much appreciated! :pray:

## License

MIT. See `LICENSE` for more details.
