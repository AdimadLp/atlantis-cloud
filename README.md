# Atlantis Cloud - Personal Infrastructure

Self-hosted cloud setup using Docker Compose.

## Services

- **IoT Dashboard** - Monitor and control IoT devices
- **Notes (Affine)** - Personal note-taking
- **Obsidian LiveSync** - Sync Obsidian vault
- **Nextcloud** - File storage and sharing
- **PDF Signatures** - Sign documents
- **Photo Management (Immich)** - Photo backup and organization

### Network Architecture

- **Isolated Networks**: Each service group runs in its own Docker network for security
- **Service Networks**:
  - `iot_network`: IoT API + PostgreSQL
  - `notes_network`: Affine notes application
  - `obsidian_network`: CouchDB for Obsidian LiveSync
  - `drive_network`: Nextcloud + MariaDB
  - `immich_network`: Photo management + PostgreSQL + Redis
  - `pdf_network`: SignaturePDF service

## Setup

1. **Clone and configure**

   ```bash
   git clone https://github.com/AdimadLp/atlantis-cloud.git
   cd atlantis-cloud
   ```

2. **Create secrets (required)**

This repo uses Docker Compose `secrets:` for credentials (see `SECRETS.md`).

3. **Start a stack**

Each service group has its own compose file under `stacks/`:

```bash
docker compose -f stacks/<stack>/compose.yaml up -d
```
