#
# build container
#
FROM --platform=linux/amd64 golang:1.19-alpine as builder
WORKDIR /

COPY postgres_exporter /postgres_exporter

EXPOSE     9187
ENTRYPOINT [ "/postgres_exporter" ]
