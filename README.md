# plakar-docker

Docker image for [Plakar](https://github.com/PlakarKorp/plakar) — a modern backup and restore tool with deduplication, encryption, and S3/B2 support.

> Plakar is a content-addressable backup and restore tool that works with local filesystems, S3-compatible stores (Backblaze B2, AWS S3, etc.), SFTP, and more.

## Quick Start

### 0. Setup directories on Synology

Before running backups, create the required directories:

```bash
# Docker configuration
mkdir -p /volume1/plakar-docker

# Plakar index storage (persistent, required for deduplication)
mkdir -p /volume1/plakar/kloset
```

The `kloset` directory stores plakar's index — it should be kept on persistent storage so deduplication works across backup runs.

### 1. Clone or setup the repo

```bash
cd /volume1/plakar-docker
git clone https://github.com/alexandrematinda/plakar-docker .
cp .env.example .env
```

### 2. Configure `.env`

Edit `.env` with your S3 credentials. Examples:

**Infomaniak S3:**
```dotenv
S3_ACCESS_KEY_ID=your_access_key
S3_SECRET_ACCESS_KEY=your_secret_key
S3_BUCKET=your-bucket-name
S3_ENDPOINT=https://s3.pub1.infomaniak.cloud
PLAKAR_PASSPHRASE=your_strong_passphrase
BACKUP_SOURCE=/volume1/data
```

**Backblaze B2:**
```dotenv
S3_ACCESS_KEY_ID=your_b2_key_id
S3_SECRET_ACCESS_KEY=your_b2_secret_key
S3_BUCKET=your-bucket-name
S3_ENDPOINT=https://s3.us-west-004.backblazeb2.com
PLAKAR_PASSPHRASE=your_strong_passphrase
BACKUP_SOURCE=/volume1/data
```

**Any S3-compatible storage** (AWS S3, MinIO, etc.) — adjust `S3_ENDPOINT` and `S3_REGION` accordingly.

### 3. Start the backup agent

```bash
# Start the agent (runs scheduled backups automatically)
docker-compose up -d --profile agent plakar-agent

# Configure backup schedules via plakar's agent configuration
# (See plakar documentation for scheduling)
```

### 4. Launch the UI

```bash
docker-compose up -d --profile ui plakar-ui
```

Then access `http://nas-ip:9000` in your browser to view backups and restore files.

---

## Features

- **Deduplication** — Only store unique blocks
- **Encryption** — AES-256 encrypted snapshots
- **S3/B2 Compatible** — Works with Backblaze B2, AWS S3, MinIO, etc.
- **Statically Compiled** — No dependencies, pure binary
- **Alpine-based** — ~15 MB image size

---

## Image Versions

Images are automatically built for every new Plakar stable release.

```
ghcr.io/orangees/plakar-docker:latest          # Latest stable (v1.0.6)
ghcr.io/orangees/plakar-docker:v1.0.6          # Specific version
```

---

## Supported Architectures

- `linux/amd64` (Synology DS-716, DS-716+)
- `linux/arm64` (ARM-based Synology, Raspberry Pi)

---

## Directory Structure

```
/volume1/
├── plakar-docker/          # Git repo (config, Dockerfile, docker-compose.yml)
│   ├── .env                # Your S3 credentials (git-ignored)
│   └── docker-compose.yml
└── plakar/
    └── kloset/             # Plakar index (persistent, CRITICAL for deduplication)
```

**Important**: The `kloset` directory must be on persistent storage (`/volume1`), not ephemeral. Plakar uses it to:
- Store content hashes and deduplication metadata
- Avoid re-uploading unchanged blocks to S3
- Enable efficient incremental backups

If you delete it, subsequent backups will be much slower and re-upload all data.

---

## docker-compose.yml

Two services are available:

### `plakar-agent`

Plakar's built-in scheduler/agent. Runs continuously and executes scheduled backup tasks.

```bash
# Start the agent in the background
docker-compose up -d --profile agent plakar-agent

# Configure scheduled backups via the agent (documented in plakar-agent(1))
docker-compose exec plakar-agent plakar agent --help
```

The agent:
- Reads backup schedules from plakar's configuration
- Handles recurring backups without needing DSM Task Scheduler
- Stores snapshots in the shared kloset

### `plakar-ui`

Web UI for managing backups and restores. Only started with `--profile ui`.

```bash
docker-compose up -d --profile ui plakar-ui
```

Access at `http://nas-ip:9000`

---

## Troubleshooting

### Check logs

```bash
docker-compose logs plakar-backup
```

### Verify B2 credentials

```bash
docker-compose run --rm plakar-backup bucket-list
```

### Manual backup command

```bash
docker-compose run --rm plakar-backup backup --store "s3://KEY:SECRET@ENDPOINT/BUCKET" /data
```

---

## Building Locally

```bash
docker build --build-arg VERSION=1.0.6 -t plakar:local .
docker run --rm plakar:local version
```

---

## License

Plakar is licensed under ISC. This Docker packaging is provided as-is.

---

## S3 Providers

Plakar works with any S3-compatible storage:

- **Infomaniak** — `https://s3.pub1.infomaniak.cloud` (Switzerland-based, GDPR-friendly)
- **Backblaze B2** — `https://s3.us-west-004.backblazeb2.com` (US-based)
- **AWS S3** — `https://s3.region.amazonaws.com`
- **MinIO** — Self-hosted S3-compatible storage
- **Others** — Any S3-compatible endpoint

See `.env.example` for configuration examples.

## Related

- [Plakar GitHub](https://github.com/PlakarKorp/plakar)
- [Plakar Docs](https://plakar.io)
- [Infomaniak S3 Docs](https://www.infomaniak.com/en/hosting/object-storage)
- [Backblaze B2 Pricing](https://www.backblaze.com/b2/cloud-storage-pricing.html)
