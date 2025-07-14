# Docker Build Directory

This directory contains all Docker-related files for the rayhunter-enhanced project.

## Files

- **`Dockerfile`** - Container definition with Ubuntu build environment
- **`docker-compose.yml`** - Docker Compose configuration for persistent environment
- **`docker-build.sh`** - Main Docker management script
- **`.dockerignore`** - Files to exclude from Docker build context
- **`DOCKER_BUILD_GUIDE.md`** - Complete Docker build documentation

## Usage

### From Project Root
Use the wrapper script from the project root:
```bash
./docker.sh up          # Start container
./docker.sh shell       # Open shell in container
./docker.sh down        # Stop container
./docker.sh status      # Show status
```

### From This Directory
You can also run commands directly from this directory:
```bash
cd docker-build
./docker-build.sh up    # Start container
./docker-build.sh shell # Open shell
```

## Quick Start

1. **Start Docker Environment**:
   ```bash
   ./docker.sh up
   ./docker.sh shell
   ```

2. **Inside Container - Run 3-Step Build**:
   ```bash
   ./setup_ubuntu_ci.sh && ./fetch_source.sh && ./build_and_deploy.sh
   ```

See `DOCKER_BUILD_GUIDE.md` for complete documentation. 