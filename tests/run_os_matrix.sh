#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$ROOT_DIR/docker.sh"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker command not found" >&2
  exit 1
fi

DOCKER_BIN="docker"
if ! docker info >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then
    DOCKER_BIN="sudo docker"
  fi
fi

# image|override_os_id|override_version|expected_pkg|expected_repo_major
CASES=(
  "rockylinux:8|rhel|8|dnf|8"
  "rockylinux:9|rhel|9|dnf|9"
  "quay.io/centos/centos:stream10|rhel|10|dnf|10"
)

FAILED=0
PASSED=0

for case_item in "${CASES[@]}"; do
  IFS='|' read -r image os_id version expected_pkg expected_repo_major <<<"$case_item"
  echo "==> Testing $image as ${os_id}-${version}"

  $DOCKER_BIN pull "$image" >/dev/null

  output="$($DOCKER_BIN run --rm \
    -e TEST_MODE=1 \
    -e OVERRIDE_OS_ID="$os_id" \
    -e OVERRIDE_OS_VERSION_ID="$version" \
    -v "$SCRIPT_PATH:/tmp/docker.sh:ro" \
    "$image" \
    bash /tmp/docker.sh)"

  echo "$output"

  ok=true
  echo "$output" | grep -q "TEST_MODE_OK"   || { echo "  FAIL: missing TEST_MODE_OK"; ok=false; }
  echo "$output" | grep -q "pkg=$expected_pkg" || { echo "  FAIL: expected pkg=$expected_pkg"; ok=false; }
  echo "$output" | grep -q "repo=centos/$expected_repo_major" || { echo "  FAIL: expected repo=centos/$expected_repo_major"; ok=false; }

  if $ok; then
    echo "  PASS"
    ((PASSED++))
  else
    echo "  FAIL"
    ((FAILED++))
  fi
done

echo ""
echo "Results: $PASSED passed, $FAILED failed out of ${#CASES[@]} tests."

if [[ $FAILED -gt 0 ]]; then
  exit 1
fi

echo "All OS matrix checks passed."
