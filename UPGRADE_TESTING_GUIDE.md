# Meetily Upgrade Testing Guide

This guide provides step-by-step instructions for testing the Meetily upgrade process from v0.0.5 (separate frontend/backend) to v0.0.6 (integrated backend) while validating data persistence.



## Test Scripts

### Part 1: `upgrade_test_part1.sh`
- Performs complete system cleanup
- Deploys and installs v0.0.5 (old version with separate backend)
- Starts the backend server
- Opens the frontend app for manual data creation

### Part 2: `upgrade_test_part2.sh`
- Documents existing test data
- Stops the backend server
- Deploys v0.0.6 (new version with integrated backend)
- Performs the upgrade
- Validates that all data was preserved

## How to Run

### Step 1: Run Part 1
```bash
./upgrade_test_part1.sh
```
This will install v0.0.5, start the backend, and open the app.

### Step 2: Create Test Data
Use the opened app to:
- record a meeting
- Save transcripts
- Create summary.

### Step 3: Run Part 2
```bash
./upgrade_test_part2.sh
```
This will upgrade to v0.0.6 and validate that all your data was preserved.

### Step 4: Verify
Open the upgraded app and confirm all your test data is still there:
```bash
open /Applications/meetily-frontend.app
```
