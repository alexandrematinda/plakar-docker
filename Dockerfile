FROM alpine:3.23
ARG VERSION
ARG TARGETARCH=amd64

RUN apk add --no-cache ca-certificates && \
    wget -qO- "https://github.com/PlakarKorp/plakar/releases/download/v${VERSION}/plakar_${VERSION}_linux_${TARGETARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin plakar && \
    chmod +x /usr/local/bin/plakar && \
    addgroup -S plakar && adduser -S -G plakar -h /home/plakar plakar

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chown plakar:plakar /home/plakar

USER plakar
WORKDIR /home/plakar
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
