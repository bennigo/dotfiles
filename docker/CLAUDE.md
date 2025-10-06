# Docker Configuration

This directory contains Docker Engine configuration, utility scripts, and compose templates for containerized development and deployment.

## Overview

**Docker Version**: 28.4.0 (Docker Engine - Community)
**Compose Version**: v2.39.4 (integrated plugin)
**Storage Driver**: overlay2
**Cgroup Driver**: systemd (Cgroup v2)
**User Group**: docker (passwordless access)

## Directory Structure

```
docker/
├── daemon.json                    # Docker daemon configuration (deployed to /etc/docker/)
├── scripts/
│   ├── docker-cleanup             # Clean up unused containers, images, volumes
│   ├── docker-stats-pretty        # Colorized container statistics
│   └── docker-logs-follow         # Follow logs from multiple containers
├── templates/
│   ├── compose-python-dev.yml     # Python development with PostgreSQL
│   ├── compose-postgres-standalone.yml  # Standalone PostgreSQL instance
│   ├── compose-web-nginx.yml      # Web app with Nginx reverse proxy
│   └── .env.example               # Environment variable template
└── CLAUDE.md                      # This file
```

## Daemon Configuration

### Network Configuration (VPN-Friendly)

The daemon.json is configured to avoid conflicts with common VPN networks:

**Default Bridge IP**: `172.18.0.1/16`
**Custom Address Pools**:
- `172.31.0.0/16` with /24 subnets
- `172.32.0.0/12` with /24 subnets

This avoids conflicts with:
- Common VPN ranges (10.x.x.x, 192.168.x.x)
- Standard Docker range (172.17.0.0/16)
- IMO network ranges (Icelandic Meteorological Office)

### DNS Configuration

**DNS Servers**:
1. `8.8.8.8` - Google DNS (primary)
2. `1.1.1.1` - Cloudflare DNS (secondary)
3. `10.170.255.10` - IMO internal DNS (for work network)

### Logging Configuration

**Log Driver**: json-file
**Log Rotation**:
- Maximum size: 10MB per file
- Maximum files: 3 files per container
- Total: ~30MB per container maximum

**Rationale**: Prevents disk space issues from runaway logs while maintaining sufficient history for debugging.

### Storage Configuration

**Driver**: overlay2
**Backing Filesystem**: extfs
**Features**:
- Native Overlay Diff: enabled
- d_type support: enabled
- metacopy: disabled (stability)

## Utility Scripts

### docker-cleanup

Comprehensive cleanup script for Docker resources.

**Usage**:
```bash
docker-cleanup              # Interactive cleanup (confirmation prompt)
docker-cleanup --all        # Remove ALL unused images (not just dangling)
docker-cleanup --force      # Skip confirmation prompt
```

**What it cleans**:
- Stopped containers
- Dangling images (or all unused with --all)
- Unused volumes
- Unused networks

**Safety**: Shows summary before cleaning, requires confirmation unless --force

### docker-stats-pretty

Colorized, formatted container statistics.

**Usage**:
```bash
docker-stats-pretty                    # All containers
docker-stats-pretty web db             # Specific containers
docker-stats-pretty $(docker ps -q)    # All running (explicit)
```

**Features**:
- Color-coded by resource usage (green/yellow/red)
- System summary (disk usage, reclaimable space)
- Clean tabular output

### docker-logs-follow

Follow logs from multiple containers simultaneously with color coding.

**Usage**:
```bash
docker-logs-follow web                 # Single container
docker-logs-follow web db redis        # Multiple containers
docker-logs-follow $(docker ps -q)     # All running containers
```

**Features**:
- Color-coded by container (up to 6 colors)
- Shows last 10 lines per container
- Compose-style format: `[container-name] log message`

## Compose Templates

### Python Development (compose-python-dev.yml)

**Stack**: Python app + PostgreSQL 18
**Features**:
- Hot reload for development (uvicorn --reload)
- Mounted source code (live editing)
- Persistent Python cache
- Health checks
- Named volumes

**Use Case**: Fast iteration on Python web applications (FastAPI, Flask, Django)

**Quick Start**:
```bash
cp ~/.dotfiles/docker/templates/compose-python-dev.yml docker-compose.yml
cp ~/.dotfiles/docker/templates/.env.example .env
# Edit .env with your settings
docker compose up -d
```

### Standalone PostgreSQL (compose-postgres-standalone.yml)

**Stack**: PostgreSQL 18 + pgAdmin (optional)
**Features**:
- Production-tuned PostgreSQL settings
- Optional pgAdmin web UI (profile: tools)
- Persistent data volume
- Health checks
- Init scripts support

**Use Case**: Local development database, testing, data analysis

**Quick Start**:
```bash
cp ~/.dotfiles/docker/templates/compose-postgres-standalone.yml docker-compose.yml
docker compose up -d
psql -h localhost -U myuser -d mydb

# With pgAdmin:
docker compose --profile tools up -d
# Access pgAdmin: http://localhost:5050
```

### Web Application with Nginx (compose-web-nginx.yml)

**Stack**: Nginx + App + PostgreSQL + Redis
**Features**:
- Nginx reverse proxy (SSL-ready)
- Backend/Frontend network isolation
- Health checks for all services
- Production-ready architecture

**Use Case**: Production deployments, multi-tier applications

**Quick Start**:
```bash
cp ~/.dotfiles/docker/templates/compose-web-nginx.yml docker-compose.yml
# Create nginx configs (nginx.conf, nginx-site.conf)
docker compose up -d
```

## Current Active Containers

**GPS Receivers Scheduler**:
- **Name**: gps-receivers-scheduler
- **Image**: gps-receivers:latest
- **Status**: Running (healthy)
- **Purpose**: Automated GNSS station data collection
- **Project**: ~/work/projects/gps/gpslibrary_new/receivers/

**Persistent Volumes**:
- `docker_gps-cache` - GPS processing cache
- `docker_gps-data` - GPS data storage

## Installation & Deployment

### Ansible-Managed Installation

Docker is installed via Ansible role: `ansible/roles/docker/`

**Installation**:
```bash
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml --extra-vars "profile=work_laptop"
# OR specific role:
ansible-playbook bootstrap.yml --tags "docker"
```

**What Ansible Does**:
1. Removes conflicting packages (docker.io, podman, etc.)
2. Adds official Docker repository
3. Installs Docker Engine + Compose plugin + Buildx
4. Adds user to docker group
5. Deploys daemon.json from dotfiles
6. Starts Docker service

**Post-Install**:
- Log out and back in (for docker group)
- OR run: `newgrp docker`
- Deploy utility scripts: `cd ~/.dotfiles && stow local_bin` (if using stow for scripts)

### Manual Daemon Configuration Update

If daemon.json changes:

```bash
# Edit dotfiles version
nvim ~/.dotfiles/docker/daemon.json

# Deploy via Ansible
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml --tags "docker"

# OR manually
sudo cp ~/.dotfiles/docker/daemon.json /etc/docker/daemon.json
sudo systemctl restart docker
```

## Common Operations

### Container Management

```bash
# List containers
docker ps                    # Running
docker ps -a                 # All

# Start/stop
docker compose up -d         # Start services
docker compose down          # Stop and remove
docker compose restart       # Restart services

# Logs
docker logs -f container     # Follow single container
docker-logs-follow web db    # Follow multiple (custom script)

# Stats
docker stats                 # Basic stats
docker-stats-pretty          # Pretty stats (custom script)

# Cleanup
docker-cleanup               # Interactive cleanup (custom script)
docker system prune -a       # Nuclear option (removes everything unused)
```

### Image Management

```bash
# Build
docker build -t myimage:tag .
docker compose build

# List images
docker images
docker images -f dangling=true    # Unused intermediate images

# Remove
docker rmi image:tag
docker-cleanup --all              # Remove all unused (custom script)
```

### Volume Management

```bash
# List volumes
docker volume ls
docker volume ls -f dangling=true

# Inspect
docker volume inspect volume_name

# Backup volume
docker run --rm -v volume_name:/data -v $(pwd):/backup \
  alpine tar czf /backup/volume-backup.tar.gz -C /data .

# Restore volume
docker run --rm -v volume_name:/data -v $(pwd):/backup \
  alpine tar xzf /backup/volume-backup.tar.gz -C /data

# Remove unused
docker volume prune
docker-cleanup                    # Includes volumes (custom script)
```

### Network Management

```bash
# List networks
docker network ls

# Inspect
docker network inspect network_name

# Create custom network
docker network create --driver bridge mynetwork

# Connect container to network
docker network connect mynetwork container_name
```

### System Information

```bash
# Version info
docker version
docker compose version

# System info
docker info
docker system df              # Disk usage
docker system events          # Real-time events
```

## Development Workflow

### Creating New Project

1. **Create project directory**:
   ```bash
   mkdir myproject && cd myproject
   ```

2. **Choose template**:
   ```bash
   # Python project
   cp ~/.dotfiles/docker/templates/compose-python-dev.yml docker-compose.yml

   # Standalone database
   cp ~/.dotfiles/docker/templates/compose-postgres-standalone.yml docker-compose.yml

   # Web application
   cp ~/.dotfiles/docker/templates/compose-web-nginx.yml docker-compose.yml
   ```

3. **Configure environment**:
   ```bash
   cp ~/.dotfiles/docker/templates/.env.example .env
   nvim .env  # Customize settings
   ```

4. **Customize compose file**:
   ```bash
   nvim docker-compose.yml  # Adjust services, ports, volumes
   ```

5. **Start services**:
   ```bash
   docker compose up -d
   docker compose logs -f
   ```

### GPS Project Pattern

Based on active GPS receivers project:

```yaml
services:
  scheduler:
    build: .
    container_name: gps-receivers-scheduler
    volumes:
      - gps-data:/app/data
      - gps-cache:/app/cache
    environment:
      - GPS_STATIONS_FILE=/app/config/stations.json
      - LOG_LEVEL=INFO
    healthcheck:
      test: ["CMD", "python", "-c", "import requests; requests.get('http://localhost:8000/health')"]
      interval: 1m
      timeout: 10s
      retries: 3
    restart: unless-stopped

volumes:
  gps-data:
    name: docker_gps-data
  gps-cache:
    name: docker_gps-cache
```

## Troubleshooting

### Permission Denied

**Problem**: `permission denied while trying to connect to the Docker daemon socket`

**Solution**:
```bash
# Check group membership
groups | grep docker

# If not in docker group:
sudo usermod -aG docker $USER
newgrp docker  # OR log out and back in
```

### Network Conflicts with VPN

**Problem**: Containers lose connectivity when VPN connects

**Solution**: Already configured in daemon.json with custom address pools
- Verify: `docker network inspect bridge`
- If issues persist, check VPN network ranges and adjust daemon.json

### Container Won't Start

**Debugging steps**:
```bash
# Check logs
docker logs container_name

# Check health
docker inspect container_name | jq '.[0].State.Health'

# Check resources
docker stats container_name

# Check configuration
docker inspect container_name
```

### Disk Space Issues

**Check usage**:
```bash
docker system df
```

**Clean up**:
```bash
docker-cleanup --all --force  # Nuclear option
# OR step-by-step:
docker container prune
docker image prune -a
docker volume prune
docker network prune
```

### Build Cache Issues

**Problem**: Changes not reflected in image

**Solution**:
```bash
docker compose build --no-cache
# OR
docker build --no-cache -t myimage .
```

## Integration with PostgreSQL

Docker containers can connect to host PostgreSQL 18 installation:

**From Container to Host**:
```yaml
services:
  app:
    environment:
      # Use host.docker.internal on Linux with Docker 20.10+
      - DATABASE_URL=postgresql://user:pass@host.docker.internal:5432/dbname
      # OR use host IP
      - DATABASE_URL=postgresql://user:pass@172.18.0.1:5432/dbname
```

**From Host to Container**:
```bash
# PostgreSQL in container
psql -h localhost -p 5432 -U user -d dbname

# With Neovim Database UI
nvim  # :DBUI, connections auto-detected
```

**See Also**: `~/.dotfiles/ansible/DATABASE_SETUP.md` for host PostgreSQL setup

## Security Best Practices

### Credentials Management

**Never hardcode secrets**:
```yaml
# ❌ Bad
environment:
  - DB_PASSWORD=hardcoded_secret

# ✅ Good
environment:
  - DB_PASSWORD=${DB_PASSWORD}  # From .env file
```

**Use Docker secrets for production**:
```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt

services:
  app:
    secrets:
      - db_password
```

### .gitignore Essentials

```gitignore
# Docker
.env
.env.*
!.env.example
docker-compose.override.yml
*.log

# Secrets
secrets/
*.key
*.pem
```

### Network Isolation

**Separate frontend and backend**:
```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No external access
```

### Least Privilege

**Run as non-root**:
```dockerfile
USER nobody:nogroup
```

**Read-only filesystem**:
```yaml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp
```

## Cross-References

- **Ansible Docker Role**: `~/.dotfiles/ansible/roles/docker/`
- **PostgreSQL Setup**: `~/.dotfiles/ansible/DATABASE_SETUP.md`
- **Main Dotfiles**: `~/.dotfiles/CLAUDE.md`
- **GPS Projects**: `~/work/projects/gps/`

## Performance Tips

### Build Optimization

**Use .dockerignore**:
```
.git
.gitignore
README.md
.env*
*.log
__pycache__
*.pyc
node_modules
```

**Multi-stage builds**:
```dockerfile
# Build stage
FROM python:3.11 AS builder
RUN pip install --user package

# Runtime stage
FROM python:3.11-slim
COPY --from=builder /root/.local /root/.local
```

### Layer Caching

**Order matters**:
```dockerfile
# ✅ Good - dependencies cached
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

# ❌ Bad - cache invalidated on every code change
COPY . .
RUN pip install -r requirements.txt
```

### Resource Limits

**Prevent resource exhaustion**:
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

---

**Created**: 2025-10-05
**Docker Version**: 28.4.0
**Purpose**: Production-ready Docker configuration for scientific computing and web development
**Context Level**: Docker-specific configuration and workflow guidance
