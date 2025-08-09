#!/bin/bash

# Complete Meetily Upgrade Test with Data Persistence Validation
# This script automates the entire upgrade test process

set -e  # Exit on any error

echo "🚀 Starting Meetily Upgrade Test with Data Persistence Validation"
echo "=================================================================="
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

print_status "Uninstalling existing Meetily components..."
brew uninstall --force meetily 2>/dev/null || true
brew uninstall --force meetily-backend 2>/dev/null || true

print_status "Removing var folder data..."
sudo rm -rf /opt/homebrew/var/meetily 2>/dev/null || true

print_status "Removing and re-adding tap..."
brew untap zackriya-solutions/meetily-staging 2>/dev/null || true

echo

# Phase 2: Deploy Old Version
echo "📋 Phase 2: Deploy Old Version"
echo "------------------------------"

print_status "Copying old version files..."
cp meetily-old.rb meetily.rb
cp meetily-backend-old.rb meetily-backend.rb
cp meetily-outside-old.rb Casks/meetily.rb

print_status "Committing old version..."
git add Casks/meetily.rb meetily-backend.rb meetily.rb
git commit -m "Automated test: Deploy old version" || print_warning "No changes to commit"
git push

echo

# Phase 3: Install Old Version
echo "📋 Phase 3: Install Old Version"
echo "-------------------------------"

print_status "Adding tap..."
brew tap zackriya-solutions/meetily-staging

print_status "Installing old version..."
brew install --cask meetily

OLD_FRONTEND_VERSION=$(brew list --cask meetily --versions | awk '{print $2}')
OLD_BACKEND_VERSION=$(brew list meetily-backend --versions | awk '{print $2}')

print_status "Installed versions:"
echo "  Frontend: $OLD_FRONTEND_VERSION"
echo "  Backend: $OLD_BACKEND_VERSION"

echo

# Phase 4: Create Test Data
echo "📋 Phase 4: Create Test Data"
echo "----------------------------"

print_status "Starting backend server..."
meetily-server &
SERVER_PID=$!

print_status "Waiting for server to start..."
sleep 10

# Check if server is running
if curl -s http://localhost:5167/health >/dev/null 2>&1; then
    print_status "Backend server is running ✅"
else
    print_warning "Backend server may not be fully ready, continuing..."
fi

print_status "Opening frontend application..."
open /Applications/meetily-frontend.app

echo
print_warning "⏸️  MANUAL STEP REQUIRED:"
echo "  1. Use the Meetily app to create test data:"
echo "     - Upload an audio file for transcription"
echo "     - Save at least one transcript to the database"
echo "     - Create meeting records with analysis"
echo "  2. Press ENTER when you have created test data..."
read -p "Press ENTER to continue after creating test data: "

print_status "Stopping backend server..."
kill $SERVER_PID 2>/dev/null || true
pkill -f meetily-server 2>/dev/null || true

print_status "Verifying test data was created..."
if [ -d "/opt/homebrew/var/meetily" ]; then
    print_status "Var directory exists ✅"
    
    INITIAL_DATA_SIZE=$(du -sh /opt/homebrew/var/meetily/ | awk '{print $1}')
    print_status "Test data size: $INITIAL_DATA_SIZE"
    
    print_status "Test data inventory:"
    find /opt/homebrew/var/meetily -type f -exec ls -la {} \; 2>/dev/null || print_warning "No files found in var directory"
    
    FILE_COUNT=$(find /opt/homebrew/var/meetily -type f 2>/dev/null | wc -l)
    print_status "Total files created: $FILE_COUNT"
    
    if [ $FILE_COUNT -eq 0 ]; then
        print_error "No test data files found! Make sure you saved data in the app."
        exit 1
    fi
else
    print_error "Var directory not created! ❌"
    exit 1
fi

echo

# Phase 5: Deploy New Version
echo "📋 Phase 5: Deploy New Version"
echo "------------------------------"

print_status "Copying new version files..."
cp meetily-new.rb meetily.rb
cp meetily-backend-new.rb meetily-backend.rb
cp meetily-outside-new.rb Casks/meetily.rb

print_status "Committing new version..."
git add Casks/meetily.rb meetily-backend.rb meetily.rb
git commit -m "Automated test: Deploy new version"
git push

echo

# Phase 6: Upgrade and Validate
echo "📋 Phase 6: Upgrade and Validate"
echo "--------------------------------"

print_status "Updating Homebrew..."
brew update

print_status "Checking for available upgrades..."
brew outdated | grep meetily || print_warning "No meetily upgrades shown in outdated list"

print_status "Upgrading Meetily..."
brew upgrade --cask meetily
brew upgrade meetily-backend

NEW_FRONTEND_VERSION=$(brew list --cask meetily --versions | awk '{print $2}')
NEW_BACKEND_VERSION=$(brew list meetily-backend --versions | awk '{print $2}')

print_status "Upgraded versions:"
echo "  Frontend: $OLD_FRONTEND_VERSION → $NEW_FRONTEND_VERSION"
echo "  Backend: $OLD_BACKEND_VERSION → $NEW_BACKEND_VERSION"

echo

# Phase 7: Validate Data Persistence
echo "📋 Phase 7: Validate Data Persistence"
echo "-------------------------------------"

if [ -d "/opt/homebrew/var/meetily" ]; then
    print_status "Var directory still exists ✅"
    
    FINAL_DATA_SIZE=$(du -sh /opt/homebrew/var/meetily/ | awk '{print $1}')
    print_status "Data size after upgrade: $INITIAL_DATA_SIZE → $FINAL_DATA_SIZE"
    
    # Check if any files still exist
    FINAL_FILE_COUNT=$(find /opt/homebrew/var/meetily -type f 2>/dev/null | wc -l)
    print_status "Files after upgrade: $FILE_COUNT → $FINAL_FILE_COUNT"
    
    if [ $FINAL_FILE_COUNT -eq $FILE_COUNT ]; then
        print_status "All test files preserved ✅"
    elif [ $FINAL_FILE_COUNT -gt 0 ]; then
        print_warning "Some files preserved ($FINAL_FILE_COUNT out of $FILE_COUNT)"
    else
        print_error "No files preserved! Data persistence failed ❌"
    fi
    
    print_status "Final directory structure:"
    ls -la /opt/homebrew/var/meetily/
    
    print_status "Preserved files:"
    find /opt/homebrew/var/meetily/ -type f -exec ls -la {} \; 2>/dev/null || echo "No files found"
    
else
    print_error "Var directory missing after upgrade! ❌"
fi

# Check symlinks
print_status "Verifying symlinks..."
if [ -L "/opt/homebrew/opt/meetily-backend/backend/transcripts" ]; then
    LINK_TARGET=$(readlink /opt/homebrew/opt/meetily-backend/backend/transcripts)
    print_status "Transcripts symlink: $LINK_TARGET ✅"
else
    print_error "Transcripts symlink missing! ❌"
fi

if [ -L "/opt/homebrew/opt/meetily-backend/backend/chroma" ]; then
    LINK_TARGET=$(readlink /opt/homebrew/opt/meetily-backend/backend/chroma)
    print_status "Chroma symlink: $LINK_TARGET ✅"
else
    print_error "Chroma symlink missing! ❌"
fi

echo
echo "🎉 Upgrade Test Complete!"
echo "========================"
echo
echo "📊 Test Summary:"
echo "  Old Version: Frontend $OLD_FRONTEND_VERSION, Backend $OLD_BACKEND_VERSION"
echo "  New Version: Frontend $NEW_FRONTEND_VERSION, Backend $NEW_BACKEND_VERSION"
echo "  Data Size: $INITIAL_DATA_SIZE → $FINAL_DATA_SIZE"
echo
echo "🧹 Cleanup (optional):"
echo "  To clean up test data: sudo rm -rf /opt/homebrew/var/meetily/"
echo "  To uninstall: brew uninstall --force meetily meetily-backend"
