FROM golang:1-alpine AS build

ARG VERSION="0.9.1"
ARG CHECKSUM="a89443224f130dea93fa31e2baa32348f1e229eda980a9e557643654c0c8a518"

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
