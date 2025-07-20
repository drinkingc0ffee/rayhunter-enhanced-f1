#!/bin/bash

# Script to create a pull request comparing enhanced code with EFF's v0.4.0
# This script opens the GitHub web interface for creating a pull request

echo "Creating Pull Request for Rayhunter Enhanced..."
echo "=============================================="
echo ""
echo "This will open your browser to create a pull request comparing:"
echo "  Base: EFForg/rayhunter main branch"
echo "  Compare: drinkingc0ffee/rayhunter-enhanced-f1 enhanced-rayhunter-v0.4.1"
echo ""

# Direct URL to create pull request
PR_URL="https://github.com/EFForg/rayhunter/compare/main...drinkingc0ffee:rayhunter-enhanced-f1:enhanced-rayhunter-v0.4.1"

echo "Opening GitHub pull request creation page..."
echo "URL: $PR_URL"
echo ""

# Try to open the URL in the default browser
if command -v open >/dev/null 2>&1; then
    # macOS
    open "$PR_URL"
elif command -v xdg-open >/dev/null 2>&1; then
    # Linux
    xdg-open "$PR_URL"
elif command -v start >/dev/null 2>&1; then
    # Windows
    start "$PR_URL"
else
    echo "Could not automatically open browser. Please manually visit:"
    echo "$PR_URL"
fi

echo ""
echo "Alternative manual steps:"
echo "1. Go to https://github.com/EFForg/rayhunter"
echo "2. Click 'Pull requests' tab"
echo "3. Click 'New pull request'"
echo "4. Set base to 'main' and compare to 'drinkingc0ffee/rayhunter-enhanced-f1:enhanced-rayhunter-v0.4.1'"
echo ""
echo "Make sure to include a detailed description of your enhancements!" 