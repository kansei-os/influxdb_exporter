FROM golang:1-alpine AS build

ARG VERSION="0.11.2"
ARG CHECKSUM="fe94ad797f0833e21af2e188592b69cf9d2ed02708c52b57ab89b354444466d1"

ADD https://github.com/prometheus/influxdb_exporter/archive/v$VERSION.tar.gz /tmp/influxdb_exporter.tar.gz

RUN [ "$(sha256sum /tmp/influxdb_exporter.tar.gz | awk '{print $1}')" = "$CHECKSUM" ] && \
    apk add curl make && \
    tar -C /tmp -xf /tmp/influxdb_exporter.tar.gz && \
    mkdir -p /go/src/github.com/prometheus && \
    mv /tmp/influxdb_exporter-$VERSION /go/src/github.com/prometheus/influxdb_exporter && \
    cd /go/src/github.com/prometheus/influxdb_exporter && \
      make build

RUN mkdir -p /rootfs/bin && \
      cp /go/src/github.com/prometheus/influxdb_exporter/influxdb_exporter /rootfs/bin/ && \
    mkdir -p /rootfs/etc && \
      echo "nogroup:*:10000:nobody" > /rootfs/etc/group && \
      echo "nobody:*:10000:10000:::" > /rootfs/etc/passwd


FROM scratch

COPY --from=build --chown=10000:10000 /rootfs /

USER 10000:10000
EXPOSE 9122/tcp
ENTRYPOINT ["/bin/influxdb_exporter"]
