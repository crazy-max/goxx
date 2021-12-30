# syntax=docker/dockerfile:1.3

ARG GOXX_BASE

FROM --platform=$BUILDPLATFORM $GOXX_BASE AS base
ENV GO111MODULE=auto
ENV CGO_ENABLED=1
WORKDIR /go/src/github.com/crazy-max/goxx/examples/c

FROM base AS build
ARG TARGETPLATFORM
RUN --mount=type=bind,source=. \
  --mount=type=cache,target=/root/.cache \
  goxx env && goxx build -o /out/c-xx .

FROM scratch AS artifact
COPY --from=build /out /

FROM scratch
COPY --from=build /out/c-xx /c-xx
ENTRYPOINT [ "/c-xx" ]
