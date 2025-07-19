#!/bin/bash

# =============================================================================
# Rayhunter Enhanced - Repository Cleanup for Publication
# =============================================================================
# This script cleans up the repository by removing build artifacts, caches,
# and temporary files to prepare for publication.

set -e

echo "🧹 Cleaning up Rayhunter Enhanced repository for publication..."
echo "================================================================"

# =============================================================================
# REMOVE BUILD ARTIFACTS AND CACHES
# =============================================================================

echo "📦 Removing build artifacts and caches..."

# Remove Rust build artifacts
if [ -d "target" ]; then
    echo "  Removing target/ directory..."
    rm -rf target/
fi

# Remove Cargo registry and cache
if [ -d ".cargo" ]; then
    echo "  Removing .cargo/ directory..."
    rm -rf .cargo/
fi

# Remove Rustup toolchains
if [ -d ".rustup" ]; then
    echo "  Removing .rustup/ directory..."
    rm -rf .rustup/
fi

# Remove Node.js modules
if [ -d "node_modules" ]; then
    echo "  Removing node_modules/ directory..."
    rm -rf node_modules/
fi

if [ -d "bin/web/node_modules" ]; then
    echo "  Removing bin/web/node_modules/ directory..."
    rm -rf bin/web/node_modules/
fi

# Remove web build outputs
if [ -d "bin/web/build" ]; then
    echo "  Removing bin/web/build/ directory..."
    rm -rf bin/web/build/
fi

if [ -d "bin/web/dist" ]; then
    echo "  Removing bin/web/dist/ directory..."
    rm -rf bin/web/dist/
fi

if [ -d "bin/web/.svelte-kit" ]; then
    echo "  Removing bin/web/.svelte-kit/ directory..."
    rm -rf bin/web/.svelte-kit/
fi

# Remove deployment artifacts
if [ -d "tmp-deploy" ]; then
    echo "  Removing tmp-deploy/ directory..."
    rm -rf tmp-deploy/
fi

if [ -d "deploy" ]; then
    echo "  Removing deploy/ directory..."
    rm -rf deploy/
fi

# Remove local build dependencies
if [ -d "build_deps" ]; then
    echo "  Removing build_deps/ directory..."
    rm -rf build_deps/
fi

if [ -d ".local_deps" ]; then
    echo "  Removing .local_deps/ directory..."
    rm -rf .local_deps/
fi

# Remove user home directory (if accidentally created)
if [ -d "rayhunter" ]; then
    echo "  Removing rayhunter/ directory (user home artifacts)..."
    rm -rf rayhunter/
fi

# =============================================================================
# REMOVE TEMPORARY AND WORKING FILES
# =============================================================================

echo "🗑️  Removing temporary and working files..."

# Remove temporary directories
for dir in temp tmp scratch .working; do
    if [ -d "$dir" ]; then
        echo "  Removing $dir/ directory..."
        rm -rf "$dir/"
    fi
done

# Remove backup files
find . -name "*.bak" -o -name "*.backup" -o -name "*.old" -o -name "*.orig" 2>/dev/null | while read file; do
    echo "  Removing backup file: $file"
    rm -f "$file"
done

# Remove temporary files
find . -name "*.tmp" -o -name "*.temp" -o -name "*~" 2>/dev/null | while read file; do
    echo "  Removing temporary file: $file"
    rm -f "$file"
done

# =============================================================================
# REMOVE LOG FILES
# =============================================================================

echo "📝 Removing log files..."

# Remove application logs
find . -name "*.log" 2>/dev/null | while read file; do
    echo "  Removing log file: $file"
    rm -f "$file"
done

# Remove logs directories
if [ -d "logs" ]; then
    echo "  Removing logs/ directory..."
    rm -rf logs/
fi

# =============================================================================
# REMOVE PYTHON CACHE
# =============================================================================

echo "🐍 Removing Python cache files..."

# Remove Python cache directories
find . -name "__pycache__" -type d 2>/dev/null | while read dir; do
    echo "  Removing Python cache: $dir"
    rm -rf "$dir"
done

# Remove Python compiled files
find . -name "*.pyc" -o -name "*.pyo" -o -name "*.pyd" 2>/dev/null | while read file; do
    echo "  Removing Python compiled file: $file"
    rm -f "$file"
done

# Remove virtual environments
for venv in env venv .venv ENV; do
    if [ -d "$venv" ]; then
        echo "  Removing virtual environment: $venv"
        rm -rf "$venv"
    fi
done

# =============================================================================
# REMOVE IDE AND EDITOR FILES
# =============================================================================

echo "💻 Removing IDE and editor files..."

# Remove VSCode settings
if [ -f ".vscode/settings.json" ]; then
    echo "  Removing .vscode/settings.json..."
    rm -f .vscode/settings.json
fi

# Remove IntelliJ IDEA files
if [ -d ".idea" ]; then
    echo "  Removing .idea/ directory..."
    rm -rf .idea/
fi

# Remove Vim swap files
find . -name "*.swp" -o -name "*.swo" 2>/dev/null | while read file; do
    echo "  Removing Vim swap file: $file"
    rm -f "$file"
done

# =============================================================================
# REMOVE SENSITIVE DATA FILES
# =============================================================================

echo "🔒 Removing sensitive data files..."

# Remove cellular capture files
find . -name "*.qmdl" -o -name "*.pcapng" -o -name "*.ndjson" -o -name "*.pcap" -o -name "*.sdm" -o -name "*.lpd" 2>/dev/null | while read file; do
    echo "  Removing cellular capture file: $file"
    rm -f "$file"
done

# Remove GPS data files
find . -name "*.gps" -o -name "*.gpx" -o -name "*.kml" 2>/dev/null | while read file; do
    echo "  Removing GPS data file: $file"
    rm -f "$file"
done

# Remove analysis results
find . -name "*_analysis.json" -o -name "*_analysis.txt" -o -name "*_analysis.csv" -o -name "*_analysis.md" 2>/dev/null | while read file; do
    echo "  Removing analysis file: $file"
    rm -f "$file"
done

# Remove correlation files
find . -name "*_correlation.csv" -o -name "*_correlation.gpx" -o -name "*_correlation.kml" 2>/dev/null | while read file; do
    echo "  Removing correlation file: $file"
    rm -f "$file"
done

# =============================================================================
# REMOVE CONFIGURATION AND SECRET FILES
# =============================================================================

echo "🔐 Removing configuration and secret files..."

# Remove environment files
find . -name ".env*" 2>/dev/null | while read file; do
    echo "  Removing environment file: $file"
    rm -f "$file"
done

# Remove certificate files
find . -name "*.key" -o -name "*.pem" -o -name "*.p12" -o -name "*.crt" -o -name "*.csr" 2>/dev/null | while read file; do
    echo "  Removing certificate file: $file"
    rm -f "$file"
done

# Remove build environment files
find . -name ".rayhunter_build_env" 2>/dev/null | while read file; do
    echo "  Removing build environment file: $file"
    rm -f "$file"
done

# =============================================================================
# REMOVE OPERATING SYSTEM FILES
# =============================================================================

echo "🖥️  Removing operating system files..."

# Remove macOS files
find . -name ".DS_Store" -o -name ".AppleDouble" -o -name ".LSOverride" 2>/dev/null | while read file; do
    echo "  Removing macOS file: $file"
    rm -f "$file"
done

# Remove Windows files
find . -name "Thumbs.db" -o -name "ehthumbs.db" -o -name "Desktop.ini" 2>/dev/null | while read file; do
    echo "  Removing Windows file: $file"
    rm -f "$file"
done

# =============================================================================
# VERIFY CLEANUP
# =============================================================================

echo "✅ Verifying cleanup..."

# Check for remaining large files
echo "  Checking for large files (>10MB)..."
LARGE_FILES=$(find . -type f -size +10M 2>/dev/null | grep -v ".git" || true)
if [ -n "$LARGE_FILES" ]; then
    echo "  ⚠️  Warning: Found large files:"
    echo "$LARGE_FILES" | while read file; do
        echo "    $file"
    done
else
    echo "  ✅ No large files found"
fi

# Check for remaining build artifacts
echo "  Checking for remaining build artifacts..."
BUILD_ARTIFACTS=$(find . -name "target" -o -name ".cargo" -o -name ".rustup" -o -name "node_modules" -o -name "tmp-deploy" -o -name "build_deps" 2>/dev/null | grep -v ".git" || true)
if [ -n "$BUILD_ARTIFACTS" ]; then
    echo "  ⚠️  Warning: Found build artifacts:"
    echo "$BUILD_ARTIFACTS" | while read artifact; do
        echo "    $artifact"
    done
else
    echo "  ✅ No build artifacts found"
fi

# Check for remaining log files
echo "  Checking for remaining log files..."
LOG_FILES=$(find . -name "*.log" 2>/dev/null | grep -v ".git" || true)
if [ -n "$LOG_FILES" ]; then
    echo "  ⚠️  Warning: Found log files:"
    echo "$LOG_FILES" | while read file; do
        echo "    $file"
    done
else
    echo "  ✅ No log files found"
fi

# =============================================================================
# FINAL STEPS
# =============================================================================

echo ""
echo "🎉 Repository cleanup completed!"
echo "================================================================"
echo ""
echo "📋 Next steps for publication:"
echo "  1. Review the changes: git status"
echo "  2. Add the updated .gitignore: git add .gitignore"
echo "  3. Add your documentation updates: git add *.md"
echo "  4. Commit the changes: git commit -m 'Prepare repository for publication'"
echo "  5. Push to your repository"
echo ""
echo "🔍 To verify the repository is clean:"
echo "  git status --porcelain"
echo "  git ls-files | wc -l"
echo ""
echo "📦 The repository is now ready for publication!" 