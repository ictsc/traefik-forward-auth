FROM --platform=$BUILDPLATFORM golang:1.24.3 AS builder

WORKDIR /src

RUN --mount=type=cache,target=/go/pkg/mod/,sharing=locked \
  --mount=type=bind,source=go.sum,target=go.sum \
  --mount=type=bind,source=go.mod,target=go.mod \
  go mod download -x

ARG TARGETOS
ARG TARGETARCH
ENV GOOS=$TARGETOS
ENV GOARCH=$TARGETARCH
ENV CGO_ENABLED=0

RUN --mount=type=cache,target=/go/pkg/mod/ \
  --mount=type=bind,source=.,target=. \
  go build -o /traefik-forward-auth -ldflags "-s -w" -trimpath ./cmd/main.go

FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder --chown=nonroot:nonroot /traefik-forward-auth /traefik-forward-auth

ENTRYPOINT ["/traefik-forward-auth"]
