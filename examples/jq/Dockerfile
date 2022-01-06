# syntax=docker/dockerfile:1

ARG GOXX_BASE

FROM --platform=$BUILDPLATFORM crazymax/osxcross:11.3 AS osxcross
FROM --platform=$BUILDPLATFORM $GOXX_BASE AS base
COPY --from=osxcross /osxcross /osxcross
ENV GO111MODULE=auto
ENV CGO_ENABLED=1
WORKDIR /src

FROM base AS build
COPY --from=osxcross /osxcross /osxcross
ARG TARGETPLATFORM
RUN --mount=type=cache,sharing=private,target=/var/cache/apt \
  --mount=type=cache,sharing=private,target=/var/lib/apt/lists \
  goxx-apt-get install -y binutils gcc g++ pkg-config libjq-dev libonig-dev
RUN goxx-macports --static install jq
ENV OSXCROSS_MP_INC=1
RUN --mount=type=bind,source=.,rw \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  goxx-go env && goxx-go build -v -o /out/jq-xx .

FROM scratch AS artifact
COPY --from=build /out /

FROM scratch
COPY --from=build /out/jq-xx /jq-xx
ENTRYPOINT [ "/jq-xx" ]
