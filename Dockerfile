# syntax=docker/dockerfile:1

FROM golang:1.25-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /server ./main.go

FROM alpine:latest

COPY --from=builder /server /server

EXPOSE 8080

ENTRYPOINT ["/server"]

# Apple Silicon Macs build natively with: docker build -t usweb .
# Build and load a Linux amd64 image for local testing:
# docker buildx build --platform linux/amd64 --load -t usweb:amd64 .
# Run it under emulation; --rm deletes the container after it exits:
# docker run --rm --platform linux/amd64 -p 8080:8080 usweb:amd64
