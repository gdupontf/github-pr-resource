ARG GOOS=linux
ARG GOARCH=amd64

FROM alpine:3.11 as resource-tools
RUN apk add --update --no-cache \
    curl \
    jq \
    git \
    git-lfs \
    openssh
COPY scripts/askpass.sh /usr/local/bin/askpass.sh
ADD scripts/install_git_crypt.sh install_git_crypt.sh
RUN ./install_git_crypt.sh && rm ./install_git_crypt.sh
RUN rm -rf scripts

FROM golang:1.21 as builder
WORKDIR /go/src/github.com/telia-oss/github-pr-resource
ENV GOOS=$GOOS
ENV GOARCH=$GOARCH
RUN curl -sL https://taskfile.dev/install.sh | sh
# https://blog.stackademic.com/20x-faster-golang-docker-builds-f7665f4f43d7
COPY go.mod .
COPY go.sum .
RUN go mod download
ADD . .
ENV GOCACHE=/root/.cache/go-build
RUN --mount=type=cache,target="/root/.cache/go-build" ./bin/task build

FROM resource-tools as resource
COPY --from=builder /go/src/github.com/telia-oss/github-pr-resource/build /opt/resource
RUN chmod +x /opt/resource/*

FROM resource