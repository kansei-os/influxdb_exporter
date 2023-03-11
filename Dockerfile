FROM golang:1-alpine AS build

ARG VERSION="0.11.3"
ARG CHECKSUM="8841d867c6ae24f3ca169e3134f2b2e88021e6632149199854678dc8772d4621"

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
