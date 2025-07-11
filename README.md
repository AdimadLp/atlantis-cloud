# Atlantis Cloud Infrastructure

A modular cloud infrastructure setup using Docker Compose with separated services and networks, accessible via Cloudflare Tunnel.

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────────────────────────┐
│   Cloudflare    │    │            Docker Host               │
│     Tunnel      │    │                                      │
│                 │    │  ┌─────────────────────────────────┐ │
│ iot.atlantis-   ├────┼──┤         Cloudflared             │ │
│ cloud.com       │    │  │    (Single Instance)            │ │
│                 │    │  └─────────────────────────────────┘ │
│ notes.atlantis- │    │              │                      │
│ cloud.com       │    │              │                      │
│                 │    │  ┌───────────┴───────────────────┐   │
│ obsidian.       │    │  │        Network Bridge        │   │
│ atlantis-       │    │  └───────────┬───────────────────┘   │
│ cloud.com       │    │              │                      │
│                 │    │  ┌───────────┴───────────────────┐   │
│ drive.atlantis- │    │  │     Separated Networks       │   │
│ cloud.com       │    │  │                               │   │
└─────────────────┘    │  │ iot_network    notes_network  │   │
                       │  │     │              │          │   │
                       │  │ ┌───▼────┐    ┌───▼────┐     │   │
                       │  │ │IoT Svc │    │Notes   │     │   │
                       │  │ │        │    │Services│     │   │
                       │  │ └────────┘    └────────┘     │   │
                       │  │                               │   │
                       │  │ obsidian_network drive_network│   │
                       │  │     │              │          │   │
                       │  │ ┌───▼────┐    ┌───▼────┐     │   │
                       │  │ │Obsidian│    │NextCloud│    │   │
                       │  │ │LiveSync│    │ + DB    │    │   │
                       │  │ └────────┘    └────────┘     │   │
                       │  └───────────────────────────────┘   │
                       └──────────────────────────────────────┘
```

## Service Organization

### 🌐 **Single Cloudflared Instance**

- **File**: `docker-compose.cloudflared.yaml`
- **Purpose**: Single tunnel instance that connects to all service networks
- **Benefits**:
  - Resource efficient
  - Centralized configuration
  - Simplified certificate management
  - Single point of ingress control

### 🏭 **Separated Service Networks**

#### 1. **IoT Network** (`iot_network`)

- **File**: `iot/irrigation/docker-compose.yaml`
- **Services**: API, Database (PostgreSQL), Dashboard
- **Domain**: `iot.atlantis-cloud.com`
- **Isolation**: Complete network isolation from other services

#### 2. **Notes Network** (`notes_network`)

- **File**: `notes/docker-compose.yaml`
- **Services**: Affine (Community Edition)
- **Domain**: `notes.atlantis-cloud.com`
- **Isolation**: Separate from other note-taking services

#### 3. **Obsidian Network** (`obsidian_network`)

- **File**: `notes/obsidian/docker-compose.yaml`
- **Services**: CouchDB for Obsidian LiveSync
- **Domain**: `obsidian.atlantis-cloud.com`
- **Isolation**: Dedicated network for Obsidian sync

#### 4. **Drive Network** (`drive_network`)

- **File**: `drive/docker-compose.yaml`
- **Services**: Nextcloud + MariaDB
- **Domain**: `drive.atlantis-cloud.com`
- **Isolation**: Secure file storage environment

## Benefits of This Architecture

### ✅ **Security & Isolation**

- Each service runs in its own network
- No cross-service communication unless explicitly configured
- Database isolation prevents data leaks
- Reduced attack surface

### ✅ **Scalability**

- Services can be scaled independently
- Easy to add new services without affecting existing ones
- Resource allocation per service group

### ✅ **Maintainability**

- Clear separation of concerns
- Easy troubleshooting and debugging
- Independent service updates
- Modular configuration

### ✅ **Performance**

- Single cloudflared instance reduces overhead
- Network isolation improves performance
- Dedicated resources per service group

## Quick Start

### 1. **Environment Setup**

```bash
# Copy environment template (create this file)
cp .env.example .env

# Edit with your values
nano .env
```

### 2. **Start All Services**

```bash
# Start everything
./atlantis.sh start

# Check status
./atlantis.sh status
```

### 3. **Individual Service Management**

```bash
# Start specific service
./atlantis.sh restart obsidian

# View logs
./atlantis.sh logs iot

# Stop everything
./atlantis.sh stop
```

## Service Access

Once running, your services will be available at:

- **IoT Dashboard**: `https://iot.atlantis-cloud.com/dashboard`
- **IoT API**: `https://iot.atlantis-cloud.com/api`
- **Notes (Affine)**: `https://notes.atlantis-cloud.com`
- **Obsidian LiveSync**: `https://obsidian.atlantis-cloud.com`
- **Drive (Nextcloud)**: `https://drive.atlantis-cloud.com`

## Configuration Files

### Required Environment Variables

Create a `.env` file in the root directory with:

```bash
# Cloudflare Tunnel
CLOUDFLARE_TUNNEL_TOKEN=your_tunnel_token
CLOUDFLARED_VERSION=latest

# IoT Services
IOT_API_IMAGE_NAME=your_iot_api
IOT_API_IMAGE_TAG=latest
DASHBOARD_IMAGE_NAME=your_dashboard
DASHBOARD_IMAGE_TAG=latest
POSTGRES_USER=iot_user
POSTGRES_PASSWORD=secure_password
POSTGRES_DB=iot_database
POSTGRES_VERSION=15

# Notes Services
AFFINE_IMAGE_TAG=stable

# Obsidian LiveSync
COUCHDB_USER=admin
COUCHDB_PASSWORD=secure_password
COUCHDB_DATA_PATH=./notes/obsidian/data
COUCHDB_CONFIG_PATH=./notes/obsidian/config

# Drive Services
NEXTCLOUD_IMAGE_TAG=latest
NEXTCLOUD_DB_NAME=nextcloud
NEXTCLOUD_DB_USER=nextcloud
NEXTCLOUD_DB_PASSWORD=secure_password
NEXTCLOUD_DB_ROOT_PASSWORD=secure_root_password
MARIADB_VERSION=10.11
```

## Network Security

### Default Behavior

- **No cross-network communication** between service groups
- **Only cloudflared** can access all networks
- **Internal services** are not exposed to host ports
- **All external access** goes through Cloudflare Tunnel

### Custom Network Communication

If you need cross-service communication, you can:

1. Create additional networks in specific compose files
2. Connect services to multiple networks
3. Use docker network aliases for service discovery

## Troubleshooting

### Service Won't Start

```bash
# Check service logs
./atlantis.sh logs <service_name>

# Check network connectivity
docker network ls
docker network inspect <network_name>
```

### Cloudflared Issues

```bash
# Check cloudflared logs
./atlantis.sh logs cloudflared

# Verify tunnel configuration
docker exec cloudflared_tunnel cloudflared tunnel info
```

### Database Connection Issues

```bash
# Check database health
docker exec <db_container> pg_isready  # PostgreSQL
docker exec <db_container> mysqladmin ping  # MariaDB
```

## Monitoring & Health Checks

All services include health checks:

- **API services**: HTTP endpoint checks
- **Databases**: Connection and ready state checks
- **Web services**: Status page checks
- **Cloudflared**: Tunnel status verification

## Backup Strategy

### Recommended Backup Locations

- **IoT Data**: `iot_db_data` volume
- **Obsidian Data**: `./notes/obsidian/data` directory
- **Nextcloud Data**: `nextcloud_data` volume
- **Affine Data**: `affine_data` volume

### Backup Script Example

```bash
#!/bin/bash
# Create backups of all persistent data
docker run --rm -v iot_db_data:/data -v $(pwd)/backups:/backup alpine tar czf /backup/iot_$(date +%Y%m%d).tar.gz -C /data .
docker run --rm -v nextcloud_data:/data -v $(pwd)/backups:/backup alpine tar czf /backup/nextcloud_$(date +%Y%m%d).tar.gz -C /data .
# Add more services as needed
```

## Contributing

When adding new services:

1. Create a new directory for the service category
2. Create a dedicated `docker-compose.yaml` file
3. Define a unique network name
4. Add the service to `atlantis.sh` script
5. Update cloudflared configuration if external access needed
6. Add environment variables to `.env.example`
7. Update this README

## License

This infrastructure setup is provided as-is for educational and personal use.
