# syntax=docker/dockerfile:1-labs

ARG GOXX_BASE

FROM --platform=$BUILDPLATFORM crazymax/osxcross:11.3 AS osxcross
FROM --platform=$BUILDPLATFORM $GOXX_BASE AS base
ENV GO111MODULE=auto
ENV CGO_ENABLED=1
WORKDIR /src

FROM base AS vendored
RUN --mount=type=bind,target=.,rw \
  --mount=type=cache,target=/go/pkg/mod \
  go mod tidy && go mod download

FROM vendored AS build
ARG TARGETPLATFORM
RUN --mount=type=cache,sharing=private,target=/var/cache/apt \
  --mount=type=cache,sharing=private,target=/var/lib/apt/lists \
  goxx-apt-get install -y binutils gcc g++ pkg-config
RUN --mount=type=bind,source=.,rw \
  --mount=from=osxcross,target=/osxcross,src=/osxcross,rw \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod <<EOT
BUILDMODE=
if [ "$(. goxx-env && echo $GOOS)" != "windows" ]; then
  case "$(. goxx-env && echo $GOARCH)" in
    mips*|ppc64)
      # pie build mode is not supported on mips architectures
      ;;
    *)
      BUILDMODE="-buildmode=pie"
      ;;
  esac
fi
LDFLAGS="-s -w"
if [ "$(. goxx-env && echo $GOOS)" = "linux" ]; then
  LDFLAGS="$LDFLAGS -extldflags -static"
fi
goxx-go env
goxx-go build -v -o /out/gorm-xx -ldflags "$LDFLAGS" $BUILDMODE .
EOT

FROM scratch AS artifact
COPY --from=build /out /

FROM scratch
COPY --from=build /out/gorm-xx /gorm-xx
ENTRYPOINT [ "/gorm-xx" ]
