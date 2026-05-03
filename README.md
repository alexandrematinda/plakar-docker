# plakar-docker

Docker image for [Plakar](https://github.com/PlakarKorp/plakar) — a modern backup and restore tool with deduplication, encryption, and cloud storage support.

> Plakar is a content-addressable backup and restore tool. This image combines plakar for local backups with **rclone** for cloud synchronization to S3-compatible storage (AWS S3, Infomaniak, Backblaze B2, etc.).

## How It Works

This image uses a **two-step backup approach**:

1. **Plakar** — Creates encrypted, deduplicated snapshots in a local repository (`/home/plakar/.plakar`)
2. **rclone** — Syncs the backup data to S3-compatible cloud storage (Infomaniak, AWS, B2, etc.)

**Benefits:**
- ✅ Plakar backup works reliably (no S3 signature issues)
- ✅ rclone handles cloud sync securely
- ✅ Flexible — use any S3-compatible provider
- ✅ Fast incremental syncs (rclone only transfers new/changed packfiles)

**Workflow:**
```bash
# 1. Create local backup with plakar
docker run -e INIT=true ... plakar-docker backup /data

# 2. Sync to cloud with rclone
rclone sync /path/to/plakar/packfiles infomaniak:bucket-name/backups
```

---

## Quick Start

### 0. Setup directories on Synology

Before running backups, create the required directories:

```bash
# Docker configuration
mkdir -p /volume1/plakar-docker

# Plakar index storage (persistent, required for deduplication)
mkdir -p /volume1/plakar/kloset
chmod 755 /volume1/plakar/kloset
```

The `kloset` directory stores plakar's index — it should be kept on persistent storage so deduplication works across backup runs.

**Important**: Ensure the directory has correct permissions for the container's user (UID/GID from `.env`).

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

### 3. Initialize the repository and configure rclone

```bash
# Create local plakar repository with rclone config
docker-compose run --rm plakar-backup -e INIT=true
```

This will:
- ✓ Create the local plakar repository
- ✓ Configure rclone with your S3 credentials (in container)
- ✓ Print the rclone sync command to use

### 4. Run a backup

```bash
# Create a plakar snapshot from your data
docker-compose run --rm plakar-backup backup /data
```

### 5. Sync to cloud storage

After each backup, sync the plakar packfiles to S3:

```bash
# Option A: Run via docker
docker-compose run --rm plakar-sync

# Option B: Run rclone directly on your NAS
rclone sync /volume1/plakar/kloset/packfiles infomaniak:nas-db-backups/backups/packfiles
```

### 6. (Optional) Launch the UI

```bash
docker-compose up -d --profile ui plakar-ui
```

Then access `http://nas-ip:9000` in your browser to view backups and restore files.

---

## Features

- **Deduplication** — Only store unique blocks (Plakar)
- **Encryption** — AES-256 encrypted snapshots (Plakar)
- **Cloud Sync** — rclone syncs to any S3-compatible provider
- **Flexible** — Works with Infomaniak, AWS S3, Backblaze B2, MinIO, etc.
- **Efficient** — Incremental syncs, only transfers new packfiles
- **Reliable** — Plakar local backups work without cloud issues, rclone handles sync

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

### Plakar refuses to run (go away casper)

Plakar refuses to run as root. Solutions:

1. **Use correct UID/GID**: Ensure `.env` has `PLAKAR_UID` and `PLAKAR_GID` matching your NAS user (e.g., `1032:100`)
2. **Rebuild the image** with your UID/GID:
   ```bash
   cd /volume1/plakar-docker
   sudo docker build --build-arg VERSION=1.0.6 --build-arg PLAKAR_UID=1032 --build-arg PLAKAR_GID=100 -t plakar:local .
   ```
3. **Use docker run instead of docker-compose** if you need to test:
   ```bash
   sudo docker run --rm -v /volume1/plakar/kloset:/home/plakar/.plakar ghcr.io/alexandrematinda/plakar-docker:latest agent --help
   ```

### Check logs

```bash
docker-compose logs plakar-agent
docker-compose logs plakar-ui
```

### Verify S3 credentials

```bash
sudo docker run --rm -e S3_ACCESS_KEY_ID=xxx -e S3_SECRET_ACCESS_KEY=xxx ghcr.io/alexandrematinda/plakar-docker:latest help
```

---

## Building Locally

Build with your NAS user's UID/GID:

```bash
sudo docker build \
  --build-arg VERSION=1.0.6 \
  --build-arg PLAKAR_UID=1032 \
  --build-arg PLAKAR_GID=100 \
  -t plakar:local .

# Test
sudo docker run --rm -v /tmp/test:/home/plakar/.plakar plakar:local agent --help
```

**Note**: The `.buildargs` file in the repo sets default UID/GID for automated GitHub builds.

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
