#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 Rayhunter Enhanced Docker Build Script${NC}"
echo -e "${BLUE}=========================================${NC}"

# Function to show usage
usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  build     - Build the Docker image"
    echo "  run       - Run the container interactively (temporary)"
    echo "  up        - Start container (uses docker-compose if available)"
    echo "  down      - Stop container/services"
    echo "  shell     - Open shell in running container"
    echo "  logs      - Show container logs"
    echo "  clean     - Remove container and image"
    echo "  rebuild   - Clean and rebuild everything"
    echo "  status    - Show container status"
    echo ""
    echo "Build Options:"
    echo "  --repo URL    - Git repository URL (default: https://github.com/drinkingc0ffee/rayhunter-enhanced.git)"
    echo "  --branch NAME - Git branch/tag to use (default: main)"
    echo "  --dev         - Enable development mode (mount local directory)"
    echo ""
    echo "Examples:"
    echo "  $0 up                    # Start the environment"
    echo "  $0 shell                 # Open shell in container"
    echo "  $0 build --branch develop # Build from develop branch"
    echo "  $0 up --dev             # Start with local development mode"
    echo "  $0 rebuild --repo https://github.com/user/fork.git"
}

# Function to build the image
build_image() {
    echo -e "${YELLOW}🔨 Building Docker image...${NC}"
    echo -e "${BLUE}📁 Building from parent directory with docker-build context...${NC}"
    docker build -f Dockerfile -t rayhunter-enhanced:latest ..
    echo -e "${GREEN}✅ Docker image built successfully${NC}"
}

# Function to run container (temporary)
run_container() {
    echo -e "${YELLOW}🚀 Running container...${NC}"
    docker run -it --rm \
        --name docker-ubuntu-build \
        -v "$(dirname $(pwd)):/workspace/rayhunter-enhanced:cached" \
        -p 8080:8080 -p 8000:8000 \
        rayhunter-enhanced:latest
}

# Function to run container (persistent, like docker-compose)
run_container_persistent() {
    echo -e "${YELLOW}🚀 Running container in background...${NC}"
    
    # Create volume if it doesn't exist
    docker volume create rayhunter-home 2>/dev/null || true
    
    # Stop existing container if running
    docker stop docker-ubuntu-build 2>/dev/null || true
    docker rm docker-ubuntu-build 2>/dev/null || true
    
    # Run container in background
    docker run -d \
        --name docker-ubuntu-build \
        --hostname rayhunter-build \
        -v rayhunter-home:/home/rayhunter \
        -p 8080:8080 -p 8000:8000 \
        -e TERM=xterm-256color \
        -e COLORTERM=truecolor \
        --tty \
        rayhunter-enhanced:latest
    
    echo -e "${GREEN}✅ Container started${NC}"
    echo -e "${BLUE}📋 To access the environment:${NC}"
    echo "  docker exec -it docker-ubuntu-build su - rayhunter"
    echo "  or use: $0 shell"
}

# Function to detect docker compose command
get_docker_compose_cmd() {
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    elif docker compose version &> /dev/null; then
        echo "docker compose"
    else
        echo "NONE"
    fi
}

# Function to use docker-compose
compose_up() {
    local compose_cmd=$(get_docker_compose_cmd)
    
    if [ "$compose_cmd" = "NONE" ]; then
        echo -e "${YELLOW}⚠️  Docker Compose not found, using plain docker run...${NC}"
        run_container_persistent
        return
    fi
    
    echo -e "${YELLOW}🚀 Starting with $compose_cmd...${NC}"
    $compose_cmd up -d
    echo -e "${GREEN}✅ Container started${NC}"
    echo -e "${BLUE}📋 To access the environment:${NC}"
    echo "  $compose_cmd exec rayhunter-build bash"
    echo "  or use: $0 shell"
}

# Function to stop docker-compose
compose_down() {
    local compose_cmd=$(get_docker_compose_cmd)
    
    if [ "$compose_cmd" = "NONE" ]; then
        echo -e "${YELLOW}🛑 Stopping container (no Docker Compose)...${NC}"
        docker stop docker-ubuntu-build 2>/dev/null || true
        docker rm docker-ubuntu-build 2>/dev/null || true
        echo -e "${GREEN}✅ Container stopped${NC}"
        return
    fi
    
    echo -e "${YELLOW}🛑 Stopping $compose_cmd services...${NC}"
    $compose_cmd down
    echo -e "${GREEN}✅ Services stopped${NC}"
}

# Function to open shell in running container
open_shell() {
    if docker ps --format '{{.Names}}' | grep -q "docker-ubuntu-build"; then
        echo -e "${YELLOW}🖥️  Opening shell in running container...${NC}"
        docker exec -it docker-ubuntu-build bash
    else
        echo -e "${RED}❌ Container not running. Start it first with: $0 up${NC}"
        exit 1
    fi
}

# Function to show logs
show_logs() {
    if docker ps --format '{{.Names}}' | grep -q "docker-ubuntu-build"; then
        echo -e "${YELLOW}📝 Showing container logs...${NC}"
        docker logs -f docker-ubuntu-build
    else
        echo -e "${RED}❌ Container not running${NC}"
        exit 1
    fi
}

# Function to clean up
clean_up() {
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    
    # Stop and remove container
    if docker ps -a --format '{{.Names}}' | grep -q "docker-ubuntu-build"; then
        docker stop docker-ubuntu-build || true
        docker rm docker-ubuntu-build || true
    fi
    
    # Remove image
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "rayhunter-enhanced:latest"; then
        docker rmi rayhunter-enhanced:latest || true
    fi
    
    # Clean up docker-compose
    local compose_cmd=$(get_docker_compose_cmd)
    if [ "$compose_cmd" != "NONE" ]; then
        $compose_cmd down --volumes --remove-orphans || true
    fi
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Function to rebuild everything
rebuild_all() {
    echo -e "${YELLOW}🔄 Rebuilding everything...${NC}"
    clean_up
    build_image
    echo -e "${GREEN}✅ Rebuild completed${NC}"
}

# Function to show status
show_status() {
    echo -e "${BLUE}📊 Container Status:${NC}"
    echo "=================="
    
    if docker ps --format '{{.Names}}' | grep -q "docker-ubuntu-build"; then
        echo -e "${GREEN}✅ Container is running${NC}"
        docker ps --filter "name=docker-ubuntu-build" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo -e "${YELLOW}⏸️  Container is not running${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}📊 Image Status:${NC}"
    echo "==============="
    
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "rayhunter-enhanced:latest"; then
        echo -e "${GREEN}✅ Image exists${NC}"
        docker images --filter "reference=rayhunter-enhanced:latest" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    else
        echo -e "${YELLOW}⏸️  Image not built${NC}"
    fi
}

# Main script logic
case "${1:-}" in
    build)
        build_image
        ;;
    run)
        run_container
        ;;
    up)
        compose_up
        ;;
    down)
        compose_down
        ;;
    shell)
        open_shell
        ;;
    logs)
        show_logs
        ;;
    clean)
        clean_up
        ;;
    rebuild)
        rebuild_all
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        usage
        ;;
    "")
        echo -e "${RED}❌ No command provided${NC}"
        echo ""
        usage
        exit 1
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        usage
        exit 1
        ;;
esac 