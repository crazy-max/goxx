# syntax=docker/dockerfile:1

ARG GOXX_BASE

FROM --platform=$BUILDPLATFORM crazymax/osxcross:11.3 AS osxcross
FROM --platform=$BUILDPLATFORM $GOXX_BASE AS base
ENV GO111MODULE=auto
ENV CGO_ENABLED=1
WORKDIR /go/src/github.com/crazy-max/goxx/examples/cpp

FROM base AS build
ARG TARGETPLATFORM
RUN --mount=type=cache,sharing=private,target=/var/cache/apt \
  --mount=type=cache,sharing=private,target=/var/lib/apt/lists \
  goxx-apt-get install -y binutils gcc g++ pkg-config
RUN --mount=type=bind,source=. \
  --mount=from=osxcross,target=/osxcross,src=/osxcross,rw \
  --mount=type=cache,target=/root/.cache \
  goxx-go env && goxx-go build -v -o /out/cpp-xx .

FROM scratch AS artifact
COPY --from=build /out /

FROM scratch
COPY --from=build /out/cpp-xx /cpp-xx
ENTRYPOINT [ "/cpp-xx" ]
