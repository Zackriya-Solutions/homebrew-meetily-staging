#!/bin/bash

# Meetily Data Persistence Investigation Script
# This script helps investigate data persistence issues during upgrades

echo "=== Meetily Data Persistence Investigation ==="
echo "Date: $(date)"
echo

echo "1. Checking Meetily installation versions:"
echo "Frontend: $(brew list --cask meetily --versions 2>/dev/null || echo 'Not installed')"
echo "Backend: $(brew list meetily-backend --versions 2>/dev/null || echo 'Not installed')"
echo

echo "2. Checking var directory structure:"
if [ -d "/opt/homebrew/var" ]; then
    echo "Homebrew var directory exists:"
    ls -la /opt/homebrew/var/ | grep meetily || echo "No meetily directories found"
    echo
    
    if [ -d "/opt/homebrew/var/meetily" ]; then
        echo "Meetily var directory contents:"
        ls -la /opt/homebrew/var/meetily/
        echo
        
        echo "Meetily var directory size:"
        du -sh /opt/homebrew/var/meetily/
        echo
    else
        echo "❌ /opt/homebrew/var/meetily directory does not exist!"
        echo
    fi
else
    echo "❌ Homebrew var directory does not exist!"
    echo
fi

echo "3. Checking backend installation directory:"
BACKEND_PREFIX=$(brew --prefix meetily-backend 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "Backend installed at: $BACKEND_PREFIX"
    echo "Backend directory contents:"
    ls -la "$BACKEND_PREFIX/"
    echo
    
    echo "Checking for data symlinks in backend:"
    if [ -d "$BACKEND_PREFIX/backend" ]; then
        find "$BACKEND_PREFIX/backend" -type l -ls 2>/dev/null || echo "No symlinks found"
    fi
    echo
else
    echo "❌ Backend not found or not installed!"
    echo
fi

echo "4. Checking for any meetily processes:"
ps aux | grep meetily | grep -v grep || echo "No meetily processes running"
echo

echo "5. Checking recent Homebrew logs for meetily:"
if [ -f "$(brew --cache)/Logs/meetily-backend" ]; then
    echo "Recent backend installation logs:"
    tail -20 "$(brew --cache)/Logs/meetily-backend"
    echo
fi

echo "6. Checking for backup data:"
if [ -d "/tmp/meetily_backup" ]; then
    echo "Temporary backup found:"
    ls -la /tmp/meetily_backup/
    echo
fi

# Check for any meetily-related files in common locations
echo "7. Searching for meetily data files:"
find /opt/homebrew -name "*meetily*" -type f 2>/dev/null | head -10
echo

echo "=== Investigation Complete ==="
echo "If data persistence is not working:"
echo "1. Check if var directory exists and has correct permissions"
echo "2. Verify symlinks in backend installation"
echo "3. Check if backup/restore scripts are in the formula"
echo "4. Review Homebrew upgrade logs for errors"
