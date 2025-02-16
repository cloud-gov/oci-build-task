# syntax = docker/dockerfile:experimental
ARG base_image

FROM concourse/golang-builder AS builder
WORKDIR /src
COPY go.mod /src/go.mod
COPY go.sum /src/go.sum
RUN --mount=type=cache,target=/root/.cache/go-build go get -d ./...
COPY . /src
ENV CGO_ENABLED 0
RUN go build -o /assets/task ./cmd/task
RUN go build -o /assets/build ./cmd/build

FROM ${base_image} AS task
ARG BUILDKIT_VERSION=v0.16.0
RUN apt update && apt upgrade -y
RUN apt-get install -y --no-install-recommends \
    wget \
    runc
RUN wget https://github.com/moby/buildkit/releases/download/${BUILDKIT_VERSION}/buildkit-${BUILDKIT_VERSION}.linux-amd64.tar.gz
RUN tar xvf buildkit-${BUILDKIT_VERSION}.linux-amd64.tar.gz -C /usr
COPY --from=builder /assets/task /usr/bin/
COPY --from=builder /assets/build /usr/bin/
COPY bin/setup-cgroups /usr/bin/
ENTRYPOINT ["task"]

FROM task
