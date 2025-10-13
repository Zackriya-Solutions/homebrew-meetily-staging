#!/bin/bash

# Meetily Upgrade Test - Part 1: Setup and Data Creation
# This script sets up the old version and prepares for manual data creation

set -e  # Exit on any error

echo "🚀 Meetily Upgrade Test - Part 1: Setup and Data Creation"
echo "========================================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Phase 1: Complete System Cleanup
echo "📋 Phase 1: Complete System Cleanup"
echo "-----------------------------------"

print_status "Uninstalling existing Meetily frontend..."
brew uninstall --force meetily 2>/dev/null || true

# NOTE: Commenting out var folder cleanup to preserve existing data during upgrade testing
# print_status "Removing var folder data..."
# sudo rm -rf /opt/homebrew/var/meetily 2>/dev/null || true

print_status "Removing and re-adding tap..."
brew untap zackriya-solutions/meetily-staging 2>/dev/null || true

print_status "Removing conflicting tap to avoid formula ambiguity..."
brew untap zackriya-solutions/meetily 2>/dev/null || true

echo

# Phase 2: Deploy Old Version (0.0.5)
echo "📋 Phase 2: Deploy Old Version (0.0.5)"
echo "--------------------------------------"

print_status "Copying old version files..."
cp meetily-new.rb meetily.rb
cp meetily-new.rb Casks/meetily.rb

print_status "Committing old version..."
git add Casks/meetily.rb meetily.rb
git commit -m "Automated test: Deploy old version" || print_warning "No changes to commit"
git push

echo

# Phase 3: Install Old Version
echo "📋 Phase 3: Install Old Version"
echo "-------------------------------"

print_status "Adding tap..."
brew tap zackriya-solutions/meetily-staging

print_status "Installing old version..."
brew install --cask zackriya-solutions/meetily-staging/meetily

OLD_FRONTEND_VERSION=$(brew list --cask zackriya-solutions/meetily-staging/meetily --versions | awk '{print $2}')

print_status "Installed versions:"
echo "  Frontend: $OLD_FRONTEND_VERSION"

# Save version for Part 2
echo "$OLD_FRONTEND_VERSION" > /tmp/meetily_test_old_frontend_version

echo

# Phase 4: Start Backend Server
echo "📋 Phase 4: Start Backend Server"
echo "--------------------------------"

print_status "Starting backend server..."
meetily-server &
SERVER_PID=$!

# Save PID for later cleanup
echo "$SERVER_PID" > /tmp/meetily_test_server_pid

print_status "Waiting for server to start..."
sleep 10

# Check if server is running
if curl -s http://localhost:5167/health >/dev/null 2>&1; then
    print_status "Backend server is running ✅"
else
    print_warning "Backend server may not be fully ready, but continuing..."
fi

print_status "Opening frontend application..."
open /Applications/meetily-frontend.app

echo
echo "🎯 NEXT STEPS:"
echo "============="
echo
print_warning "📱 Use the Meetily app to create test data:"
echo "  1. Upload an audio file for transcription"
echo "  2. Save at least one transcript to the database"
echo "  3. Create meeting records with analysis"
echo "  4. Note what data you created for validation later"
echo
print_status "✨ When you're done creating test data, run:"
echo "     ./upgrade_test_part2.sh"
echo
print_warning "🔧 Backend server is running in the background (PID: $SERVER_PID)"
echo "   It will be automatically stopped when you run Part 2"
echo
echo "📊 Current Status:"
echo "  - Old version (0.0.5) installed: Frontend $OLD_FRONTEND_VERSION"
echo "  - Backend server running on http://localhost:5167"
echo "  - Frontend app opened for data creation"
echo
echo "✅ Part 1 Complete! Ready for data creation."
