# plakar-docker

Docker image for [Plakar](https://github.com/PlakarKorp/plakar) — a modern backup and restore tool with deduplication, encryption, and S3/B2 support.

> Plakar is a content-addressable backup and restore tool that works with local filesystems, S3-compatible stores (Backblaze B2, AWS S3, etc.), SFTP, and more.

## Quick Start

### 1. Clone or setup the repo

```bash
cd /volume1/plakar-docker
git clone https://github.com/orangees/plakar-docker .
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

### 3. Run a backup

```bash
cd /volume1/plakar-docker
docker-compose run --rm plakar-backup
```

Or schedule via Synology **Control Panel > Task Scheduler > Create > Scheduled Task > Custom**:

```bash
cd /volume1/plakar-docker && docker-compose run --rm plakar-backup
```

### 4. (Optional) Launch the UI

```bash
docker-compose up -d --profile ui plakar-ui
```

Then access `http://nas-ip:9000` in your browser.

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

## docker-compose.yml

Two services are available:

### `plakar-backup`

One-shot backup service. Triggered manually or via scheduled task.

```bash
docker-compose run --rm plakar-backup
```

Options in `.env`:
- `BACKUP_SOURCE` — Path to back up (e.g., `/volume1/data`)
- `B2_*` — S3/B2 credentials and bucket
- `PLAKAR_PASSPHRASE` — Encryption passphrase

### `plakar-ui` (Optional)

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
