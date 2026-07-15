#!/bin/bash
# Build and push markriggins/suitecrm with pinned SuiteCRM version.
set -euo pipefail
cd "$(dirname "$0")"

VERSION="$(grep '^SUITECRM_VERSION=' VERSION | cut -d= -f2)"
# 8.10.1 → 8.10
LINE="${VERSION%.*}"
IMAGE="${IMAGE:-markriggins/suitecrm}"
PUSH="${PUSH:-0}"

echo "==> Building ${IMAGE}:${VERSION} (SuiteCRM ${VERSION})"
docker build \
  --build-arg "SUITECRM_VERSION=${VERSION}" \
  -t "${IMAGE}:${VERSION}" \
  -t "${IMAGE}:${LINE}" \
  .

echo "Built:"
echo "  ${IMAGE}:${VERSION}"
echo "  ${IMAGE}:${LINE}"

if [[ "${PUSH}" == "1" ]]; then
  echo "==> Pushing to Docker Hub..."
  docker push "${IMAGE}:${VERSION}"
  docker push "${IMAGE}:${LINE}"
  echo "Pushed."
else
  echo "Skip push (set PUSH=1 to push)."
fi
