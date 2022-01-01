# syntax=docker/dockerfile:1.3

ARG GOXX_BASE

FROM --platform=$BUILDPLATFORM $GOXX_BASE AS base
ENV GO111MODULE=auto
ENV CGO_ENABLED=1
WORKDIR /src

FROM base AS build
ARG TARGETPLATFORM
RUN goxx-apt-get install -y binutils gcc g++ pkg-config libjq-dev libonig-dev
RUN goxx-macports install jq
ENV OSXCROSS_MP_INC=1
RUN --mount=type=bind,source=.,rw \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  goxx-go env && goxx-go build -o /out/jq-xx .

FROM scratch AS artifact
COPY --from=build /out /

FROM scratch
COPY --from=build /out/jq-xx /jq-xx
ENTRYPOINT [ "/jq-xx" ]
