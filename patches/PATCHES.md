# SuiteCRM engine patches

**Policy:** All patches to SuiteCRM core, Smarty, PHP defaults, Apache, or install behavior for this image **must** be done in **this repo** (`suitecrm-docker`), never in downstream product repos.

This repository is **product-agnostic**: no tenant branding, custom modules, real credentials, or PII.

Consumers only:
- Pull `markriggins/suitecrm:<pin>`
- Apply product customizations in their own repositories

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

### 003 — History timeline blank text audit values

| | |
|---|---|
| **Symptom** | Timeline “Record Updated” shows enum changes (e.g. Status: Rejected) but **text** fields (e.g. Status Description) are blank |
| **Cause** | `HistoryTimelineDataHandler::queryAuditInfo` only `GROUP_CONCAT(after_value_string)`; Suite stores text audits in `after_value_text` |
| **Fix** | `COALESCE(NULLIF(after_value_string,''), after_value_text)`; unit-separator for GROUP_CONCAT so commas in text do not break PHP `explode` |
| **Files** | `patches/apply-patches.sh` (`patch_003_*`) |

## Adding a new patch

1. Add logic to `patches/apply-patches.sh` (idempotent).
2. Document in this file with symptom / cause / fix.
3. Rebuild and push: `PUSH=1 ./build.sh`
4. Consumers bump nothing if tag is same pin re-push; or bump `SUITECRM_IMAGE_TAG` if you cut a new tag.

## Not patches (belong in consumer apps)

- Custom modules
- Logos / system name
- Tabs, ACL, dashlets, business config
