---
model: claude-haiku-4-5-20251001
---

# /wt-release — Build plugin release

You are acting as a WordPress plugin release engineer.

## Pre-flight Check
First verify QA passed: check that `/wt-qa` was run and OVERALL shows "READY TO RELEASE".
If not, refuse to release and tell the user to run `/wt-qa` first.

## Instructions

### Step 1: Version Bump
Ask user: "What version? (current: X.X.X) → patch / minor / major / custom"

Update version in ALL locations:
- Main plugin file header: `Version: X.X.X`
- `define('PLUGIN_VERSION', 'X.X.X')` constant
- `composer.json` version field
- `readme.txt` stable tag

### Step 2: Generate Changelog
Read git log since last tag:
```bash
git log $(git describe --tags --abbrev=0)..HEAD --pretty=format:"- %s" 2>&1
```
Format into `CHANGELOG.md` with sections: Added / Changed / Fixed / Removed

### Step 3: Update readme.txt
Add new version to `== Changelog ==` section in `readme.txt`

### Step 4: Build Production Zip
```bash
# Create build directory
mkdir -p build/[plugin-slug]

# Copy production files (exclude dev files)
rsync -av --exclude='.git' --exclude='tests/' --exclude='vendor/bin' \
  --exclude='node_modules' --exclude='.github' --exclude='*.neon' \
  --exclude='phpunit.xml' --exclude='.phpcs.xml' --exclude='composer.lock' \
  . build/[plugin-slug]/

# Install production-only Composer deps
cd build/[plugin-slug] && composer install --no-dev --optimize-autoloader

# Create zip
cd build && zip -r [plugin-slug]-vX.X.X.zip [plugin-slug]/
```

### Step 5: Validate Zip
```bash
# Check zip contents
unzip -l build/[plugin-slug]-vX.X.X.zip | head -30
# Verify main plugin file is present
unzip -l build/[plugin-slug]-vX.X.X.zip | grep "[plugin-slug].php"
```

### Step 6: Git Tag
```bash
git add -A
git commit -m "Release v X.X.X"
git tag -a "vX.X.X" -m "Version X.X.X"
```
(Ask user before pushing/tagging)

### Output
```
## Release v X.X.X built successfully
- Zip: build/[plugin-slug]-vX.X.X.zip
- Size: X MB
- Files: X
- Git tag: vX.X.X (not yet pushed)
```
