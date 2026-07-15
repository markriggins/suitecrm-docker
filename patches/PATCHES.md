# SuiteCRM engine patches

**Policy:** All patches to SuiteCRM core, Smarty, PHP defaults, Apache, or install behavior for this image **must** be done in **this repo** (`suitecrm-docker`), never in Ojenta or other consumers.

Consumers (e.g. Ojenta Guild) only:
- Pull `markriggins/suitecrm:<pin>`
- Apply **product** customizations (custom modules, branding) in their own repo

## How patches are applied

| When | What |
|---|---|
| **Image build** | `Dockerfile` runs `patches/apply-patches.sh` on `/opt/suitecrm-seed` |
| **Container start** | `docker-entrypoint.sh` runs the same script on `/var/www/html` (volume) so existing data volumes pick up new patches after image upgrade |

`apply-patches.sh` is **idempotent**.

## Active patches

### 001 — Smarty `file_exists` (SuiteCRM 8.10.x)

| | |
|---|---|
| **Symptom** | `Deprecated: Using unregistered function "file_exists" in a template...` |
| **Cause** | Core `themes/suite8/tpls/header.tpl` uses `{if file_exists(...)}`; Smarty 5 no longer auto-exposes PHP functions |
| **Fix** | Register `file_exists` as modifier + in `registerPHPFunctions`; ship `modifier.file_exists.php` under `custom/include/Smarty/plugins` |
| **Files** | `patches/apply-patches.sh` (`patch_001_*`), `patches/001-smarty-file_exists/` |

### 002 — PHP error display (image)

| | |
|---|---|
| **Fix** | `display_errors=Off`, log deprecations only — in `Dockerfile` `suitecrm.ini` |
| **Why** | Deprecations from upstream must not break HTML layout |

## Adding a new patch

1. Add logic to `patches/apply-patches.sh` (idempotent).
2. Document in this file with symptom / cause / fix.
3. Rebuild and push: `PUSH=1 ./build.sh`
4. Consumers bump nothing if tag is same pin re-push; or bump `SUITECRM_IMAGE_TAG` if you cut a new tag.

## Not patches (belong in consumer)

- Custom modules (e.g. OG_Chapters)
- Logos / system name
- Tabs, ACL, dashlets product config
