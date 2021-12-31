[![GitHub release](https://img.shields.io/github/release/crazy-max/goxx.svg?style=flat-square)](https://github.com/crazy-max/goxx/releases/latest)
[![Build Status](https://img.shields.io/github/workflow/status/crazy-max/goxx/build?label=build&logo=github&style=flat-square)](https://github.com/crazy-max/goxx/actions?query=workflow%3Abuild)
[![Test Status](https://img.shields.io/github/workflow/status/crazy-max/goxx/test?label=test&logo=github&style=flat-square)](https://github.com/crazy-max/goxx/actions?query=workflow%3Atest)
[![Docker Stars](https://img.shields.io/docker/stars/crazymax/goxx.svg?style=flat-square&logo=docker)](https://hub.docker.com/r/crazymax/goxx/)
[![Docker Pulls](https://img.shields.io/docker/pulls/crazymax/goxx.svg?style=flat-square&logo=docker)](https://hub.docker.com/r/crazymax/goxx/)

[![Become a sponsor](https://img.shields.io/badge/sponsor-crazy--max-181717.svg?logo=github&style=flat-square)](https://github.com/sponsors/crazy-max)
[![Donate Paypal](https://img.shields.io/badge/donate-paypal-00457c.svg?logo=paypal&style=flat-square)](https://www.paypal.me/crazyws)

___

* [About](#about)
* [Projects using goxx](#projects-using-goxx)
* [Docker image](#docker-image)
* [Platforms available](#platforms-available)
* [Usage](#usage)
* [Build](#build)
* [Notes](#notes)
  * [Wrapper](#wrapper)
  * [CGO](#cgo)
  * [Override MacOSX cross toolchain](#override-macosx-cross-toolchain)
* [Contributing](#contributing)
* [Lisence](#license)

## About

This repo contains a Dockerfile for building an image which can be used as a
base for building your Go project using CGO. All the necessary Go tool-chains,
C/C++ cross-compilers and platform headers/libraries have been assembled into
a single Docker container. It also includes the MinGW compiler for windows,
and the MacOSX SDK.

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

## Platforms available

| Platform             | `CC`                           | `CXX`                          |
|----------------------|--------------------------------|--------------------------------|
| `darwin/amd64`       | `o64-clang`                    | `o64-clang++`                  |
| `darwin/arm64`       | `o64-clang`                    | `o64-clang++`                  |
| `linux/386`          | `i686-linux-gnu-gcc`           | `i686-linux-gnu-g++`           |
| `linux/amd64`        | `x86_64-linux-gnu-gcc`         | `x86_64-linux-gnu-g++`         |
| `linux/arm64`        | `aarch64-linux-gnu-gcc`        | `aarch64-linux-gnu-g++`        |
| `linux/arm/v5`       | `arm-linux-gnueabi-gcc`        | `arm-linux-gnueabi-g++`        |
| `linux/arm/v6`       | `arm-linux-gnueabi-gcc`        | `arm-linux-gnueabi-g++`        |
| `linux/arm/v7`       | `arm-linux-gnueabihf-gcc`      | `arm-linux-gnueabihf-g++`      |
| `linux/mips`         | `mips-linux-gnu-gcc`           | `mips-linux-gnu-g++`           |
| `linux/mipsle`       | `mipsel-linux-gnu-gcc`         | `mipsel-linux-gnu-g++`         |
| `linux/mips64`       | `mips64-linux-gnuabi64-gcc`    | `mips64-linux-gnuabi64-g++`    |
| `linux/mips64le`     | `mips64el-linux-gnuabi64-gcc`  | `mips64el-linux-gnuabi64-g++`  |
| `linux/ppc64le`      | `powerpc64le-linux-gnu-gcc`    | `powerpc64le-linux-gnu-g++`    |
| `linux/riscv64`      | `riscv64-linux-gnu-gcc`        | `riscv64-linux-gnu-g++`        |
| `linux/s390x`        | `s390x-linux-gnu-gcc`          | `s390x-linux-gnu-g++`          |
| `windows/386`        | `i686-w64-mingw32-gcc`         | `i686-w64-mingw32-g++`         |
| `windows/amd64`      | `x86_64-w64-mingw32-gcc`       | `x86_64-w64-mingw32-g++`       |

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
RUN --mount=type=bind,source=. \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  goxx build -o /out/hello ./hello.go

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
  of buildx so `goreleaser-xx` will be able to automatically build against
  the right platform.

> More details about multi-platform builds in this [blog post](https://medium.com/@tonistiigi/faster-multi-platform-builds-dockerfile-cross-compilation-guide-part-1-ec087c719eaf).

Let's run a simple build against the `artifact` target in our Dockerfile:

```shell
# build and output content of the artifact stage that contains the archive in ./dist
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

You can also create a multi-platform image in addition to the generated
artifacts:

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

# Create docker container builder
docker buildx create --name goxx --driver-opt network=host --use

# Create local registry to push the image
docker run -d --name registry -p 5000:5000 registry:2

# Build goxx image and push to local registry
docker buildx bake --set "*.tags=localhost:5000/goxx:latest" --push

# Examples
export GOXX_BASE=localhost:5000/goxx:latest
(cd ./examples/c ; docker buildx bake artifact-all)
(cd ./examples/cpp ; docker buildx bake artifact-all)
(cd ./examples/gorm ; docker buildx bake artifact-all)
```

## Notes

### Wrapper

[`goxx`](rootfs/usr/local/bin/goxx) is a simple wrapper for `go` which will
automatically sets values for `GOOS`, `GOARCH`, `GOARM`, `GOMIPS`, etc. but also
`AR`, `CC`, `CXX` if building with CGO based on defined [ARGs in the global scope](https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope)
like `TARGETPLATFORM`.

### CGO

By default, CGO is enabled in Go when compiling for native architecture and
disabled when cross-compiling. It's therefore recommended to always set
`CGO_ENABLED=0` or `CGO_ENABLED=1` when cross-compiling depending on whether
you need to use CGO or not.

### Override MacOSX cross toolchain

You can also use another version of the MacOSX cross toolchain provided by
[`crazymax/osxcross`](https://github.com/crazy-max/docker-osxcross) image:

```dockerfile
# syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM crazymax/osxcross:10.13 AS osxcross
FROM --platform=$BUILDPLATFORM crazymax/goxx:1.17 AS base
ENV GO111MODULE=auto
ENV CGO_ENABLED=1
WORKDIR /go/src/hello

FROM base AS build
ARG TARGETPLATFORM
RUN --mount=type=bind,source=. \
  --mount=from=osxcross,target=/osxcross,src=/osxcross,rw \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  goxx build -o /out/hello ./hello.go
```

## Contributing

Want to contribute? Awesome! The most basic way to show your support is to star
the project, or to raise issues. You can also support this project by
[**becoming a sponsor on GitHub**](https://github.com/sponsors/crazy-max) or by
making a [Paypal donation](https://www.paypal.me/crazyws) to ensure this journey
continues indefinitely!

Thanks again for your support, it is much appreciated! :pray:

## License

MIT. See `LICENSE` for more details.
