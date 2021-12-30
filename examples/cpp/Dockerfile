# syntax=docker/dockerfile:1.3

ARG GOXX_BASE

FROM --platform=$BUILDPLATFORM $GOXX_BASE AS base
ENV GO111MODULE=auto
ENV CGO_ENABLED=1
WORKDIR /go/src/github.com/crazy-max/goxx/examples/cpp

FROM base AS build
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
RUN --mount=type=bind,source=. \
  --mount=type=cache,target=/root/.cache \
  goxx env && goxx build -o /out/cpp-xx .

FROM scratch AS artifact
COPY --from=build /out /

FROM scratch
COPY --from=build /out/cpp-xx /cpp-xx
ENTRYPOINT [ "/cpp-xx" ]
