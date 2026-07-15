# Repository scope

## Purpose

Public, reusable Docker packaging for **upstream SuiteCRM** (pinned version tags).

## Must never contain

| Category | Examples |
|---|---|
| Product / tenant code | Custom CRM modules, branding, business workflows |
| Secrets | Production passwords, API keys, tokens, `.env` with real values |
| PII | Customer names, emails, phone numbers, dumps, screenshots with data |
| Downstream identity | Named product apps that consume this image |

## May contain

- Dockerfile, entrypoint, Apache/PHP config
- Generic engine patches (see `patches/`)
- **Placeholder** demo credentials in docs/examples only (`admin` / `suitecrm` / `root`)
- Docker Hub image name for this packaging project

## Secrets handling

- `.env` is gitignored; never commit real credentials
- CI uses GitHub secrets for Hub login only (`DOCKERHUB_*`), not app passwords
- Install defaults in the entrypoint are for first boot demos; operators must set env vars in production
