#!/bin/bash

# Complete Cleanup Script for rayhunter-enhanced
# This script removes build artifacts, Docker containers, and images

echo "🧹 Complete Cleanup for rayhunter-enhanced"
echo "==========================================="

# Function to show disk usage
show_disk_usage() {
    echo "📊 Current directory size: $(du -sh . | cut -f1)"
}

echo "📊 Before cleanup:"
show_disk_usage
echo ""

# 1. Clean Docker containers and images
echo "🐳 Cleaning Docker containers and images..."
echo "============================================="

# Stop and remove containers
if docker ps -a --format '{{.Names}}' | grep -q "docker-ubuntu-build"; then
    echo "🛑 Stopping Docker container..."
    docker stop docker-ubuntu-build || true
    echo "🗑️  Removing Docker container..."
    docker rm docker-ubuntu-build || true
    echo "✅ Docker container removed"
else
    echo "ℹ️  No Docker container to remove"
fi

# Remove Docker images
if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "rayhunter-enhanced:latest"; then
    echo "🗑️  Removing Docker image..."
    docker rmi rayhunter-enhanced:latest || true
    echo "✅ Docker image removed"
else
    echo "ℹ️  No Docker image to remove"
fi

# Clean up docker-compose volumes
echo "🗑️  Cleaning Docker volumes..."
if docker volume ls | grep -q "rayhunter-home"; then
    docker volume rm rayhunter-home || true
    echo "✅ Docker volumes cleaned"
else
    echo "ℹ️  No Docker volumes to clean"
fi

# 2. Clean build artifacts
echo ""
echo "🔧 Cleaning build artifacts..."
echo "==============================="

# Clean Rust build artifacts
if [ -d "target" ]; then
    echo "🗑️  Cleaning Rust target directory..."
    rm -rf target/
    echo "✅ Rust artifacts cleaned"
fi

# Clean Node.js artifacts
if [ -d "bin/web/node_modules" ]; then
    echo "🗑️  Cleaning Node.js modules..."
    rm -rf bin/web/node_modules/
    echo "✅ Node.js modules cleaned"
fi

if [ -d "bin/web/build" ]; then
    echo "🗑️  Cleaning web build artifacts..."
    rm -rf bin/web/build/
    echo "✅ Web build artifacts cleaned"
fi

# Clean build_deps if it exists and is not empty
if [ -d "build_deps" ] && [ "$(ls -A build_deps)" ]; then
    echo "🗑️  Cleaning local build dependencies..."
    rm -rf build_deps/
    echo "✅ Local build dependencies cleaned"
fi

# 3. Clean temporary files
echo ""
echo "🧽 Cleaning temporary files..."
echo "==============================="

# Clean any backup files
if ls *.backup 1> /dev/null 2>&1; then
    echo "🗑️  Cleaning backup files..."
    rm -f *.backup
    echo "✅ Backup files cleaned"
fi

# Clean any temporary files
if ls *.tmp 1> /dev/null 2>&1; then
    echo "🗑️  Cleaning temporary files..."
    rm -f *.tmp
    echo "✅ Temporary files cleaned"
fi

# Clean any .DS_Store files (macOS)
if ls .DS_Store 1> /dev/null 2>&1; then
    echo "🗑️  Cleaning .DS_Store files..."
    find . -name ".DS_Store" -delete
    echo "✅ .DS_Store files cleaned"
fi

# Clean any editor temp files
if ls *.swp *.swo 1> /dev/null 2>&1; then
    echo "🗑️  Cleaning editor temp files..."
    rm -f *.swp *.swo
    echo "✅ Editor temp files cleaned"
fi

# 4. System-wide Docker cleanup (optional)
echo ""
echo "🚮 System-wide Docker cleanup..."
echo "================================="

# Remove unused Docker images
echo "🗑️  Removing unused Docker images..."
docker image prune -f || true

# Remove unused Docker volumes
echo "🗑️  Removing unused Docker volumes..."
docker volume prune -f || true

# Remove unused Docker networks
echo "🗑️  Removing unused Docker networks..."
docker network prune -f || true

echo "✅ System-wide Docker cleanup completed"

echo ""
echo "🎉 Complete cleanup finished!"
echo "============================="
echo "📊 After cleanup:"
show_disk_usage
echo ""
echo "🚀 Your rayhunter-enhanced directory is now clean!"
echo ""
echo "🔄 To start fresh:"
echo "  1. Docker: ./docker.sh up && ./docker.sh shell"
echo "  2. Build: ./build_all.sh"
echo "  3. Deploy: ./deploy.sh" 