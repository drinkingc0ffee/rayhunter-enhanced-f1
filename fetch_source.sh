#!/bin/bash -e

# Rayhunter Enhanced Source Code Fetcher
# Step 2: Download the latest source code

echo "📥 Fetching rayhunter-enhanced source code..."
echo "=============================================="

# Configuration
REPO_URL="${REPO_URL:-https://github.com/drinkingc0ffee/rayhunter-enhanced.git}"
BRANCH="${BRANCH:-main}"
SOURCE_DIR="$HOME/rayhunter-enhanced"

echo "📋 Source configuration:"
echo "  Repository: $REPO_URL"
echo "  Branch: $BRANCH"
echo "  Directory: $SOURCE_DIR"
echo ""

# Check if git is available
if ! command -v git &> /dev/null; then
    echo "❌ Git not found. Please run ./setup_ubuntu_ci.sh first."
    exit 1
fi

# Handle existing source directory
if [ -d "$SOURCE_DIR" ]; then
    echo "📁 Source directory already exists"
    
    # Check if it's a git repository
    if [ -d "$SOURCE_DIR/.git" ]; then
        echo "🔄 Updating existing repository..."
        cd "$SOURCE_DIR"
        
        # Save any local changes
        if ! git diff --quiet || ! git diff --cached --quiet; then
            echo "⚠️  Local changes detected, stashing them..."
            git stash push -m "Auto-stash before fetch - $(date)"
        fi
        
        # Fetch latest changes
        git fetch origin
        git checkout "$BRANCH"
        git pull origin "$BRANCH"
        
        echo "✅ Repository updated to latest $BRANCH"
    else
        echo "⚠️  Directory exists but is not a git repository"
        echo "🔄 Moving existing directory and cloning fresh..."
        
        # Backup existing directory
        BACKUP_DIR="${SOURCE_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        mv "$SOURCE_DIR" "$BACKUP_DIR"
        echo "📦 Existing directory backed up to: $BACKUP_DIR"
        
        # Clone fresh
        git clone --branch "$BRANCH" "$REPO_URL" "$SOURCE_DIR"
        echo "✅ Fresh repository cloned"
    fi
else
    echo "📥 Cloning repository for the first time..."
    git clone --branch "$BRANCH" "$REPO_URL" "$SOURCE_DIR"
    echo "✅ Repository cloned successfully"
fi

# Change to source directory
cd "$SOURCE_DIR"

# Show repository information
echo ""
echo "📊 Repository information:"
echo "========================="
echo "Current branch: $(git rev-parse --abbrev-ref HEAD)"
echo "Latest commit: $(git log -1 --pretty=format:'%h - %s (%an, %ar)')"
echo "Repository status: $(git status --porcelain | wc -l) modified files"

# Check for required build scripts
echo ""
echo "🔍 Checking for build scripts..."
if [ -f "./build_all.sh" ]; then
    echo "✅ build_all.sh found"
else
    echo "⚠️  build_all.sh not found"
fi

if [ -f "./setup_local_deps.sh" ]; then
    echo "✅ setup_local_deps.sh found"
else
    echo "⚠️  setup_local_deps.sh not found"
fi

# Make scripts executable
echo ""
echo "🔧 Making scripts executable..."
chmod +x *.sh 2>/dev/null || true
echo "✅ Scripts made executable"

# Auto-patch project build scripts to load build environment
echo ""
echo "🔧 Patching project build scripts to auto-load build environment..."

# Function to patch a build script
patch_build_script() {
    local script_file="$1"
    if [ -f "$script_file" ]; then
        # Check if already patched
        if ! grep -q "Auto-load build environment" "$script_file"; then
            # Create backup
            cp "$script_file" "${script_file}.backup"
            
            # Create patched version
            cat > "${script_file}.tmp" << 'EOF'
#!/bin/bash

# Auto-load build environment (added by fetch_source.sh)
if [ -f "$HOME/.rayhunter_build_env" ]; then
    source "$HOME/.rayhunter_build_env"
elif [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

EOF
            
            # Append original script (skip the shebang line)
            tail -n +2 "$script_file" >> "${script_file}.tmp"
            
            # Replace original with patched version
            mv "${script_file}.tmp" "$script_file"
            chmod +x "$script_file"
            
            echo "  ✅ Patched: $script_file"
        else
            echo "  ℹ️  Already patched: $script_file"
        fi
    fi
}

# Patch key build scripts
patch_build_script "build_all.sh"
patch_build_script "make.sh"
patch_build_script "clean.sh"
patch_build_script "deploy.sh"

echo "✅ Build scripts patched for automatic environment loading"

# Show project structure
echo ""
echo "📁 Project structure:"
echo "===================="
ls -la

echo ""
echo "✅ Source code fetch completed successfully!"
echo "==========================================="
echo ""
echo "📍 Source code location: $SOURCE_DIR"
echo ""
echo "🎯 Next steps:"
echo "1. Run: ./build_and_deploy.sh (to build and install the app)"
echo "2. Or manually: cd ~/rayhunter-enhanced && ./build_all.sh"
echo "" 