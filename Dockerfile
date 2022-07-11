FROM docker.io/golang:1.18.3 AS builder
COPY . src
RUN cd src && make bin


FROM docker.io/fedora:36
LABEL maintainer="Dalton Hubble <dghubble@gmail.com>"

ARG VERSION
ARG SHA

COPY scripts /scripts
RUN /scripts/build

COPY --from=builder /go/src/bin/gha /opt/
WORKDIR /actions-runner
ENTRYPOINT ["/scripts/start"]

# Skip Github's script which interferes with signal handling.
# CMD ["./run.sh"]
CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]
