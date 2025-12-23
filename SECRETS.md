# Docker Compose Secrets Configuration

This project uses Docker Compose secrets instead of `.env` files for managing sensitive data. Secrets are more secure than environment variables and are the recommended approach for storing passwords and other sensitive information.

## Directory Structure

Secrets are stored in the `secrets/` directory with subdirectories for each service:

```
secrets/
├── notes/
│   ├── db_username
│   └── db_password
├── obsidian/
│   ├── couchdb_user
│   └── couchdb_password
├── drive/
│   ├── db_root_password
│   ├── db_user
│   └── db_password
└── immich/
    ├── db_password
    └── jwt_secret
```

## Setting Up Secrets

1. **Create secret files**: Each secret is stored in a separate plain text file. Replace the placeholder values with your actual secrets.

   ```bash
   # Example: Set Nextcloud database password
   echo "your_actual_password" > secrets/drive/db_password
   ```

2. **File permissions**: Make sure secret files are only readable by the owner:

   ```bash
   chmod 600 secrets/**/*
   ```

3. **Git security**: The `secrets/` directory should be ignored in `.gitignore`:

   ```bash
   # Already included - do not commit secrets!
   secrets/
   ```

## Service Configuration

Each compose file now includes a `secrets:` section that references the secret files:

### Notes (Affine) Service

**Secrets used:**

- `db_username`: PostgreSQL username for Affine
- `db_password`: PostgreSQL password for Affine

**File locations:**

- `secrets/notes/db_username`
- `secrets/notes/db_password`

### Obsidian LiveSync Service

**Secrets used:**

- `couchdb_user`: CouchDB admin username
- `couchdb_password`: CouchDB admin password

**File locations:**

- `secrets/obsidian/couchdb_user`
- `secrets/obsidian/couchdb_password`

### Drive (Nextcloud) Service

**Secrets used:**

- `db_root_password`: MariaDB root password
- `db_user`: MariaDB Nextcloud user
- `db_password`: MariaDB Nextcloud password

**File locations:**

- `secrets/drive/db_root_password`
- `secrets/drive/db_user`
- `secrets/drive/db_password`

### Immich Service

**Secrets used:**

- `db_password`: PostgreSQL password for Immich
- `jwt_secret`: JWT secret for authentication

**File locations:**

- `secrets/immich/db_password`
- `secrets/immich/jwt_secret`

## Container Access to Secrets

When using Docker Compose secrets, they are mounted at `/run/secrets/<secret_name>` inside containers. However, most applications expect these values as environment variables.

To bridge this gap, you may need to:

1. **Use initialization scripts** to read secrets and set environment variables
2. **Modify entry points** to read secrets from `/run/secrets/` before starting services
3. **Check application documentation** for native secret support

### Example: Reading Secrets in a Container

If an application supports it, you can use:

```bash
# Inside the container
DB_PASSWORD=$(cat /run/secrets/db_password)
```

## Using Environment Variables with Secrets

**Note:** This repository is intended to work without a `.env` file. For sensitive credentials, we recommend:

1. Use Docker Compose secrets for all passwords and tokens
2. Modify applications to read from `/run/secrets/` or use initialization scripts

## Adding New Secrets

To add a new secret:

1. Create the secret file in the appropriate `secrets/service/` directory
2. Add the secret reference to the compose file:

   ```yaml
   secrets:
     my_secret:
       file: ../secrets/service/my_secret
   ```

3. Reference the secret in your service definition:

   ```yaml
   services:
     my_service:
       secrets:
         - my_secret
   ```

## Security Best Practices

1. **Rotate secrets regularly**: Change passwords and tokens periodically
2. **Use strong passwords**: At least 16 characters with mixed case, numbers, and symbols
3. **Protect secret files**: Use appropriate file permissions (`600` or `400`)
4. **Never commit secrets**: Keep `.gitignore` updated to exclude the `secrets/` directory
5. **Use production secret management**: For production deployments, consider:
   - Docker Swarm secret management
   - External secret vaults (HashiCorp Vault, AWS Secrets Manager, etc.)
   - Kubernetes secrets (if using Kubernetes)

## Migration from .env Files

If you're migrating from a setup that used `.env` files:

1. Extract sensitive values from `.env`
2. Create corresponding secret files in `secrets/`
3. Update compose files to use `secrets:` section
4. Remove `.env` usage from your deployment flow (this repo does not rely on it)
5. Test thoroughly before deploying

## References

- [Docker Compose Secrets Documentation](https://docs.docker.com/compose/use-secrets/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
