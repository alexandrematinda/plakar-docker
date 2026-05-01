FROM debian:12-slim
ARG VERSION
ARG TARGETARCH=amd64
ARG PLAKAR_UID=1000
ARG PLAKAR_GID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/* && \
    curl -fsSL "https://github.com/PlakarKorp/plakar/releases/download/v${VERSION}/plakar_${VERSION}_linux_${TARGETARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin plakar && \
    chmod +x /usr/local/bin/plakar && \
    groupadd -g ${PLAKAR_GID} plakar && \
    useradd -u ${PLAKAR_UID} -g plakar -d /home/plakar -m plakar

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chown plakar:plakar /home/plakar

USER plakar
WORKDIR /home/plakar
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
