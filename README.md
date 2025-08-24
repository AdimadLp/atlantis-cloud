# Atlantis Cloud - Personal Infrastructure

Self-hosted cloud setup using Docker Compose and Cloudflare Tunnel.

## Services

- **IoT Dashboard** - Monitor and control IoT devices
- **Notes (Affine)** - Personal note-taking
- **Obsidian LiveSync** - Sync Obsidian vault
- **Nextcloud** - File storage and sharing
- **PDF Signatures** - Sign documents
- **Photo Management (Immich)** - Photo backup and organization

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────────────────────────┐
│   Cloudflare    │    │            Docker Host               │
│     Tunnel      │    │                                      │
│                 │    │  ┌─────────────────────────────────┐ │
│ iot.atlantis-   ├────┼──┤         Cloudflared             │ │
│ cloud.com       │    │  │    (Single Instance)            │ │
│                 │    │  └─────────────────────────────────┘ │
│ notes.atlantis- │    │              │                       │
│ cloud.com       │    │              │                       │
│                 │    │  ┌───────────┴───────────────────┐   │
│ obsidian.       │    │  │        Network Bridge         │   │
│ atlantis-       │    │  └───┬───────────────────────────┘   │
│ cloud.com       │    │      │                               │
│                 │    │  ┌───┴───────────────────────────┐   │
│ drive.atlantis- │    │  │     Separated Networks        │   │
│ cloud.com       │    │  │                               │   │
│                 │    │  │ iot_network    notes_network  │   │
│ photos.atlantis-│    │  │     │              │          │   │
│ cloud.com       │    │  │ ┌───▼────┐    ┌───▼────┐      │   │
│                 │    │  │ │IoT API │    │Affine  │      │   │
│ pdf.atlantis-   │    │  │ │+ PostDB│    │Notes   │      │   │
│ cloud.com       │    │  │ └────────┘    └────────┘      │   │
└─────────────────┘    │  │                               │   │
                       │  │ obsidian_network drive_network│   │
                       │  │     │              │          │   │
                       │  │ ┌───▼────┐    ┌───▼────┐      │   │
                       │  │ │CouchDB │    │Nextcloud│     │   │
                       │  │ │LiveSync│    │+ MariaDB│     │   │
                       │  │ └────────┘    └────────┘      │   │
                       │  │                               │   │
                       │  │ immich_network  pdf_network   │   │
                       │  │     │              │          │   │
                       │  │ ┌───▼────┐    ┌───▼────┐      │   │
                       │  │ │Immich  │    │Signature│     │   │
                       │  │ │+ PostDB│    │PDF      │     │   │
                       │  │ │+ Redis │    └────────┘      │   │
                       │  │ └────────┘                    │   │
                       │  └───────────────────────────────┘   │
                       └──────────────────────────────────────┘
```

### Network Architecture

- **Single Cloudflared Instance**: One tunnel connects to all service networks for efficient resource usage
- **Isolated Networks**: Each service group runs in its own Docker network for security
- **Service Networks**:
  - `iot_network`: IoT API + PostgreSQL
  - `notes_network`: Affine notes application
  - `obsidian_network`: CouchDB for Obsidian LiveSync
  - `drive_network`: Nextcloud + MariaDB
  - `immich_network`: Photo management + PostgreSQL + Redis
  - `pdf_network`: SignaturePDF service
- **Secure Access**: All services accessible via HTTPS through Cloudflare Tunnel
- **No Direct Exposure**: Internal services not exposed to host ports

## Setup

1. **Clone and configure**

   ```bash
   git clone https://github.com/AdimadLp/atlantis-cloud.git
   cd atlantis-cloud
   cp .env.example .env
   # Edit .env with your settings
   ```

2. **Start everything**
   ```bash
   ./atlantis-cloud.sh start
   ```

## Usage

```bash
# Start all services
./atlantis-cloud.sh start

# Stop all services
./atlantis-cloud.sh stop

# Restart specific service
./atlantis-cloud.sh restart <service-name>

# View logs
./atlantis-cloud.sh logs <service-name>
```
