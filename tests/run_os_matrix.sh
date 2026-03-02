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

# 格式: image|override_os_id|override_version|expected_pkg|expected_repo
# expected_repo 为完整路径，如 centos/9、ubuntu/noble、fedora/41
CASES=(
  # ---- RPM 系: CentOS / Rocky / Alma / Oracle ----
  "rockylinux:8|rhel|8|dnf|centos/8"
  "rockylinux:9|rhel|9|dnf|centos/9"
  "quay.io/centos/centos:stream10|rhel|10|dnf|centos/10"
  "almalinux:8|rhel|8|dnf|centos/8"
  "almalinux:9|rhel|9|dnf|centos/9"
  "oraclelinux:8|ol|8|dnf|centos/8"
  "oraclelinux:9|ol|9|dnf|centos/9"

  # ---- RPM 兼容系: Anolis / OpenCloudOS / openEuler ----
  "openanolis/anolisos:23|anolis|23|dnf|centos/9"
  "opencloudos/opencloudos9-minimal|opencloudos|9.4|dnf|centos/9"
  "openeuler/openeuler:24.03-lts|openeuler|24.03|dnf|centos/9"

  # ---- Debian 系 ----
  "ubuntu:24.04|ubuntu|24.04|apt-get|ubuntu/noble"
  "ubuntu:22.04|ubuntu|22.04|apt-get|ubuntu/jammy"
  "ubuntu:20.04|ubuntu|20.04|apt-get|ubuntu/focal"
  "debian:12|debian|12|apt-get|debian/bookworm"
  "debian:11|debian|11|apt-get|debian/bullseye"

  # ---- Fedora ----
  "fedora:41|fedora|41|dnf|fedora/41"
  "fedora:40|fedora|40|dnf|fedora/40"
)

FAILED=0
PASSED=0
FAILURES=()

for case_item in "${CASES[@]}"; do
  IFS='|' read -r image os_id version expected_pkg expected_repo <<<"$case_item"
  echo "==> Testing $image as ${os_id}-${version}"

  if ! $DOCKER_BIN pull "$image" >/dev/null 2>&1; then
    echo "  SKIP: unable to pull $image"
    continue
  fi

  # Debian/Ubuntu 容器可能没有 bash，用 sh 兜底
  shell="bash"
  if [[ "$os_id" == "ubuntu" || "$os_id" == "debian" || "$os_id" == "kali" ]]; then
    shell="bash"
  fi

  output="$($DOCKER_BIN run --rm \
    -e TEST_MODE=1 \
    -e OVERRIDE_OS_ID="$os_id" \
    -e OVERRIDE_OS_VERSION_ID="$version" \
    -v "$SCRIPT_PATH:/tmp/docker.sh:ro" \
    "$image" \
    $shell /tmp/docker.sh 2>&1)" || true

  echo "$output"

  ok=true
  echo "$output" | grep -q "TEST_MODE_OK"          || { echo "  FAIL: missing TEST_MODE_OK"; ok=false; }
  echo "$output" | grep -q "pkg=$expected_pkg"      || { echo "  FAIL: expected pkg=$expected_pkg"; ok=false; }
  echo "$output" | grep -q "repo=$expected_repo"    || { echo "  FAIL: expected repo=$expected_repo"; ok=false; }

  if $ok; then
    echo "  PASS ✓"
    PASSED=$((PASSED + 1))
  else
    echo "  FAIL ✗"
    FAILED=$((FAILED + 1))
    FAILURES+=("$image (${os_id}-${version})")
  fi
  echo ""
done

echo "========================================"
echo "Results: $PASSED passed, $FAILED failed out of ${#CASES[@]} tests."
echo "========================================"

if [[ $FAILED -gt 0 ]]; then
  echo ""
  echo "Failed tests:"
  for f in "${FAILURES[@]}"; do
    echo "  - $f"
  done
  exit 1
fi

echo "All OS matrix checks passed."
