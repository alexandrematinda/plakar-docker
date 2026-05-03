FROM debian:12-slim

ARG VERSION=1.0.6
ARG TARGETARCH=amd64

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    rclone \
    cron && \
    curl -fsSL "https://github.com/PlakarKorp/plakar/releases/download/v${VERSION}/plakar_${VERSION}_linux_${TARGETARCH}.tar.gz" | \
    tar -xz -C /usr/local/bin plakar && \
    chmod +x /usr/local/bin/plakar && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY scheduler.yaml /home/plakar/scheduler.yaml
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /home/plakar
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
