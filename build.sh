#!/bin/bash
# Build and push markriggins/suitecrm with pinned SuiteCRM version.
set -euo pipefail
cd "$(dirname "$0")"

VERSION="$(grep '^SUITECRM_VERSION=' VERSION | cut -d= -f2)"
# 8.10.1 → 8.10
LINE="${VERSION%.*}"
IMAGE="${IMAGE:-markriggins/suitecrm}"
PUSH="${PUSH:-0}"

# Multi-arch required: Mac (arm64) + DigitalOcean droplet (amd64)
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"

echo "==> Building ${IMAGE}:${VERSION} (SuiteCRM ${VERSION}) platforms=${PLATFORMS}"
if [[ "${PUSH}" == "1" ]]; then
  docker buildx build \
    --platform "${PLATFORMS}" \
    --build-arg "SUITECRM_VERSION=${VERSION}" \
    -t "${IMAGE}:${VERSION}" \
    -t "${IMAGE}:${LINE}" \
    --push \
    .
  echo "Pushed ${IMAGE}:${VERSION} and ${IMAGE}:${LINE}"
else
  docker buildx build \
    --platform "${PLATFORMS}" \
    --build-arg "SUITECRM_VERSION=${VERSION}" \
    -t "${IMAGE}:${VERSION}" \
    -t "${IMAGE}:${LINE}" \
    --load \
    . 2>/dev/null || docker build \
    --build-arg "SUITECRM_VERSION=${VERSION}" \
    -t "${IMAGE}:${VERSION}" \
    -t "${IMAGE}:${LINE}" \
    .
  echo "Built locally (set PUSH=1 for multi-arch Hub push)."
fi
