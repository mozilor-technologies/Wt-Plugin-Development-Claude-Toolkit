---
name: wp-symlink-check
description: "Use to verify and create a symlink for the plugin so it is accessible directly under wp-content/plugins/. Run at the start of any plugin development session."
compatibility: "Local Sites (LocalWP) environment on macOS."
---

# WP Symlink Check

## When to use

Run this at the start of any plugin development session to ensure the plugin is accessible directly under `wp-content/plugins/` as a top-level directory.

## Procedure

### 1) Detect the current plugin path

Use the current working directory or the repo root to determine the plugin's real path.

### 2) Check if a matching symlink exists under `wp-content/plugins/`

Look for a symlink in the parent `wp-content/plugins/` directory that points to the plugin's real path:

```bash
ls -la "$(dirname "$(dirname "$PWD")")" | grep "^l"
```

Or check directly:

```bash
ls -la "<wp-content/plugins>/<plugin-folder-name>"
```

- If a valid symlink exists → nothing to do.
- If no symlink exists → proceed to step 3.

### 3) Ask the user

If no symlink is found, ask:

> "No symlink was found for this plugin directly under `wp-content/plugins/`. Would you like me to create one?
>
> Please confirm or provide:
> 1. **Source** (real plugin path) — e.g. the current working directory
> 2. **Symlink target** (where to create it) — e.g. `wp-content/plugins/<plugin-name>`"

### 4) Create the symlink (after user confirms paths)

```bash
ln -s "<source-path>" "<symlink-target-path>"
```

### 5) Verify

```bash
ls -la "<symlink-target-path>"
```

Confirm the output shows a symlink (`->`) pointing to the correct source.
