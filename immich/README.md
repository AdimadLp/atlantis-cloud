# Immich - Self-hosted Photo and Video Management

Immich is a high-performance self-hosted photo and video management solution that provides:

- **Auto backup** from mobile devices
- **Machine learning** for face detection, object recognition, and smart search
- **Timeline view** with date-based organization
- **Album management** and sharing
- **Live photos** support
- **Video transcoding** and streaming
- **Mobile apps** for iOS and Android
- **Web interface** for browsing and management

## Quick Start

1. **Configure Environment Variables**
   Copy the environment variables from `.env.example` to your main `.env` file:

   ```bash
   cat immich/.env.example >> .env
   ```

2. **Generate JWT Secret**

   ```bash
   openssl rand -base64 32
   ```

   Add this to your `.env` file as `IMMICH_JWT_SECRET`

3. **Create Storage Directories**

   ```bash
   # Adjust paths according to your setup
   mkdir -p /path/to/immich/{photos,postgres,model-cache}
   chown -R 1000:1000 /path/to/immich/
   ```

4. **Update Environment Variables**
   Edit your `.env` file and set:

   - `IMMICH_DB_PASSWORD` - Set a secure database password
   - `IMMICH_UPLOAD_LOCATION` - Path where photos will be stored
   - `IMMICH_DB_DATA_PATH` - Path for PostgreSQL data
   - `IMMICH_MODEL_CACHE_PATH` - Path for ML model cache

5. **Start Immich**
   ```bash
   ./atlantis-cloud.sh restart immich
   ```

## Access

- **Web Interface**: https://photos.atlantis-cloud.com
- **Mobile Apps**: Download from app stores and connect to your domain

## Initial Setup

1. Visit https://photos.atlantis-cloud.com
2. Create your admin account
3. Configure user settings and preferences
4. Download mobile apps and configure auto-backup

## Services Included

- **immich-server**: Main application server
- **immich-postgres**: PostgreSQL database with vector support
- **immich-redis**: Redis cache for performance
- **immich-machine-learning**: ML service for face detection and smart features

## Hardware Acceleration (Optional)

For better performance, you can enable hardware acceleration:

### Intel Quick Sync Video

Uncomment the Intel QSV section in `docker-compose.yaml` and ensure `/dev/dri` is available.

### NVIDIA GPU

Uncomment the NVIDIA GPU section in `docker-compose.yaml` and ensure NVIDIA Docker runtime is installed.

## Storage Considerations

- **Photos/Videos**: Can grow very large, ensure adequate storage
- **Database**: Metadata and ML embeddings, moderate size
- **Model Cache**: ML models, ~2-4GB when populated

## Backup

Important data to backup:

- `IMMICH_UPLOAD_LOCATION` - Your photos and videos
- `IMMICH_DB_DATA_PATH` - Database with metadata and ML data

## Troubleshooting

### Check Service Status

```bash
./atlantis-cloud.sh logs immich
```

### Restart Services

```bash
./atlantis-cloud.sh restart immich
```

### Database Issues

If you encounter database issues, check the PostgreSQL logs:

```bash
docker logs immich_postgres
```

## Mobile Apps

- **iOS**: Search "Immich" in the App Store
- **Android**: Download from Google Play Store or F-Droid

Configure the apps to connect to: `https://photos.atlantis-cloud.com`
