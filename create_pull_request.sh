#!/bin/bash

# Script to create a pull request from rayhunter-enhanced to the original EFForg/rayhunter repository
# This script prepares everything needed for a pull request

set -e

echo "=== Rayhunter Enhanced Pull Request Creator ==="
echo ""

# Check if we're in the right directory
if [ ! -f "Cargo.toml" ] || [ ! -d ".git" ]; then
    echo "Error: This script must be run from the rayhunter-enhanced repository root"
    exit 1
fi

# Check current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"

# Check if we have uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "Warning: You have uncommitted changes. Please commit or stash them first."
    git status --short
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create a feature branch for the pull request
FEATURE_BRANCH="enhanced-features-$(date +%Y%m%d)"
echo "Creating feature branch: $FEATURE_BRANCH"
git checkout -b "$FEATURE_BRANCH"

# Push the feature branch to your fork
echo "Pushing feature branch to your fork..."
git push origin "$FEATURE_BRANCH"

# Show summary of changes
echo ""
echo "=== Summary of Changes ==="
echo "Your enhanced version includes the following commits compared to upstream:"
echo ""
git log --oneline upstream/main..HEAD

echo ""
echo "=== Key Differences ==="
echo "Files that differ from upstream:"
git diff --name-status upstream/main

echo ""
echo "=== Pull Request Instructions ==="
echo ""
echo "To create a pull request, follow these steps:"
echo ""
echo "1. Go to: https://github.com/EFForg/rayhunter"
echo "2. Click on 'Pull requests' tab"
echo "3. Click 'New pull request'"
echo "4. Click 'compare across forks'"
echo "5. Set:"
echo "   - base repository: EFForg/rayhunter"
echo "   - base branch: main"
echo "   - head repository: drinkingc0ffee/rayhunter-enhanced"
echo "   - compare branch: $FEATURE_BRANCH"
echo "6. Click 'Create pull request'"
echo ""
echo "=== Alternative: Install GitHub CLI ==="
echo "If you want to create the PR from command line, install GitHub CLI:"
echo "brew install gh"
echo ""
echo "Then authenticate and create the PR with:"
echo "gh pr create --repo EFForg/rayhunter --head drinkingc0ffee:$FEATURE_BRANCH --title 'Rayhunter Enhanced Features' --body 'This PR includes enhanced features for IMSI catcher detection and GPS correlation analysis.'"
echo ""
echo "=== Current Status ==="
echo "Feature branch '$FEATURE_BRANCH' has been created and pushed to your fork."
echo "You can now create the pull request using the instructions above."
echo ""
echo "To switch back to main branch: git checkout main"
echo "To delete the feature branch later: git branch -d $FEATURE_BRANCH" 