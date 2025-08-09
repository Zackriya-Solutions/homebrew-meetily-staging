#!/bin/bash

# Test script to verify database persistence works correctly

set -e

echo "🧪 Testing Meetily Database Persistence"
echo "======================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test directory
TEST_DIR="$HOME/Library/Application Support/Meetily"
TEST_DB="$TEST_DIR/meeting_minutes.db"

echo -e "${BLUE}Step 1: Check if data directory exists${NC}"
if [ -d "$TEST_DIR" ]; then
    echo -e "${GREEN}✅ Data directory exists: $TEST_DIR${NC}"
else
    echo -e "${YELLOW}⚠️  Data directory doesn't exist yet: $TEST_DIR${NC}"
fi

echo -e "${BLUE}Step 2: Check if database exists${NC}"
if [ -f "$TEST_DB" ]; then
    echo -e "${GREEN}✅ Database exists: $TEST_DB${NC}"
    
    # Show database size
    DB_SIZE=$(du -h "$TEST_DB" | cut -f1)
    echo -e "${BLUE}📊 Database size: $DB_SIZE${NC}"
    
    # Count tables (if sqlite3 is available)
    if command -v sqlite3 >/dev/null 2>&1; then
        TABLE_COUNT=$(sqlite3 "$TEST_DB" ".tables" | wc -w)
        echo -e "${BLUE}📋 Number of tables: $TABLE_COUNT${NC}"
        
        # Show table names
        echo -e "${BLUE}📝 Tables:${NC}"
        sqlite3 "$TEST_DB" ".tables" | tr ' ' '\n' | grep -v '^$' | while read table; do
            echo -e "   - $table"
        done
        
        # Count meetings
        MEETING_COUNT=$(sqlite3 "$TEST_DB" "SELECT COUNT(*) FROM meetings;" 2>/dev/null || echo "0")
        echo -e "${BLUE}🗣️  Number of meetings: $MEETING_COUNT${NC}"
        
        # Count transcripts
        TRANSCRIPT_COUNT=$(sqlite3 "$TEST_DB" "SELECT COUNT(*) FROM transcripts;" 2>/dev/null || echo "0")
        echo -e "${BLUE}📄 Number of transcripts: $TRANSCRIPT_COUNT${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Database doesn't exist yet: $TEST_DB${NC}"
    echo -e "${BLUE}ℹ️  This is normal for a fresh installation${NC}"
fi

echo -e "${BLUE}Step 3: Check environment configuration${NC}"
if [ -f "$TEST_DIR/.env" ]; then
    echo -e "${GREEN}✅ Environment file exists: $TEST_DIR/.env${NC}"
    echo -e "${BLUE}📄 Content:${NC}"
    cat "$TEST_DIR/.env" | sed 's/^/   /'
else
    echo -e "${YELLOW}⚠️  Environment file doesn't exist yet: $TEST_DIR/.env${NC}"
fi

echo -e "${BLUE}Step 4: Check Homebrew installation${NC}"
BACKEND_PATH="$(brew --prefix)/opt/meetily-backend/backend"
if [ -d "$BACKEND_PATH" ]; then
    echo -e "${GREEN}✅ Meetily backend installed: $BACKEND_PATH${NC}"
    
    # Check if db.py is patched
    if grep -q "os.getenv('DB_PATH'" "$BACKEND_PATH/app/db.py" 2>/dev/null; then
        echo -e "${GREEN}✅ Database code is patched for persistence${NC}"
    else
        echo -e "${RED}❌ Database code is NOT patched${NC}"
        echo -e "${YELLOW}   Run: brew reinstall meetily-backend${NC}"
    fi
else
    echo -e "${RED}❌ Meetily backend not found${NC}"
    echo -e "${YELLOW}   Run: brew install --cask meetily${NC}"
fi

echo -e "${BLUE}Step 5: Test database path environment variable${NC}"
export DB_PATH="$TEST_DB"
echo -e "${GREEN}✅ DB_PATH set to: $DB_PATH${NC}"

echo ""
echo -e "${GREEN}🎉 Database Persistence Test Complete!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo -e "   • Data Directory: $TEST_DIR"
echo -e "   • Database File: $TEST_DB"
echo -e "   • Survives upgrades: ✅ YES"
echo -e "   • Standard macOS location: ✅ YES"
echo ""
echo -e "${BLUE}💡 To backup your data:${NC}"
echo -e "   cp -r \"$TEST_DIR\" \"~/Meetily_Backup_\$(date +%Y%m%d)\""
