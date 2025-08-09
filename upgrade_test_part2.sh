#!/bin/bash

# Meetily Upgrade Test - Part 2: Upgrade and Validate Data Persistence
# This script performs the upgrade and validates that data was preserved

set -e  # Exit on any error

echo "🚀 Meetily Upgrade Test - Part 2: Upgrade and Validation"
echo "========================================================"
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

# Check if Part 1 was run
if [ ! -f "/tmp/meetily_test_old_frontend_version" ] || [ ! -f "/tmp/meetily_test_old_backend_version" ]; then
    print_error "Part 1 has not been run! Please run upgrade_test_part1.sh first."
    exit 1
fi

# Load old versions
OLD_FRONTEND_VERSION=$(cat /tmp/meetily_test_old_frontend_version)
OLD_BACKEND_VERSION=$(cat /tmp/meetily_test_old_backend_version)

echo "📋 Continuing from Part 1"
echo "-------------------------"
print_status "Old versions: Frontend $OLD_FRONTEND_VERSION, Backend $OLD_BACKEND_VERSION"

# Phase 5: Stop Server and Document Test Data
echo
echo "📋 Phase 5: Document Test Data"
echo "------------------------------"

print_status "Stopping backend server..."
if [ -f "/tmp/meetily_test_server_pid" ]; then
    SERVER_PID=$(cat /tmp/meetily_test_server_pid)
    kill $SERVER_PID 2>/dev/null || true
    rm /tmp/meetily_test_server_pid
fi
pkill -f meetily-server 2>/dev/null || true

print_status "Documenting test data before upgrade..."

# Check backend directory for data
BACKEND_DIR="/opt/homebrew/opt/meetily-backend/backend"
if [ -d "$BACKEND_DIR" ]; then
    print_status "Backend directory exists ✅"
    
    echo "Files in backend directory:"
    ls -la "$BACKEND_DIR/"
    
    # Look for database files
    DB_FILES=$(find "$BACKEND_DIR" -name "*.db" -o -name "*.sqlite*" 2>/dev/null || true)
    if [ -n "$DB_FILES" ]; then
        print_status "Database files found:"
        echo "$DB_FILES" | while read -r file; do
            if [ -f "$file" ]; then
                SIZE=$(ls -lh "$file" | awk '{print $5}')
                echo "  - $(basename "$file"): $SIZE"
            fi
        done
        
        # Count total files
        INITIAL_FILE_COUNT=$(find "$BACKEND_DIR" -type f 2>/dev/null | wc -l | xargs)
        INITIAL_DB_SIZE=$(du -sh "$BACKEND_DIR" 2>/dev/null | awk '{print $1}' || echo "0B")
        
        print_status "Initial data state:"
        echo "  - Total files: $INITIAL_FILE_COUNT"
        echo "  - Directory size: $INITIAL_DB_SIZE"
        
        # Save for comparison
        echo "$INITIAL_FILE_COUNT" > /tmp/meetily_test_initial_file_count
        echo "$INITIAL_DB_SIZE" > /tmp/meetily_test_initial_size
    else
        print_warning "No database files found in backend directory"
        echo "0" > /tmp/meetily_test_initial_file_count
        echo "0B" > /tmp/meetily_test_initial_size
    fi
else
    print_error "Backend directory not found!"
    exit 1
fi

# Check var directory
if [ -d "/opt/homebrew/var/meetily" ]; then
    print_status "Var directory exists (data persistence enabled) ✅"
    VAR_SIZE=$(du -sh /opt/homebrew/var/meetily/ 2>/dev/null | awk '{print $1}' || echo "0B")
    echo "  - Var directory size: $VAR_SIZE"
else
    print_warning "Var directory does not exist (data persistence not enabled in old version)"
fi

echo

# Phase 6: Deploy New Version
echo "📋 Phase 6: Deploy New Version"
echo "------------------------------"

print_status "Copying new version files..."
cp meetily-new.rb meetily.rb
cp meetily-backend-new.rb meetily-backend.rb
cp meetily-outside-new.rb Casks/meetily.rb

print_status "Committing new version..."
git add Casks/meetily.rb meetily-backend.rb meetily.rb
if git commit -m "Automated test: Deploy new version"; then
    print_status "New version committed successfully"
else
    print_warning "No changes to commit (new version may already be deployed)"
fi
git push

echo

# Phase 7: Upgrade and Validate
echo "📋 Phase 7: Upgrade and Validate"
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

# Phase 8: Validate Data Persistence
echo "📋 Phase 8: Validate Data Persistence"
echo "-------------------------------------"

INITIAL_FILE_COUNT=$(cat /tmp/meetily_test_initial_file_count)
INITIAL_DB_SIZE=$(cat /tmp/meetily_test_initial_size)

# Check backend directory after upgrade
if [ -d "$BACKEND_DIR" ]; then
    print_status "Backend directory still exists ✅"
    
    # Check for database files
    FINAL_DB_FILES=$(find "$BACKEND_DIR" -name "*.db" -o -name "*.sqlite*" 2>/dev/null || true)
    if [ -n "$FINAL_DB_FILES" ]; then
        print_status "Database files still exist after upgrade:"
        echo "$FINAL_DB_FILES" | while read -r file; do
            if [ -f "$file" ]; then
                SIZE=$(ls -lh "$file" | awk '{print $5}')
                echo "  - $(basename "$file"): $SIZE"
            fi
        done
        
        FINAL_FILE_COUNT=$(find "$BACKEND_DIR" -type f 2>/dev/null | wc -l | xargs)
        FINAL_DB_SIZE=$(du -sh "$BACKEND_DIR" 2>/dev/null | awk '{print $1}' || echo "0B")
        
        print_status "Final data state:"
        echo "  - Total files: $INITIAL_FILE_COUNT → $FINAL_FILE_COUNT"
        echo "  - Directory size: $INITIAL_DB_SIZE → $FINAL_DB_SIZE"
        
        if [ "$FINAL_FILE_COUNT" -ge "$INITIAL_FILE_COUNT" ]; then
            print_status "Data preserved during upgrade ✅"
        else
            print_error "Some data may have been lost during upgrade ❌"
        fi
    else
        print_error "Database files missing after upgrade! ❌"
    fi
else
    print_error "Backend directory missing after upgrade! ❌"
fi

# Check var directory after upgrade
if [ -d "/opt/homebrew/var/meetily" ]; then
    print_status "Var directory exists after upgrade (data persistence working) ✅"
    
    VAR_FILES=$(find /opt/homebrew/var/meetily -type f 2>/dev/null | wc -l | xargs)
    VAR_SIZE=$(du -sh /opt/homebrew/var/meetily/ 2>/dev/null | awk '{print $1}' || echo "0B")
    
    print_status "Var directory contents:"
    ls -la /opt/homebrew/var/meetily/
    echo "  - Files in var: $VAR_FILES"
    echo "  - Var size: $VAR_SIZE"
    
    # Check symlinks
    print_status "Checking symlinks..."
    if [ -L "$BACKEND_DIR/transcripts" ]; then
        LINK_TARGET=$(readlink "$BACKEND_DIR/transcripts")
        print_status "Transcripts symlink: $LINK_TARGET ✅"
    else
        print_warning "Transcripts symlink not found"
    fi
    
    if [ -L "$BACKEND_DIR/chroma" ]; then
        LINK_TARGET=$(readlink "$BACKEND_DIR/chroma")
        print_status "Chroma symlink: $LINK_TARGET ✅"
    else
        print_warning "Chroma symlink not found"
    fi
else
    print_warning "Var directory still does not exist after upgrade"
fi

echo
echo "🎉 Upgrade Test Complete!"
echo "========================"
echo
echo "📊 Test Summary:"
echo "  - Old Version: Frontend $OLD_FRONTEND_VERSION, Backend $OLD_BACKEND_VERSION"
echo "  - New Version: Frontend $NEW_FRONTEND_VERSION, Backend $NEW_BACKEND_VERSION"
echo "  - Data Files: $INITIAL_FILE_COUNT → $FINAL_FILE_COUNT"
echo "  - Data Size: $INITIAL_DB_SIZE → $FINAL_DB_SIZE"
echo
echo "🧹 Cleanup:"
print_status "Removing temporary test files..."
rm -f /tmp/meetily_test_*

echo
echo "  To clean up completely:"
echo "    sudo rm -rf /opt/homebrew/var/meetily/"
echo "    brew uninstall --force meetily meetily-backend"
echo
echo "✅ Test completed successfully!"
