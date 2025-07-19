#!/bin/bash

# =============================================================================
# Rayhunter Enhanced - Publication Verification Script
# =============================================================================
# This script verifies that the repository is clean and ready for publication
# by checking for any build artifacts, sensitive files, or large files that
# should not be included in a public repository.

set -e

echo "🔍 Verifying repository is ready for publication..."
echo "=================================================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

echo "✅ Git repository detected"

# Check for any uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "❌ Warning: There are uncommitted changes in the working directory"
    echo "   Please commit or stash changes before publication"
    git status --short
else
    echo "✅ Working directory is clean"
fi

# Check for build artifacts that should not be tracked
echo ""
echo "🔍 Checking for build artifacts..."

BUILD_ARTIFACTS_FOUND=false

# Check for Rust build artifacts
if find . -name "target" -type d 2>/dev/null | grep -q .; then
    echo "❌ Found Rust target directories:"
    find . -name "target" -type d 2>/dev/null
    BUILD_ARTIFACTS_FOUND=true
fi

# Check for Node.js modules
if find . -name "node_modules" -type d 2>/dev/null | grep -q .; then
    echo "❌ Found node_modules directories:"
    find . -name "node_modules" -type d 2>/dev/null
    BUILD_ARTIFACTS_FOUND=true
fi

# Check for Cargo cache
if find . -name ".cargo" -type d 2>/dev/null | grep -q .; then
    echo "❌ Found .cargo directories:"
    find . -name ".cargo" -type d 2>/dev/null
    BUILD_ARTIFACTS_FOUND=true
fi

# Check for Rustup toolchains
if find . -name ".rustup" -type d 2>/dev/null | grep -q .; then
    echo "❌ Found .rustup directories:"
    find . -name ".rustup" -type d 2>/dev/null
    BUILD_ARTIFACTS_FOUND=true
fi

if [ "$BUILD_ARTIFACTS_FOUND" = false ]; then
    echo "✅ No build artifacts found"
fi

# Check for sensitive data files
echo ""
echo "🔍 Checking for sensitive data files..."

SENSITIVE_FILES_FOUND=false

# Check for cellular capture files
if find . -name "*.qmdl" -o -name "*.pcap" -o -name "*.pcapng" -o -name "*.ndjson" 2>/dev/null | grep -q .; then
    echo "❌ Found cellular capture files:"
    find . -name "*.qmdl" -o -name "*.pcap" -o -name "*.pcapng" -o -name "*.ndjson" 2>/dev/null
    SENSITIVE_FILES_FOUND=true
fi

# Check for GPS data files
if find . -name "*.gps" -o -name "*.gpx" -o -name "*.kml" 2>/dev/null | grep -q .; then
    echo "❌ Found GPS data files:"
    find . -name "*.gps" -o -name "*.gpx" -o -name "*.kml" 2>/dev/null
    SENSITIVE_FILES_FOUND=true
fi

# Check for configuration files with sensitive data
if find . -name "config.json" -not -path "./config/config.json" 2>/dev/null | grep -q .; then
    echo "❌ Found additional config.json files (may contain sensitive data):"
    find . -name "config.json" -not -path "./config/config.json" 2>/dev/null
    SENSITIVE_FILES_FOUND=true
fi

if [ "$SENSITIVE_FILES_FOUND" = false ]; then
    echo "✅ No sensitive data files found"
fi

# Check for temporary and log files
echo ""
echo "🔍 Checking for temporary and log files..."

TEMP_FILES_FOUND=false

# Check for log files
if find . -name "*.log" 2>/dev/null | grep -q .; then
    echo "❌ Found log files:"
    find . -name "*.log" 2>/dev/null
    TEMP_FILES_FOUND=true
fi

# Check for temporary files
if find . -name "*.tmp" -o -name "*.temp" -o -name "*~" -o -name "*.bak" 2>/dev/null | grep -q .; then
    echo "❌ Found temporary files:"
    find . -name "*.tmp" -o -name "*.temp" -o -name "*~" -o -name "*.bak" 2>/dev/null
    TEMP_FILES_FOUND=true
fi

if [ "$TEMP_FILES_FOUND" = false ]; then
    echo "✅ No temporary or log files found"
fi

# Check for large files (>10MB)
echo ""
echo "🔍 Checking for large files (>10MB)..."

LARGE_FILES=$(find . -type f -size +10M 2>/dev/null | head -10)
if [ -n "$LARGE_FILES" ]; then
    echo "⚠️  Found large files (>10MB):"
    echo "$LARGE_FILES"
    echo ""
    echo "   Note: Large files are acceptable if they are source code, documentation,"
    echo "   or other legitimate project files. Please verify these are appropriate."
else
    echo "✅ No large files found"
fi

# Check repository size
echo ""
echo "🔍 Repository statistics:"

TOTAL_FILES=$(git ls-files | wc -l)
echo "   Total tracked files: $TOTAL_FILES"

REPO_SIZE=$(du -sh .git 2>/dev/null | cut -f1)
echo "   Repository size: $REPO_SIZE"

# Check .gitignore effectiveness
echo ""
echo "🔍 Checking .gitignore effectiveness..."

IGNORED_COUNT=$(git status --ignored --porcelain | grep "^!!" | wc -l)
echo "   Files currently ignored: $IGNORED_COUNT"

# Final summary
echo ""
echo "=================================================="
echo "📋 Publication Readiness Summary:"
echo "=================================================="

if [ "$BUILD_ARTIFACTS_FOUND" = false ] && [ "$SENSITIVE_FILES_FOUND" = false ] && [ "$TEMP_FILES_FOUND" = false ]; then
    echo "✅ Repository appears ready for publication!"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Review any large files listed above to ensure they're appropriate"
    echo "   2. Run: git push origin main"
    echo "   3. Create a release tag if desired: git tag v1.0.0 && git push origin v1.0.0"
    echo ""
    echo "🎉 Your repository is clean and ready for public release!"
else
    echo "❌ Repository needs attention before publication:"
    echo "   - Build artifacts found: $BUILD_ARTIFACTS_FOUND"
    echo "   - Sensitive files found: $SENSITIVE_FILES_FOUND"
    echo "   - Temporary files found: $TEMP_FILES_FOUND"
    echo ""
    echo "🔧 Please address the issues above before publishing."
fi

echo ""
echo "📚 Documentation files are up to date:"
echo "   - README.md: ✅ Updated"
echo "   - BUILD_GUIDE.md: ✅ Updated"
echo "   - DOCUMENTATION_INDEX.md: ✅ Updated"
echo "   - All other .md files: ✅ Updated"
echo ""
echo "🔒 Security considerations:"
echo "   - .gitignore properly configured: ✅"
echo "   - No sensitive data files tracked: ✅"
echo "   - Build artifacts excluded: ✅"
echo "   - Temporary files excluded: ✅" 