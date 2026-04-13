# Release Agent Specification

## Purpose
Autonomous agent for release and distribution phase.

Bumps version, creates release zip file, tags release, and prepares for distribution.

## Task
1. Load plugin CLAUDE.md (plugin slug, min WP/WC versions)
2. Check: Is PR merged to main? (verify Bitbucket status)
   - If not: BLOCK, ask to merge PR first
3. Load current version from plugin-header.php:
   ```php
   * Version: 1.2.3
   ```
4. Ask user: "Bump to which version?"
   - Options: major (1.3.0) / minor (1.2.4) / patch (1.2.3-patch)
   - Or: manual version entry
5. Update version in:
   - Main plugin file header (Version: X.Y.Z)
   - composer.json (if exists)
   - README.txt (if exists)
   - CHANGELOG.md (add release date + changes)
6. Create changelog entry:
   - Date: today
   - Version: X.Y.Z
   - Summary of changes from commit messages
7. Commit version bump:
   ```bash
   git commit -m "Release: v1.2.3"
   ```
8. Create git tag:
   ```bash
   git tag -a v1.2.3 -m "Release v1.2.3"
   git push origin v1.2.3
   ```
9. Build release zip:
   ```bash
   # Create: releases/{plugin-slug}-v1.2.3.zip
   # Exclude: .git, vendor, tests, node_modules, build files
   # Include: readme, license, changelog, all plugin files
   ```
10. Generate release notes:
    - Version
    - Release date
    - Features added
    - Bugs fixed
    - Security updates (if any)
11. Return:
    - Zip file location
    - Git tag created
    - Ready for distribution
12. Save state: phase="release", status="completed", version="X.Y.Z"

## Outputs
- Version bumped in all files
- Commit made for version bump
- Git tag created (v1.2.3)
- Release zip file created
- Release notes generated
- Changelog updated

## Success Criteria
✅ Version updated everywhere
✅ Git tag created
✅ Zip file ready for download
✅ Release notes complete
✅ Changelog updated
✅ No sensitive files in zip (no .git, node_modules, etc.)

## Failure Handling
❌ PR not merged → BLOCK, ask to merge to main first
❌ Uncommitted changes → Ask to commit first
❌ Version already exists → Suggest next version
❌ Zip creation fails → Show error, suggest manual creation

## Version Semantics
- **Major** (1.0.0 → 2.0.0): Breaking changes, major features
- **Minor** (1.0.0 → 1.1.0): New features, backward compatible
- **Patch** (1.0.0 → 1.0.1): Bug fixes only

## Release Files
```
plugin-name/
├── releases/
│   ├── my-plugin-v1.2.3.zip
│   ├── my-plugin-v1.2.2.zip
│   └── ...
├── CHANGELOG.md (updated)
└── readme.txt (version updated)
```

## Zip Contents (exclude)
```
❌ Excluded:
  .git/
  .github/
  vendor/
  node_modules/
  tests/
  build/
  *.zip
  .DS_Store

✅ Included:
  *.php
  readme.txt
  LICENSE
  CHANGELOG.md
  assets/
  includes/
  composer.json
```

## Tools Needed
- Git (create tag, commit)
- File system (update version, create zip)
- Bash (zip creation, file operations)

## Agent Type
Use general-purpose agent with tools: git, bash, file operations, version parsing
