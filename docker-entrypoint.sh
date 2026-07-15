#!/bin/bash
# Seed SuiteCRM onto volume, CLI-install once, run Apache.
# Generic image — no product branding (consumers rebrand).
set -euo pipefail

APP_ROOT="${SUITECRM_APP_ROOT:-/var/www/html}"
SEED_ROOT="/opt/suitecrm-seed"
LEGACY="${APP_ROOT}/public/legacy"
MARKER="${APP_ROOT}/.suitecrm-installed"

log() { echo "[suitecrm] $*"; }

if [[ ! -f "${APP_ROOT}/bin/console" ]]; then
  log "Seeding SuiteCRM ${SUITECRM_VERSION:-unknown} into ${APP_ROOT}..."
  mkdir -p "${APP_ROOT}"
  rsync -a "${SEED_ROOT}/" "${APP_ROOT}/"
fi

if [[ -f "${SEED_ROOT}/.suitecrm-version" ]]; then
  cp "${SEED_ROOT}/.suitecrm-version" "${APP_ROOT}/.suitecrm-version"
fi

# Re-apply engine patches on every start (idempotent; upgrades existing volumes)
if [[ -x /opt/suitecrm-patches/apply-patches.sh ]]; then
  /opt/suitecrm-patches/apply-patches.sh "${APP_ROOT}"
fi

mkdir -p \
  "${APP_ROOT}/cache" \
  "${APP_ROOT}/logs" \
  "${LEGACY}/cache" \
  "${LEGACY}/upload" \
  "${LEGACY}/custom" \
  "${LEGACY}/custom/modules"

DB_HOST="${SUITECRM_DATABASE_HOST:-db}"
DB_PORT="${SUITECRM_DATABASE_PORT_NUMBER:-3306}"
DB_NAME="${SUITECRM_DATABASE_NAME:-suitecrm}"
DB_USER="${SUITECRM_DATABASE_USER:-suitecrm}"
DB_PASS="${SUITECRM_DATABASE_PASSWORD:-suitecrm}"
ADMIN_USER="${SUITECRM_USERNAME:-admin}"
ADMIN_PASS="${SUITECRM_PASSWORD:-admin}"
ADMIN_EMAIL="${SUITECRM_EMAIL:-admin@localhost}"

SITE_HOST="${SUITECRM_HOST:-localhost}"
if [[ "${SUITECRM_ENABLE_HTTPS:-no}" == "yes" ]]; then
  SITE_SCHEME="https"
  EXT_PORT="${SUITECRM_EXTERNAL_HTTPS_PORT_NUMBER:-443}"
  if [[ "${EXT_PORT}" == "443" ]]; then SITE_URL="${SITE_SCHEME}://${SITE_HOST}"
  else SITE_URL="${SITE_SCHEME}://${SITE_HOST}:${EXT_PORT}"; fi
else
  SITE_SCHEME="http"
  EXT_PORT="${SUITECRM_EXTERNAL_HTTP_PORT_NUMBER:-80}"
  if [[ "${EXT_PORT}" == "80" ]]; then SITE_URL="${SITE_SCHEME}://${SITE_HOST}"
  else SITE_URL="${SITE_SCHEME}://${SITE_HOST}:${EXT_PORT}"; fi
fi

log "Waiting for database ${DB_HOST}:${DB_PORT}..."
for i in $(seq 1 90); do
  if php -r "try { new PDO('mysql:host=${DB_HOST};port=${DB_PORT}', '${DB_USER}', '${DB_PASS}'); exit(0);} catch (Exception \$e) { exit(1);}" 2>/dev/null; then
    break
  fi
  sleep 2
  if [[ "$i" -eq 90 ]]; then
    log "ERROR: database not reachable"
    exit 1
  fi
done
log "Database is up."

if [[ ! -f "${MARKER}" ]] && [[ ! -f "${LEGACY}/config.php" ]]; then
  log "Running SuiteCRM CLI install (site_url=${SITE_URL})..."
  cd "${APP_ROOT}"
  chmod +x bin/console || true
  set +e
  ./bin/console suitecrm:app:install \
    -u "${ADMIN_USER}" \
    -p "${ADMIN_PASS}" \
    -U "${DB_USER}" \
    -P "${DB_PASS}" \
    -H "${DB_HOST}" \
    -N "${DB_NAME}" \
    -S "${SITE_URL}" \
    -d "no" \
    --sys_check_option true
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    ./bin/console suitecrm:app:install \
      -u "${ADMIN_USER}" \
      -p "${ADMIN_PASS}" \
      -U "${DB_USER}" \
      -P "${DB_PASS}" \
      -H "${DB_HOST}" \
      -N "${DB_NAME}" \
      -S "${SITE_URL}" \
      -d "no"
  fi

  if [[ -n "${ADMIN_EMAIL}" ]]; then
    php -r "
      try {
        \$pdo = new PDO('mysql:host=${DB_HOST};port=${DB_PORT};dbname=${DB_NAME}', '${DB_USER}', '${DB_PASS}');
        \$pdo->prepare('UPDATE users SET email1=? WHERE user_name=?')->execute(['${ADMIN_EMAIL}', '${ADMIN_USER}']);
      } catch (Throwable \$e) {}
    " 2>/dev/null || true
  fi

  touch "${MARKER}"
  log "Install complete."
else
  log "Existing install detected."
  if [[ -f "${LEGACY}/config.php" ]]; then
    php -r "
      \$f='${LEGACY}/config.php';
      \$c=file_get_contents(\$f);
      \$want='${SITE_URL}';
      \$c2=preg_replace(\"/'site_url'\\s*=>\\s*'[^']*'/\", \"'site_url' => '\$want'\", \$c, 1, \$n);
      if (\$n) { file_put_contents(\$f, \$c2); }
    " 2>/dev/null || true
  fi
fi

chown -R www-data:www-data "${APP_ROOT}" || true
find "${APP_ROOT}" -type d -exec chmod 2775 {} \; 2>/dev/null || true
find "${APP_ROOT}" -type f -exec chmod 0664 {} \; 2>/dev/null || true
chmod +x "${APP_ROOT}/bin/console" 2>/dev/null || true
chmod -R 777 "${APP_ROOT}/cache" "${LEGACY}/cache" 2>/dev/null || true

if [[ -d /etc/cron.d ]]; then
  echo "* * * * * www-data cd ${APP_ROOT} && php -f public/legacy/cron.php > /dev/null 2>&1" > /etc/cron.d/suitecrm || true
  chmod 0644 /etc/cron.d/suitecrm 2>/dev/null || true
  service cron start 2>/dev/null || true
fi

log "setup finished (SuiteCRM ${SUITECRM_VERSION:-unknown})"
log "Listening on :80  site_url=${SITE_URL}"

exec "$@"
