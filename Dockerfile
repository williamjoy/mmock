FROM golang:alpine

WORKDIR /build

COPY Makefile ./
COPY go.mod ./
COPY go.sum ./
COPY cmd ./cmd
COPY internal ./internal
COPY pkg ./pkg
COPY tmpl ./tmpl

RUN apk --no-cache add make gcc libc-dev
RUN make build

FROM alpine
RUN apk --no-cache add ca-certificates curl bash file

RUN mkdir /config
RUN mkdir /tls

VOLUME /config

COPY tls/server.crt /tls/server.crt
COPY tls/server.key /tls/server.key
COPY --from=0 /build/bin/mmock /usr/local/bin/mmock

EXPOSE 8082 8083 8084

ENTRYPOINT ["mmock","-config-path","/config","-tls-path","/tls"]
CMD ["-server-ip","0.0.0.0","-console-ip","0.0.0.0"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=3s --retries=2 CMD curl -f http://localhost:8082 || exit 1
