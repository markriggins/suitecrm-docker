# suitecrm-docker

Public Docker image for **SuiteCRM 8.10.x**, pinned (not floating `latest` for app version).

**Image:** [markriggins/suitecrm](https://hub.docker.com/r/markriggins/suitecrm)

| Tag | Meaning |
|---|---|
| `8.10.1` | Exact app pin (prefer this) |
| `8.10` | Same build; minor line alias |
| `latest` | Optional; may lag — prefer version tags |

## Quick start

```bash
docker run -d --name suitecrm-db \
  -e MYSQL_DATABASE=suitecrm \
  -e MYSQL_USER=suitecrm \
  -e MYSQL_PASSWORD=suitecrm \
  -e MYSQL_ROOT_PASSWORD=root \
  mariadb:11.4

docker run -d --name suitecrm \
  -p 8080:80 \
  -e SUITECRM_DATABASE_HOST=suitecrm-db \
  -e SUITECRM_DATABASE_NAME=suitecrm \
  -e SUITECRM_DATABASE_USER=suitecrm \
  -e SUITECRM_DATABASE_PASSWORD=suitecrm \
  -e SUITECRM_HOST=localhost \
  -e SUITECRM_EXTERNAL_HTTP_PORT_NUMBER=8080 \
  -e SUITECRM_USERNAME=admin \
  -e SUITECRM_PASSWORD=admin \
  --link suitecrm-db:suitecrm-db \
  -v suitecrm_data:/var/www/html \
  markriggins/suitecrm:8.10.1
```

First boot runs CLI install. Log line: `setup finished`.

## Build & push

```bash
./build.sh
# or:
docker build -t markriggins/suitecrm:8.10.1 -t markriggins/suitecrm:8.10 .
docker push markriggins/suitecrm:8.10.1
docker push markriggins/suitecrm:8.10
```

## Env vars

| Variable | Default | Notes |
|---|---|---|
| `SUITECRM_DATABASE_HOST` | `db` | |
| `SUITECRM_DATABASE_PORT_NUMBER` | `3306` | |
| `SUITECRM_DATABASE_NAME` | `suitecrm` | |
| `SUITECRM_DATABASE_USER` | `suitecrm` | |
| `SUITECRM_DATABASE_PASSWORD` | `suitecrm` | |
| `SUITECRM_USERNAME` | `admin` | First install only |
| `SUITECRM_PASSWORD` | `admin` | First install only |
| `SUITECRM_EMAIL` | `admin@localhost` | |
| `SUITECRM_HOST` | `localhost` | Host only, no scheme |
| `SUITECRM_ENABLE_HTTPS` | `no` | |
| `SUITECRM_EXTERNAL_HTTP_PORT_NUMBER` | `80` | Used in `site_url` |
| `SUITECRM_EXTERNAL_HTTPS_PORT_NUMBER` | `443` | |

Volume: `/var/www/html` (full app tree after seed).

## Not included

Product branding, custom modules (e.g. Ojenta Chapters). Layer those in the consuming project.

## License

SuiteCRM is AGPL. This packaging is provided as-is.
