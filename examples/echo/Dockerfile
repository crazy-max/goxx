# syntax=docker/dockerfile:1

ARG GOXX_BASE

FROM --platform=$BUILDPLATFORM $GOXX_BASE AS base
ENV GO111MODULE=auto
ENV CGO_ENABLED=0
WORKDIR /src

FROM base AS vendored
RUN --mount=type=bind,target=.,rw \
  --mount=type=cache,target=/go/pkg/mod \
  go mod tidy && go mod download

FROM vendored AS build
ARG TARGETPLATFORM
RUN --mount=type=bind,source=.,rw \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  goxx-go env && goxx-go build -v -o /out/echo-xx .

FROM scratch AS artifact
COPY --from=build /out /

FROM scratch
COPY --from=build /out/echo-xx /echo-xx
ENTRYPOINT [ "/gorm-xx" ]
