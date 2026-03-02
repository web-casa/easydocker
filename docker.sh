#!/bin/bash
# EasyDocker — Docker 一键安装配置脚本
# 支持官方未覆盖的 Linux 发行版（openEuler、Kylin、Anolis、OpenCloudOS 等）
set -e

get_latest_version() {
  local repo="$1" default="$2"
  local version
  version=$(curl -fsSL --connect-timeout 5 --max-time 10 \
    "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
    | grep '"tag_name"' | head -1 | sed 's/.*"v\?\([^"]*\)".*/\1/')
  if [[ -n "$version" && "$version" != "null" ]]; then
    echo "$version"
  else
    echo "$default"
  fi
}

MIRROR_LIST=(
  "https://mirrors.aliyun.com/docker-ce"
  "https://mirrors.cloud.tencent.com/docker-ce"
  "https://mirrors.huaweicloud.com/docker-ce"
  "https://mirrors.ustc.edu.cn/docker-ce"
  "https://mirrors.tuna.tsinghua.edu.cn/docker-ce"
  "https://download.docker.com"
)

# ============================================================
# 工具函数
# ============================================================

# 检查是否安装了 sudo，如果没有则创建一个函数来模拟 sudo
setup_sudo() {
  if ! command -v sudo &> /dev/null; then
    echo "⚠️  未检测到 sudo 命令，将直接使用 root 权限执行命令"
    sudo() { "$@"; }
    export -f sudo
  fi
}

# 清理临时文件
cleanup() {
  rm -f /tmp/docker.tgz /tmp/docker-ce-install.log /tmp/docker-ce-install-retry.log /tmp/docker-ce-install-mirror.log 2>/dev/null || true
}
trap cleanup EXIT

# ============================================================
# TEST_MODE: 仅做系统支持性校验（用于 CI/本地容器矩阵）
# ============================================================
if [[ "${TEST_MODE:-0}" == "1" ]]; then
  OS="${OVERRIDE_OS_ID:-$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')}"
  VERSION_ID="${OVERRIDE_OS_VERSION_ID:-$(awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release | tr -d '"')}"
  VERSION_MAJOR="${VERSION_ID%%.*}"
  CODENAME="${OVERRIDE_CODENAME:-$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release 2>/dev/null | tr -d '"')}"
  PKG_MANAGER=""
  REPO_PATH=""

  case "$OS" in
    # ---- RPM 系（CentOS 兼容仓库）----
    centos|rhel|rocky|almalinux|ol)
      case "$VERSION_MAJOR" in
        8|9|10) PKG_MANAGER="dnf" ;;
        *)
          echo "UNSUPPORTED: $OS $VERSION_ID (仅支持 8/9/10)"
          exit 1
          ;;
      esac
      if [[ "$VERSION_MAJOR" -ge 10 ]]; then
        REPO_PATH="centos/10"
      else
        REPO_PATH="centos/$VERSION_MAJOR"
      fi
      ;;

    openeuler)
      PKG_MANAGER="dnf"
      if [[ "$VERSION_MAJOR" -ge 22 ]]; then
        REPO_PATH="centos/9"
      elif [[ "$VERSION_MAJOR" -ge 20 ]]; then
        REPO_PATH="centos/8"
      else
        echo "UNSUPPORTED: openEuler $VERSION_ID (仅支持 20+)"
        exit 1
      fi
      ;;

    opencloudos)
      PKG_MANAGER="dnf"
      REPO_PATH="centos/9"
      ;;

    anolis)
      if [[ "$VERSION_MAJOR" -ge 23 ]]; then
        PKG_MANAGER="dnf"
        REPO_PATH="centos/9"
      elif [[ "$VERSION_MAJOR" -ge 8 ]]; then
        PKG_MANAGER="dnf"
        REPO_PATH="centos/8"
      else
        echo "UNSUPPORTED: Anolis $VERSION_ID (仅支持 8+)"
        exit 1
      fi
      ;;

    alinux)
      if [[ "$VERSION_MAJOR" -ge 3 ]]; then
        PKG_MANAGER="dnf"
      else
        PKG_MANAGER="yum"
      fi
      REPO_PATH="centos/8"
      ;;

    kylin)
      PKG_MANAGER="dnf"
      REPO_PATH="centos/8"
      ;;

    # ---- Fedora ----
    fedora)
      PKG_MANAGER="dnf"
      REPO_PATH="fedora/$VERSION_ID"
      ;;

    # ---- Debian 系 ----
    ubuntu)
      PKG_MANAGER="apt-get"
      case "$VERSION_ID" in
        24.04) CODENAME="noble" ;;
        22.04) CODENAME="jammy" ;;
        20.04) CODENAME="focal" ;;
        18.04) CODENAME="bionic" ;;
      esac
      if [[ -z "$CODENAME" ]]; then
        echo "UNSUPPORTED: Ubuntu $VERSION_ID (无法确定代号)"
        exit 1
      fi
      REPO_PATH="ubuntu/$CODENAME"
      ;;

    debian)
      PKG_MANAGER="apt-get"
      case "$VERSION_ID" in
        13) CODENAME="trixie" ;;
        12) CODENAME="bookworm" ;;
        11) CODENAME="bullseye" ;;
      esac
      if [[ -z "$CODENAME" ]]; then
        echo "UNSUPPORTED: Debian $VERSION_ID (无法确定代号)"
        exit 1
      fi
      REPO_PATH="debian/$CODENAME"
      ;;

    kali)
      PKG_MANAGER="apt-get"
      if [[ -z "$CODENAME" ]]; then
        CODENAME="bookworm"
      fi
      REPO_PATH="debian/$CODENAME"
      ;;

    *)
      echo "UNSUPPORTED: $OS $VERSION_ID"
      exit 1
      ;;
  esac

  echo "TEST_MODE_OK os=$OS version=$VERSION_ID major=$VERSION_MAJOR pkg=$PKG_MANAGER repo=$REPO_PATH"
  exit 0
fi

# ============================================================
# 版本号（自动获取最新版，API 不可用时使用默认值）
# ============================================================
echo "正在获取最新版本号..."
DOCKER_BINARY_VERSION=$(get_latest_version "moby/moby" "29.2.1")
DOCKER_COMPOSE_V2_VERSION=$(get_latest_version "docker/compose" "2.36.0")
echo "  Docker: ${DOCKER_BINARY_VERSION}  |  Compose: ${DOCKER_COMPOSE_V2_VERSION}"

# ============================================================
# 镜像源管理
# ============================================================

# try_mirror_download <路径后缀> <输出文件> [超时秒数]
# 依次尝试所有镜像源下载指定文件，成功返回 0
try_mirror_download() {
  local suffix="$1" output="$2" timeout="${3:-60}"
  for mirror in "${MIRROR_LIST[@]}"; do
    local url="${mirror}${suffix}"
    echo "  尝试下载: $url"
    if curl -fsSL "$url" -o "$output" --connect-timeout 10 --max-time "$timeout" 2>/dev/null; then
      echo "  ✅ 下载成功"
      return 0
    fi
  done
  echo "  ❌ 所有源下载失败"
  return 1
}

# setup_rpm_repo <pkg_manager> <centos_version>
# 为 RPM 系发行版配置 Docker CE 仓库，自动尝试多个镜像源
setup_rpm_repo() {
  local pkg_mgr="$1" centos_ver="$2"

  sudo "$pkg_mgr" install -y "${pkg_mgr}-utils" 2>/dev/null || true

  echo "正在配置 Docker CE 仓库 (centos/${centos_ver})..."

  for mirror in "${MIRROR_LIST[@]}"; do
    local base_url="${mirror}/linux/centos/${centos_ver}/\$basearch/stable"
    local gpg_url="${mirror}/linux/centos/gpg"

    echo "  尝试源: $mirror"
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<REPOEOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=${base_url}
enabled=1
gpgcheck=1
gpgkey=${gpg_url}
REPOEOF

    sudo "$pkg_mgr" clean all 2>/dev/null || true
    if sudo "$pkg_mgr" makecache 2>/dev/null; then
      echo "  ✅ 源配置成功: $mirror"
      return 0
    fi
  done

  echo "❌ 所有 Docker 源都配置失败"
  return 1
}

# setup_fedora_repo <centos_version>
# 为 Fedora 配置 Docker CE 仓库
setup_fedora_repo() {
  local fedora_ver="$1"

  sudo dnf install -y dnf-plugins-core 2>/dev/null || true

  echo "正在配置 Docker CE 仓库 (fedora/${fedora_ver})..."

  for mirror in "${MIRROR_LIST[@]}"; do
    local base_url="${mirror}/linux/fedora/${fedora_ver}/\$basearch/stable"
    local gpg_url="${mirror}/linux/fedora/gpg"

    echo "  尝试源: $mirror"
    sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<REPOEOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=${base_url}
enabled=1
gpgcheck=1
gpgkey=${gpg_url}
REPOEOF

    sudo dnf clean all 2>/dev/null || true
    if sudo dnf makecache 2>/dev/null; then
      echo "  ✅ 源配置成功: $mirror"
      return 0
    fi
  done

  echo "❌ 所有 Docker 源都配置失败"
  return 1
}

# setup_deb_repo
# 为 Debian/Ubuntu/Kali 配置 Docker CE APT 仓库
setup_deb_repo() {
  local os_id="$1" codename="$2"

  # Kali 基于 Debian，使用 debian 仓库
  local repo_os="$os_id"
  [[ "$os_id" == "kali" ]] && repo_os="debian"

  # 安装前置依赖
  sudo apt-get update -qq 2>/dev/null || true
  sudo apt-get install -y ca-certificates curl gnupg 2>/dev/null || true

  echo "正在配置 Docker CE APT 仓库 (${repo_os}/${codename})..."

  for mirror in "${MIRROR_LIST[@]}"; do
    local gpg_url="${mirror}/linux/${repo_os}/gpg"
    local repo_url="${mirror}/linux/${repo_os}"

    echo "  尝试源: $mirror"

    # 导入 GPG 密钥
    sudo install -m 0755 -d /etc/apt/keyrings 2>/dev/null || true
    if curl -fsSL "$gpg_url" 2>/dev/null | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg 2>/dev/null; then
      sudo chmod a+r /etc/apt/keyrings/docker.gpg

      # 添加仓库
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] ${repo_url} ${codename} stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

      if sudo apt-get update -qq 2>/dev/null; then
        echo "  ✅ APT 源配置成功: $mirror"
        return 0
      fi
    fi
  done

  echo "❌ 所有 Docker APT 源都配置失败"
  return 1
}

# ============================================================
# Docker 安装函数
# ============================================================

# install_docker_rpm <pkg_manager>
# 通过 RPM 包管理器安装 Docker CE
install_docker_rpm() {
  local pkg_mgr="$1"

  echo ">>> [3/8] 安装 Docker CE..."

  # 处理 iSulad 冲突 (openEuler)
  if rpm -q iSulad &>/dev/null; then
    echo "⚠️  检测到 iSulad，需要卸载以避免与 Docker CE 冲突"
    sudo "$pkg_mgr" remove -y iSulad 2>/dev/null || true
  fi

  set +e

  # 尝试批量安装
  if sudo "$pkg_mgr" install -y --allowerasing docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>&1; then
    echo "✅ Docker CE 安装成功"
    set -e
    return 0
  fi

  echo "❌ 批量安装失败，尝试逐个安装..."

  # 逐个安装核心组件
  for pkg in containerd.io docker-ce-cli docker-ce docker-buildx-plugin docker-compose-plugin; do
    echo "  安装 $pkg..."
    if sudo "$pkg_mgr" install -y --allowerasing "$pkg" 2>&1; then
      echo "  ✅ $pkg 安装成功"
    else
      echo "  ⚠️  $pkg 安装失败"
    fi
  done

  set -e

  # 检查核心组件
  if command -v docker &>/dev/null && { [ -f /usr/lib/systemd/system/docker.service ] || [ -f /etc/systemd/system/docker.service ]; }; then
    echo "✅ Docker CE 核心组件安装完成"
    return 0
  fi

  echo "❌ 包管理器安装失败，回退到二进制安装..."
  install_docker_binary
}

# install_docker_deb
# 通过 APT 安装 Docker CE
install_docker_deb() {
  echo ">>> [3/8] 安装 Docker CE..."

  set +e

  if sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>&1; then
    echo "✅ Docker CE 安装成功"
    set -e
    return 0
  fi

  echo "❌ 批量安装失败，尝试逐个安装..."

  for pkg in containerd.io docker-ce-cli docker-ce docker-buildx-plugin docker-compose-plugin; do
    echo "  安装 $pkg..."
    if sudo apt-get install -y "$pkg" 2>&1; then
      echo "  ✅ $pkg 安装成功"
    else
      echo "  ⚠️  $pkg 安装失败"
    fi
  done

  set -e

  if command -v docker &>/dev/null; then
    echo "✅ Docker CE 核心组件安装完成"
    return 0
  fi

  echo "❌ APT 安装失败，回退到二进制安装..."
  install_docker_binary
}

# install_docker_binary
# 下载并安装 Docker 静态二进制包（最终兜底方案）
install_docker_binary() {
  echo "正在下载 Docker ${DOCKER_BINARY_VERSION} 二进制包..."

  if ! try_mirror_download "/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKER_BINARY_VERSION}.tgz" /tmp/docker.tgz 120; then
    echo "❌ 所有下载源都失败，无法安装 Docker"
    echo "请检查网络连接或手动安装 Docker"
    exit 1
  fi

  echo "正在解压并安装..."
  sudo tar -xzf /tmp/docker.tgz -C /usr/bin --strip-components=1
  sudo chmod +x /usr/bin/docker*

  # SELinux 提示
  if command -v getenforce &> /dev/null && [ "$(getenforce 2>/dev/null)" != "Disabled" ]; then
    echo ""
    echo "⚠️  检测到 SELinux 处于开启状态 ($(getenforce))"
    echo "⚠️  二进制安装方式可能会遇到 SELinux 上下文问题"
    echo "💡 推荐：安装 container-selinux >= 2.74 或临时执行 setenforce 0"
    echo ""
  fi

  # 创建 systemd 服务文件
  sudo tee /etc/systemd/system/docker.service > /dev/null <<'SVCEOF'
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service time-set.target
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
SVCEOF

  sudo tee /etc/systemd/system/docker.socket > /dev/null <<'SOCKEOF'
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
SOCKEOF

  sudo groupadd docker 2>/dev/null || true
  echo "✅ Docker 二进制安装成功"
}

# ============================================================
# Docker Compose 安装
# ============================================================
install_docker_compose() {
  echo ">>> [4/8] 安装 Docker Compose..."

  # 先检查 docker-compose-plugin 是否已通过包管理器安装
  if docker compose version &>/dev/null 2>&1; then
    echo "✅ Docker Compose (插件版) 已安装: $(docker compose version 2>/dev/null || echo 'unknown')"
    return 0
  fi

  # 尝试下载独立 Docker Compose v2 二进制
  echo "正在下载 Docker Compose v${DOCKER_COMPOSE_V2_VERSION}..."

  local compose_arch
  case "$DOCKER_ARCH" in
    x86_64)  compose_arch="x86_64" ;;
    aarch64) compose_arch="aarch64" ;;
    armv7l|armhf) compose_arch="armv7" ;;
    *)       compose_arch="$DOCKER_ARCH" ;;
  esac

  local compose_suffix="/linux/compose/v${DOCKER_COMPOSE_V2_VERSION}/docker-compose-linux-${compose_arch}"

  # 先尝试国内镜像源的 docker-compose v2 二进制
  local downloaded=false
  for mirror in "${MIRROR_LIST[@]}"; do
    # 国内镜像源路径格式不同
    local url
    if [[ "$mirror" == "https://download.docker.com" ]]; then
      # 官方使用 GitHub Releases
      url="https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_V2_VERSION}/docker-compose-linux-${compose_arch}"
    else
      url="${mirror}${compose_suffix}"
    fi

    echo "  尝试: $url"
    if sudo curl -fsSL "$url" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 60 2>/dev/null; then
      downloaded=true
      echo "  ✅ 下载成功"
      break
    fi
  done

  if [[ "$downloaded" == "true" ]]; then
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true
    echo "✅ Docker Compose v${DOCKER_COMPOSE_V2_VERSION} 安装完成"
  else
    echo "⚠️  Docker Compose 独立二进制下载失败"
    echo "💡 您仍可以使用 'docker compose'（如果插件已安装）或手动安装"
  fi
}

# ============================================================
# 启动 Docker 服务
# ============================================================
start_docker_service() {
  echo ">>> [5/8] 启动 Docker 服务..."

  # 检查 docker.service 文件是否存在
  if [ ! -f /etc/systemd/system/docker.service ] && [ ! -f /usr/lib/systemd/system/docker.service ]; then
    echo "❌ docker.service 文件不存在，Docker 服务无法启动"
    exit 1
  fi

  sudo systemctl daemon-reload 2>/dev/null || true
  sudo systemctl enable docker 2>/dev/null && echo "✅ Docker 已设为开机自启" || echo "⚠️  开机自启设置失败"
  if sudo systemctl start docker 2>/dev/null; then
    echo "✅ Docker 服务启动成功"
  else
    echo "⚠️  Docker 服务启动失败，尝试查看日志..."
    sudo systemctl status docker --no-pager -l 2>/dev/null || true
    echo "💡 可尝试手动启动: sudo dockerd &"
  fi
}

# ============================================================
# 镜像加速 & daemon.json 配置
# ============================================================
configure_daemon_json() {
  local choice="$1"
  local custom_domain="${2:-}"

  echo ">>> [6/8] 配置镜像加速..."

  sudo mkdir -p /etc/docker

  # 备份现有配置
  if [ -f /etc/docker/daemon.json ]; then
    sudo cp /etc/docker/daemon.json "/etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ 已备份现有配置"
  fi

  # 清理用户输入的域名
  custom_domain="${custom_domain#http://}"
  custom_domain="${custom_domain#https://}"

  # 构建 mirror_list
  local mirror_list insecure_registries
  if [[ "$choice" == "2" && -n "$custom_domain" ]]; then
    if [[ "$custom_domain" == *.example.run ]]; then
      local custom_domain_dev="${custom_domain%.example.run}.example.dev"
      mirror_list="[\"https://$custom_domain\",\"https://$custom_domain_dev\",\"https://docker.m.daocloud.io\"]"
      insecure_registries="[\"$custom_domain\",\"$custom_domain_dev\"]"
    else
      mirror_list="[\"https://$custom_domain\",\"https://docker.m.daocloud.io\"]"
      insecure_registries="[\"$custom_domain\"]"
    fi
  else
    mirror_list='["https://docker.m.daocloud.io"]'
    insecure_registries='[]'
  fi

  # DNS 配置（仅在系统无 DNS 时添加）
  local dns_line=""
  if [[ "${SKIP_DNS:-}" != "true" ]]; then
    if ! grep -q "nameserver" /etc/resolv.conf 2>/dev/null; then
      dns_line=',
  "dns": ["119.29.29.29", "114.114.114.114"]'
      echo "ℹ️  系统未配置 DNS，已自动添加 Docker DNS"
    else
      echo "ℹ️  系统已有 DNS 配置，跳过 Docker DNS 设置"
    fi
  fi

  cat <<JSONEOF | sudo tee /etc/docker/daemon.json > /dev/null
{
  "registry-mirrors": $mirror_list,
  "insecure-registries": $insecure_registries$dns_line
}
JSONEOF

  echo "✅ daemon.json 配置完成"

  # 显示当前配置的镜像源
  echo "当前配置的镜像源:"
  if [[ "$choice" == "2" && -n "$custom_domain" ]]; then
    echo "  - https://$custom_domain (优先)"
    [[ "$custom_domain" == *.example.run ]] && echo "  - https://${custom_domain%.example.run}.example.dev (备用)"
  fi
  echo "  - https://docker.m.daocloud.io"
}

# 询问用户选择镜像加速配置，返回 choice 和 custom_domain
ask_mirror_choice() {
  echo ""
  echo "请选择镜像加速版本:"
  echo "1) 使用公共加速域名 (docker.m.daocloud.io)"
  echo "2) 使用自定义加速域名 (自定义 + docker.m.daocloud.io)"

  while true; do
    read -rp "请输入选择 [1/2]: " MIRROR_CHOICE
    if [[ "$MIRROR_CHOICE" == "1" || "$MIRROR_CHOICE" == "2" ]]; then
      break
    fi
    echo "❌ 无效选择，请输入 1 或 2"
  done

  CUSTOM_DOMAIN=""
  if [[ "$MIRROR_CHOICE" == "2" ]]; then
    read -rp "请输入您的自定义镜像加速域名: " CUSTOM_DOMAIN
  fi
}

# 重载并重启 Docker
restart_docker() {
  echo ">>> [7/8] 重载 Docker 配置..."
  sudo systemctl daemon-reexec 2>/dev/null || true
  sudo systemctl restart docker 2>/dev/null || true

  echo "等待 Docker 服务启动..."
  sleep 3

  if systemctl is-active --quiet docker 2>/dev/null; then
    echo "✅ Docker 服务已成功启动"
  else
    echo "❌ Docker 服务启动失败，请检查配置"
    exit 1
  fi
}

# 配置用户权限
setup_user_group() {
  echo ">>> [8/8] 配置用户权限..."

  add_user_to_docker_group() {
    local target_user="$1"
    if ! groups "$target_user" 2>/dev/null | grep -q "\bdocker\b"; then
      echo "⚠️  将用户 $target_user 加入 docker 组意味着赋予该用户 root 级权限。"
      read -rp "是否继续将 $target_user 添加到 docker 组？[Y/n] " confirm
      confirm=${confirm:-Y}
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sudo usermod -aG docker "$target_user" 2>/dev/null || true
        echo "✅ 已将用户 $target_user 添加到 docker 组"
        echo "⚠️  请重新登录或执行 'newgrp docker' 使权限生效"
      else
        echo "ℹ️  已跳过用户组配置"
      fi
    else
      echo "✅ 用户 $target_user 已在 docker 组中"
    fi
  }

  if [ -n "${SUDO_USER:-}" ]; then
    add_user_to_docker_group "$SUDO_USER"
  elif [ "$(id -u)" -ne 0 ]; then
    add_user_to_docker_group "$USER"
  else
    echo "ℹ️  当前以 root 用户执行，无需添加到 docker 组"
  fi
}

# ============================================================
# 非 Linux 系统检测与引导
# ============================================================
show_macos_guide() {
  cat <<'MACEOF'
🍎 检测到 macOS 系统
==========================================
⚠️  macOS 不支持此 Linux 安装脚本
==========================================

📋 macOS 安装 Docker 的正确方式：

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
方法一：使用 Homebrew 安装（推荐）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. 安装 Homebrew:
     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  2. 安装 Docker Desktop:
     brew install --cask docker

  3. 启动 Docker Desktop

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
方法二：下载官方安装包
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  https://www.docker.com/products/docker-desktop

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 配置 Docker 镜像加速
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Docker Desktop → Settings → Docker Engine → 添加:
  {
    "registry-mirrors": ["https://docker.m.daocloud.io"]
  }
==========================================
MACEOF
}

show_windows_guide() {
  cat <<'WINEOF'
🪟 检测到 Windows 系统
==========================================
⚠️  Windows 不支持此 Linux 安装脚本
==========================================

📋 Windows 安装 Docker 的正确方式：

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
方法一：Docker Desktop（推荐）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  https://www.docker.com/products/docker-desktop

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
方法二：在 WSL 2 中使用
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. wsl --install
  2. 在 WSL 2 中运行本安装脚本

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 配置 Docker 镜像加速
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Docker Desktop → Settings → Docker Engine → 添加:
  {
    "registry-mirrors": ["https://docker.m.daocloud.io"]
  }

📚 官方文档: https://docs.docker.com/desktop/install/windows-install/
==========================================
WINEOF
}

# ============================================================
# 系统检测：映射 OS → 安装策略
# ============================================================
# 返回值赋给全局变量:
#   INSTALL_TYPE:    rpm / deb
#   PKG_MANAGER:     yum / dnf / apt-get
#   CENTOS_VERSION:  8 / 9 / 10 (仅 rpm)
#   DEB_CODENAME:    bookworm / jammy 等 (仅 deb)
detect_install_strategy() {
  local os_lower
  os_lower=$(echo "$OS" | tr '[:upper:]' '[:lower:]')

  case "$os_lower" in
    # ------ RPM 系（CentOS 兼容仓库） ------
    centos|rhel|rocky|almalinux|ol)
      INSTALL_TYPE="rpm"
      VERSION_MAJOR="${VERSION_ID%%.*}"
      if [[ "$VERSION_MAJOR" -ge 10 ]]; then
        CENTOS_VERSION="10"
        PKG_MANAGER="dnf"
      elif [[ "$VERSION_MAJOR" == "9" ]]; then
        CENTOS_VERSION="9"
        PKG_MANAGER="dnf"
      elif [[ "$VERSION_MAJOR" == "8" ]]; then
        CENTOS_VERSION="8"
        PKG_MANAGER="dnf"
      else
        echo "❌ 不支持 $OS $VERSION_ID（仅支持 8/9/10+）"
        exit 1
      fi
      echo "✅ 检测到 $OS $VERSION_ID，使用 CentOS ${CENTOS_VERSION} 仓库"
      ;;

    openeuler)
      INSTALL_TYPE="rpm"
      local ver_major="${VERSION_ID%%.*}"
      if [[ "$ver_major" -ge 22 ]]; then
        CENTOS_VERSION="9"
        PKG_MANAGER="dnf"
      elif [[ "$ver_major" -ge 20 ]]; then
        CENTOS_VERSION="8"
        PKG_MANAGER="dnf"
      else
        echo "❌ openEuler $VERSION_ID 版本过低，仅支持 20+"
        exit 1
      fi
      echo "✅ 检测到 openEuler $VERSION_ID，使用 CentOS ${CENTOS_VERSION} 兼容仓库"
      ;;

    opencloudos)
      INSTALL_TYPE="rpm"
      CENTOS_VERSION="9"
      PKG_MANAGER="dnf"
      echo "✅ 检测到 OpenCloudOS $VERSION_ID，使用 CentOS 9 兼容仓库"
      ;;

    anolis)
      INSTALL_TYPE="rpm"
      if [[ "${VERSION_ID%%.*}" -ge 23 ]]; then
        CENTOS_VERSION="9"
        PKG_MANAGER="dnf"
      elif [[ "${VERSION_ID%%.*}" -ge 8 ]]; then
        CENTOS_VERSION="8"
        PKG_MANAGER="dnf"
      else
        echo "❌ Anolis OS $VERSION_ID 版本过低，仅支持 8+"
        exit 1
      fi
      echo "✅ 检测到 Anolis OS $VERSION_ID，使用 CentOS ${CENTOS_VERSION} 兼容仓库"
      ;;

    alinux)
      INSTALL_TYPE="rpm"
      if [[ "${VERSION_ID%%.*}" -ge 3 ]]; then
        CENTOS_VERSION="8"
        PKG_MANAGER="dnf"
      else
        CENTOS_VERSION="8"
        PKG_MANAGER="yum"
      fi
      echo "✅ 检测到 Alibaba Cloud Linux $VERSION_ID，使用 CentOS ${CENTOS_VERSION} 兼容仓库"
      ;;

    kylin)
      INSTALL_TYPE="rpm"
      # 银河麒麟基于 RHEL
      if command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
        CENTOS_VERSION="8"
      else
        echo "❌ Kylin $VERSION_ID 版本过低，仅支持使用 dnf 的版本"
        exit 1
      fi
      echo "✅ 检测到银河麒麟 (Kylin) $VERSION_ID，使用 CentOS ${CENTOS_VERSION} 兼容仓库"
      ;;

    fedora)
      INSTALL_TYPE="fedora"
      PKG_MANAGER="dnf"
      CENTOS_VERSION="${VERSION_ID}"
      echo "✅ 检测到 Fedora $VERSION_ID，使用 Fedora 仓库"
      ;;

    # ------ Debian 系 ------
    ubuntu)
      INSTALL_TYPE="deb"
      PKG_MANAGER="apt-get"
      # Ubuntu 版本代号映射
      case "$VERSION_ID" in
        24.04) DEB_CODENAME="noble" ;;
        22.04) DEB_CODENAME="jammy" ;;
        20.04) DEB_CODENAME="focal" ;;
        18.04) DEB_CODENAME="bionic" ;;
        *)
          # 尝试从 /etc/os-release 获取
          DEB_CODENAME=$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release | tr -d '"')
          if [[ -z "$DEB_CODENAME" ]]; then
            echo "❌ 无法检测 Ubuntu $VERSION_ID 的代号"
            exit 1
          fi
          ;;
      esac
      echo "✅ 检测到 Ubuntu $VERSION_ID ($DEB_CODENAME)"
      ;;

    debian)
      INSTALL_TYPE="deb"
      PKG_MANAGER="apt-get"
      case "$VERSION_ID" in
        13) DEB_CODENAME="trixie" ;;
        12) DEB_CODENAME="bookworm" ;;
        11) DEB_CODENAME="bullseye" ;;
        *)
          DEB_CODENAME=$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release | tr -d '"')
          if [[ -z "$DEB_CODENAME" ]]; then
            echo "❌ 无法检测 Debian $VERSION_ID 的代号"
            exit 1
          fi
          ;;
      esac
      echo "✅ 检测到 Debian $VERSION_ID ($DEB_CODENAME)"
      ;;

    kali)
      INSTALL_TYPE="deb"
      PKG_MANAGER="apt-get"
      # Kali 使用对应的 Debian 代号
      DEB_CODENAME=$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release | tr -d '"')
      if [[ -z "$DEB_CODENAME" ]]; then
        DEB_CODENAME="bookworm"
      fi
      echo "✅ 检测到 Kali Linux，使用 Debian ($DEB_CODENAME) 兼容仓库"
      ;;

    *)
      echo "❌ 暂不支持该系统: $OS $VERSION_ID"
      echo "💡 支持的系统: CentOS/RHEL/Rocky/AlmaLinux 8-10, openEuler 20+,"
      echo "   OpenCloudOS, Anolis 8+, Alinux, Kylin, Fedora, Ubuntu, Debian, Kali"
      exit 1
      ;;
  esac
}

# ============================================================
# 主流程
# ============================================================
main() {
  setup_sudo

  echo "=========================================="
  echo "🐳 欢迎使用 Docker 一键安装配置脚本"
  echo "=========================================="
  echo "官方网站: https://docs.docker.com"
  echo ""

  # 检测非 Linux 系统
  local detected_os
  detected_os=$(uname -s 2>/dev/null || echo "Unknown")

  if [[ "$detected_os" == "Darwin" ]]; then
    show_macos_guide
    exit 0
  fi

  if [[ "$detected_os" == MINGW* ]] || [[ "$detected_os" == MSYS* ]] || [[ "$detected_os" == CYGWIN* ]]; then
    show_windows_guide
    exit 0
  fi

  # 交互式选择操作模式
  echo "请选择操作模式："
  echo "1) 一键安装配置（推荐）"
  echo "2) 修改镜像加速域名"
  echo ""

  while true; do
    read -rp "请输入选择 [1/2]: " mode_choice

    if [[ "$mode_choice" == "1" ]]; then
      echo ""
      echo ">>> 模式：一键安装配置"

      # 检查是否已安装 Docker
      if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
        echo ""
        echo "⚠️  检测到已安装 Docker 版本: $DOCKER_VERSION"
        echo "⚠️  继续将进行 Docker 升级或重装，建议先备份重要数据"
        echo ""
        echo "1) 确认继续安装/升级"
        echo "2) 返回选择菜单"
        echo ""

        while true; do
          read -rp "请输入选择 [1/2]: " confirm_choice
          if [[ "$confirm_choice" == "1" ]]; then
            echo "✅ 用户确认继续"
            break
          elif [[ "$confirm_choice" == "2" ]]; then
            echo "🔄 返回选择菜单..."
            echo ""
            echo "请选择操作模式："
            echo "1) 一键安装配置（推荐）"
            echo "2) 修改镜像加速域名"
            echo ""
            break
          else
            echo "❌ 无效选择"
          fi
        done
        [[ "$confirm_choice" == "2" ]] && continue
      fi
      break

    elif [[ "$mode_choice" == "2" ]]; then
      echo ""
      echo ">>> 模式：仅修改镜像加速域名"
      echo ""

      if ! command -v docker &> /dev/null; then
        echo "❌ Docker 未安装！建议选择选项 1 进行完整安装"
        exit 1
      fi

      ask_mirror_choice
      configure_daemon_json "$MIRROR_CHOICE" "$CUSTOM_DOMAIN"

      if systemctl is-active --quiet docker 2>/dev/null; then
        sudo systemctl daemon-reexec 2>/dev/null || true
        sudo systemctl restart docker 2>/dev/null || true
        sleep 3
        if systemctl is-active --quiet docker; then
          echo "✅ Docker 服务重启成功，新配置已生效"
        else
          echo "❌ Docker 服务重启失败"
        fi
      else
        echo "⚠️  Docker 服务未运行，配置将在下次启动时生效"
      fi

      echo ""
      echo "🎉 镜像配置完成！"
      exit 0
    else
      echo "❌ 无效选择，请输入 1 或 2"
    fi
  done

  # ---- 全新安装/升级流程 ----

  echo ">>> [1/8] 检查系统信息..."
  OS="${OVERRIDE_OS_ID:-$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')}"
  ARCH=$(uname -m)
  VERSION_ID="${OVERRIDE_OS_VERSION_ID:-$(awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release | tr -d '"')}"
  echo "系统: $OS $VERSION_ID 架构: $ARCH"

  # 映射架构
  case "$ARCH" in
    x86_64)             DOCKER_ARCH="x86_64" ;;
    aarch64|arm64)      DOCKER_ARCH="aarch64" ;;
    armv7l|armhf)       DOCKER_ARCH="armhf" ;;
    armv6l|armel)       DOCKER_ARCH="armel" ;;
    s390x)              DOCKER_ARCH="s390x" ;;
    ppc64le)            DOCKER_ARCH="ppc64le" ;;
    *)                  DOCKER_ARCH="$ARCH" ;;
  esac
  echo "📦 Docker 架构: $DOCKER_ARCH"

  # 检测安装策略
  detect_install_strategy

  # ---- 安装 Docker ----
  echo ">>> [2/8] 配置 Docker 源..."

  case "$INSTALL_TYPE" in
    rpm)
      setup_rpm_repo "$PKG_MANAGER" "$CENTOS_VERSION"
      install_docker_rpm "$PKG_MANAGER"
      ;;
    fedora)
      setup_fedora_repo "$CENTOS_VERSION"
      install_docker_rpm "$PKG_MANAGER"
      ;;
    deb)
      setup_deb_repo "$OS" "$DEB_CODENAME"
      install_docker_deb
      ;;
  esac

  # 启动 Docker
  start_docker_service

  # 安装 Docker Compose
  install_docker_compose

  # 配置镜像加速
  ask_mirror_choice
  configure_daemon_json "$MIRROR_CHOICE" "$CUSTOM_DOMAIN"

  # 重启 Docker 使配置生效
  restart_docker

  # 配置用户权限
  setup_user_group

  echo ""
  echo "🎉 安装和配置完成！"
  echo "Docker 版本: $(docker --version 2>/dev/null || echo '未知')"
  echo "官方网站: https://docs.docker.com"
}

# 执行主流程
main "$@"
