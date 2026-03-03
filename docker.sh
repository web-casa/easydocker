#!/bin/bash
# EasyDocker — One-click Docker installation script
# Supports Linux distros not covered by the official Docker install script
# (openEuler, Kylin, Anolis, OpenCloudOS, etc.)
set -e

# ============================================================
# i18n message system
# ============================================================
declare -A MESSAGES

init_messages_en() {
  MESSAGES=(
    [welcome]="Welcome to EasyDocker — Docker One-Click Installer"
    [official_site]="Official site: https://docs.docker.com"
    [fetching_versions]="Fetching latest version numbers..."
    [version_info]="  Docker: %s  |  Compose: %s"
    [try_download]="  Trying: %s"
    [download_ok]="  Download succeeded"
    [download_all_failed]="  All download sources failed"
    [configuring_repo]="Configuring Docker CE repository (%s)..."
    [try_source]="  Trying source: %s"
    [source_ok]="  Source configured: %s"
    [source_all_failed]="All Docker sources failed"
    [configuring_apt]="Configuring Docker CE APT repository (%s)..."
    [apt_source_ok]="  APT source configured: %s"
    [apt_source_all_failed]="All Docker APT sources failed"
    [installing_docker]="Installing Docker CE..."
    [docker_installed]="Docker CE installed successfully"
    [batch_install_failed]="Batch install failed, trying individual packages..."
    [installing_pkg]="  Installing %s..."
    [pkg_installed]="  %s installed"
    [pkg_failed]="  %s install failed"
    [core_installed]="Docker CE core components installed"
    [pkg_fallback_binary]="Package manager install failed, falling back to binary install..."
    [apt_fallback_binary]="APT install failed, falling back to binary install..."
    [downloading_binary]="Downloading Docker %s binary package..."
    [binary_all_failed]="All download sources failed, cannot install Docker"
    [check_network]="Please check your network or install Docker manually"
    [extracting]="Extracting and installing..."
    [selinux_warning]="SELinux is enabled (%s). Binary install may have SELinux context issues."
    [selinux_tip]="Tip: Install container-selinux >= 2.74 or run setenforce 0"
    [binary_installed]="Docker binary installed successfully"
    [isulad_detected]="iSulad detected, removing to avoid conflict with Docker CE"
    [installing_compose]="Installing Docker Compose..."
    [compose_already]="Docker Compose (plugin) already installed: %s"
    [downloading_compose]="Downloading Docker Compose v%s..."
    [compose_installed]="Docker Compose v%s installed"
    [compose_failed]="Docker Compose binary download failed"
    [compose_tip]="You can still use 'docker compose' (if plugin is installed) or install manually"
    [starting_docker]="Starting Docker service..."
    [service_missing]="docker.service not found, cannot start Docker"
    [autostart_ok]="Docker set to start on boot"
    [autostart_failed]="Failed to set autostart"
    [service_started]="Docker service started"
    [service_start_failed]="Docker service failed to start, checking logs..."
    [service_start_tip]="Tip: Try starting manually with: sudo dockerd &"
    [kernel_reboot_hint]="A newer kernel (%s) is installed but not running (current: %s). Reboot to load the new kernel and its modules, then Docker should start normally."
    [reboot_command]="Run: reboot"
    [removing_conflicts]="Removing conflicting packages (podman, buildah, etc.)..."
    [conflicts_removed]="Conflicting packages removed"
    [installing_kernel_modules]="Installing kernel-modules-extra (required for Docker networking on EL10+)..."
    [kernel_modules_installed]="kernel-modules-extra installed"
    [loading_kernel_modules]="Loading required kernel modules..."
    [kernel_modules_loaded]="Kernel modules loaded and persisted"
    [kernel_modules_load_failed]="Failed to load kernel modules (may need reboot for new kernel)"
    [configuring_mirror]="Configuring mirror acceleration..."
    [backup_ok]="Existing config backed up"
    [no_dns_added]="No DNS configured, added Docker DNS automatically"
    [dns_exists]="System DNS found, skipping Docker DNS"
    [daemon_json_ok]="daemon.json configured"
    [current_mirrors]="Configured mirrors:"
    [mirror_priority]="  - https://%s (priority)"
    [mirror_fallback]="  - https://%s (fallback)"
    [select_mirror]="Select mirror acceleration:"
    [mirror_opt_none]="1) No mirror acceleration (default)"
    [mirror_opt_public]="2) Use public mirror (docker.m.daocloud.io)"
    [mirror_opt_custom]="3) Use custom mirror domain"
    [enter_choice]="Enter choice [%s]: "
    [invalid_choice]="Invalid choice"
    [enter_custom_domain]="Enter your custom mirror domain: "
    [reloading_docker]="Reloading Docker configuration..."
    [waiting_docker]="Waiting for Docker service..."
    [service_restarted]="Docker service restarted successfully"
    [service_restart_failed]="Docker service restart failed, please check config"
    [configuring_user]="Configuring user permissions..."
    [group_warning]="Adding user %s to docker group grants root-level privileges."
    [group_confirm]="Add %s to docker group? [Y/n] "
    [group_added]="User %s added to docker group"
    [group_relogin]="Please re-login or run 'newgrp docker' to apply"
    [group_skipped]="Skipped user group configuration"
    [group_already]="User %s is already in docker group"
    [group_root]="Running as root, no need to add to docker group"
    [no_sudo]="sudo not found, running commands directly as root"
    [select_mode]="Select operation mode:"
    [mode_install]="1) Install and configure (recommended)"
    [mode_mirror]="2) Change mirror acceleration only"
    [mode_install_label]="Mode: Install and configure"
    [mode_mirror_label]="Mode: Change mirror acceleration"
    [docker_exists]="Docker %s is already installed"
    [docker_exists_warn]="Continuing will upgrade or reinstall Docker. Back up important data first."
    [confirm_continue]="1) Continue with install/upgrade"
    [confirm_back]="2) Go back"
    [user_confirmed]="User confirmed, continuing"
    [going_back]="Going back..."
    [docker_not_installed]="Docker is not installed! Use option 1 for full installation"
    [mirror_config_done]="Mirror configuration complete!"
    [service_restart_ok]="Docker restarted, new config applied"
    [service_restart_err]="Docker restart failed"
    [service_not_running]="Docker is not running, config will apply on next start"
    [checking_system]="Checking system information..."
    [system_info]="System: %s %s  Arch: %s"
    [docker_arch]="Docker arch: %s"
    [configuring_source]="Configuring Docker source..."
    [install_done]="Installation and configuration complete!"
    [install_done_warning]="Installation complete, but Docker service failed to start. Please check the logs above."
    [docker_version_info]="Docker version: %s"
    [detected_os]="Detected %s %s, using %s repository"
    [unsupported_os]="Unsupported: %s %s"
    [unsupported_version]="Unsupported: %s %s (only %s supported)"
    [supported_list]="Supported: CentOS/RHEL/Rocky/AlmaLinux 8-10, openEuler 20+, OpenCloudOS, Anolis 8+, Alinux, Kylin, Fedora, Ubuntu, Debian, Kali"
    [cannot_detect_codename]="Cannot detect codename for %s %s"
    [macos_detected]="macOS detected"
    [macos_unsupported]="macOS is not supported by this Linux install script"
    [macos_install_methods]="How to install Docker on macOS:"
    [macos_homebrew]="Method 1: Install with Homebrew (recommended)"
    [macos_download]="Method 2: Download official installer"
    [macos_mirror_config]="Configure Docker mirror acceleration"
    [windows_detected]="Windows detected"
    [windows_unsupported]="Windows is not supported by this Linux install script"
    [windows_install_methods]="How to install Docker on Windows:"
    [windows_desktop]="Method 1: Docker Desktop (recommended)"
    [windows_wsl]="Method 2: Use WSL 2"
    [mirror_required]="--mirror must be set to 'public' or a domain when using --mode mirror"
    [usage_header]="Usage: bash docker.sh [OPTIONS]"
    [usage_options]="Options:"
  )
}

init_messages_zh() {
  MESSAGES=(
    [welcome]="欢迎使用 EasyDocker — Docker 一键安装配置脚本"
    [official_site]="官方网站: https://docs.docker.com"
    [fetching_versions]="正在获取最新版本号..."
    [version_info]="  Docker: %s  |  Compose: %s"
    [try_download]="  尝试下载: %s"
    [download_ok]="  下载成功"
    [download_all_failed]="  所有源下载失败"
    [configuring_repo]="正在配置 Docker CE 仓库 (%s)..."
    [try_source]="  尝试源: %s"
    [source_ok]="  源配置成功: %s"
    [source_all_failed]="所有 Docker 源都配置失败"
    [configuring_apt]="正在配置 Docker CE APT 仓库 (%s)..."
    [apt_source_ok]="  APT 源配置成功: %s"
    [apt_source_all_failed]="所有 Docker APT 源都配置失败"
    [installing_docker]="安装 Docker CE..."
    [docker_installed]="Docker CE 安装成功"
    [batch_install_failed]="批量安装失败，尝试逐个安装..."
    [installing_pkg]="  安装 %s..."
    [pkg_installed]="  %s 安装成功"
    [pkg_failed]="  %s 安装失败"
    [core_installed]="Docker CE 核心组件安装完成"
    [pkg_fallback_binary]="包管理器安装失败，回退到二进制安装..."
    [apt_fallback_binary]="APT 安装失败，回退到二进制安装..."
    [downloading_binary]="正在下载 Docker %s 二进制包..."
    [binary_all_failed]="所有下载源都失败，无法安装 Docker"
    [check_network]="请检查网络连接或手动安装 Docker"
    [extracting]="正在解压并安装..."
    [selinux_warning]="检测到 SELinux 处于开启状态 (%s)，二进制安装可能会遇到上下文问题"
    [selinux_tip]="推荐：安装 container-selinux >= 2.74 或临时执行 setenforce 0"
    [binary_installed]="Docker 二进制安装成功"
    [isulad_detected]="检测到 iSulad，需要卸载以避免与 Docker CE 冲突"
    [installing_compose]="安装 Docker Compose..."
    [compose_already]="Docker Compose (插件版) 已安装: %s"
    [downloading_compose]="正在下载 Docker Compose v%s..."
    [compose_installed]="Docker Compose v%s 安装完成"
    [compose_failed]="Docker Compose 独立二进制下载失败"
    [compose_tip]="您仍可以使用 'docker compose'（如果插件已安装）或手动安装"
    [starting_docker]="启动 Docker 服务..."
    [service_missing]="docker.service 文件不存在，Docker 服务无法启动"
    [autostart_ok]="Docker 已设为开机自启"
    [autostart_failed]="开机自启设置失败"
    [service_started]="Docker 服务启动成功"
    [service_start_failed]="Docker 服务启动失败，尝试查看日志..."
    [service_start_tip]="可尝试手动启动: sudo dockerd &"
    [kernel_reboot_hint]="检测到已安装新内核 (%s) 但当前运行的是旧内核 (%s)。请重启服务器以加载新内核及其模块，之后 Docker 应可正常启动。"
    [reboot_command]="执行: reboot"
    [removing_conflicts]="正在移除冲突的软件包 (podman, buildah 等)..."
    [conflicts_removed]="冲突软件包已移除"
    [installing_kernel_modules]="正在安装 kernel-modules-extra（EL10+ Docker 网络所需）..."
    [kernel_modules_installed]="kernel-modules-extra 已安装"
    [loading_kernel_modules]="正在加载所需内核模块..."
    [kernel_modules_loaded]="内核模块已加载并持久化"
    [kernel_modules_load_failed]="内核模块加载失败（可能需要重启以使用新内核）"
    [configuring_mirror]="配置镜像加速..."
    [backup_ok]="已备份现有配置"
    [no_dns_added]="系统未配置 DNS，已自动添加 Docker DNS"
    [dns_exists]="系统已有 DNS 配置，跳过 Docker DNS 设置"
    [daemon_json_ok]="daemon.json 配置完成"
    [current_mirrors]="当前配置的镜像源:"
    [mirror_priority]="  - https://%s (优先)"
    [mirror_fallback]="  - https://%s (备用)"
    [select_mirror]="请选择镜像加速版本:"
    [mirror_opt_none]="1) 不使用镜像加速（默认）"
    [mirror_opt_public]="2) 使用公共加速域名 (docker.m.daocloud.io)"
    [mirror_opt_custom]="3) 使用自定义加速域名"
    [enter_choice]="请输入选择 [%s]: "
    [invalid_choice]="无效选择"
    [enter_custom_domain]="请输入您的自定义镜像加速域名: "
    [reloading_docker]="重载 Docker 配置..."
    [waiting_docker]="等待 Docker 服务启动..."
    [service_restarted]="Docker 服务已成功启动"
    [service_restart_failed]="Docker 服务启动失败，请检查配置"
    [configuring_user]="配置用户权限..."
    [group_warning]="将用户 %s 加入 docker 组意味着赋予该用户 root 级权限。"
    [group_confirm]="是否继续将 %s 添加到 docker 组？[Y/n] "
    [group_added]="已将用户 %s 添加到 docker 组"
    [group_relogin]="请重新登录或执行 'newgrp docker' 使权限生效"
    [group_skipped]="已跳过用户组配置"
    [group_already]="用户 %s 已在 docker 组中"
    [group_root]="当前以 root 用户执行，无需添加到 docker 组"
    [no_sudo]="未检测到 sudo 命令，将直接使用 root 权限执行命令"
    [select_mode]="请选择操作模式："
    [mode_install]="1) 一键安装配置（推荐）"
    [mode_mirror]="2) 修改镜像加速域名"
    [mode_install_label]="模式：一键安装配置"
    [mode_mirror_label]="模式：仅修改镜像加速域名"
    [docker_exists]="检测到已安装 Docker 版本: %s"
    [docker_exists_warn]="继续将进行 Docker 升级或重装，建议先备份重要数据"
    [confirm_continue]="1) 确认继续安装/升级"
    [confirm_back]="2) 返回选择菜单"
    [user_confirmed]="用户确认继续"
    [going_back]="返回选择菜单..."
    [docker_not_installed]="Docker 未安装！建议选择选项 1 进行完整安装"
    [mirror_config_done]="镜像配置完成！"
    [service_restart_ok]="Docker 服务重启成功，新配置已生效"
    [service_restart_err]="Docker 服务重启失败"
    [service_not_running]="Docker 服务未运行，配置将在下次启动时生效"
    [checking_system]="检查系统信息..."
    [system_info]="系统: %s %s 架构: %s"
    [docker_arch]="Docker 架构: %s"
    [configuring_source]="配置 Docker 源..."
    [install_done]="安装和配置完成！"
    [install_done_warning]="安装完成，但 Docker 服务启动失败，请检查上方日志。"
    [docker_version_info]="Docker 版本: %s"
    [detected_os]="检测到 %s %s，使用 %s 仓库"
    [unsupported_os]="暂不支持该系统: %s %s"
    [unsupported_version]="不支持 %s %s（仅支持 %s）"
    [supported_list]="支持的系统: CentOS/RHEL/Rocky/AlmaLinux 8-10, openEuler 20+, OpenCloudOS, Anolis 8+, Alinux, Kylin, Fedora, Ubuntu, Debian, Kali"
    [cannot_detect_codename]="无法检测 %s %s 的代号"
    [macos_detected]="检测到 macOS 系统"
    [macos_unsupported]="macOS 不支持此 Linux 安装脚本"
    [macos_install_methods]="macOS 安装 Docker 的正确方式："
    [macos_homebrew]="方法一：使用 Homebrew 安装（推荐）"
    [macos_download]="方法二：下载官方安装包"
    [macos_mirror_config]="配置 Docker 镜像加速"
    [windows_detected]="检测到 Windows 系统"
    [windows_unsupported]="Windows 不支持此 Linux 安装脚本"
    [windows_install_methods]="Windows 安装 Docker 的正确方式："
    [windows_desktop]="方法一：Docker Desktop（推荐）"
    [windows_wsl]="方法二：在 WSL 2 中使用"
    [mirror_required]="使用 --mode mirror 时，--mirror 必须设为 'public' 或一个域名"
    [usage_header]="用法: bash docker.sh [选项]"
    [usage_options]="选项："
  )
}

# Print a translated message. Supports printf-style format args.
# Usage: msg <key> [args...]
msg() {
  local key="$1"
  shift
  local template="${MESSAGES[$key]:-$key}"
  if [[ $# -gt 0 ]]; then
    # shellcheck disable=SC2059
    printf "${template}\n" "$@"
  else
    echo "$template"
  fi
}

# ============================================================
# Defaults and CLI argument parsing
# ============================================================
LANG_CHOICE="en"
MIRROR_CHOICE_ARG=""
MODE_ARG=""
AUTO_YES=false

show_usage() {
  init_messages_en
  echo "Usage: bash docker.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --lang en|zh       UI language (default: en)"
  echo "  --mirror <value>   Mirror config: none, public, or a custom domain"
  echo "                     (default: none — uses Docker official registry)"
  echo "  --mode <value>     Operation mode: install or mirror"
  echo "                     (non-interactive when specified)"
  echo "  -y, --yes          Skip interactive confirmations"
  echo "  -h, --help         Show this help message"
  echo ""
  echo "Examples:"
  echo "  bash docker.sh                              # Interactive (English)"
  echo "  bash docker.sh --lang zh                    # Interactive (Chinese)"
  echo "  bash docker.sh --mode install --yes         # Non-interactive install"
  echo "  bash docker.sh --mode install --mirror public --yes"
  echo "  bash docker.sh --mode mirror --mirror public"
  echo "  bash docker.sh --mode mirror --mirror hub.example.com"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --lang)
        LANG_CHOICE="$2"
        shift 2
        ;;
      --mirror)
        MIRROR_CHOICE_ARG="$2"
        shift 2
        ;;
      --mode)
        MODE_ARG="$2"
        shift 2
        ;;
      -y|--yes)
        AUTO_YES=true
        shift
        ;;
      -h|--help)
        show_usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done
}

get_latest_version() {
  local repo="$1" default="$2"
  local version
  version=$(curl -fsSL --connect-timeout 5 --max-time 10 \
    "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
    | grep '"tag_name"' | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  if [[ -n "$version" ]]; then
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
# Utility functions
# ============================================================

# Set up sudo wrapper if sudo is not available
setup_sudo() {
  if ! command -v sudo &> /dev/null; then
    msg no_sudo
    sudo() { "$@"; }
    export -f sudo
  fi
}

# Check if a newer kernel is installed but not yet running
# If so, a reboot is likely needed for Docker to work (missing kernel modules)
check_kernel_reboot_needed() {
  local running_kernel newest_kernel
  running_kernel=$(uname -r)

  # Get list of installed kernels sorted by version, pick the newest
  if command -v rpm &>/dev/null; then
    newest_kernel=$(rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' 2>/dev/null | sort -V | tail -1)
  elif command -v dpkg &>/dev/null; then
    newest_kernel=$(dpkg -l 'linux-image-*' 2>/dev/null | awk '/^ii/{print $2}' | sed 's/linux-image-//' | sort -V | tail -1)
  fi

  if [[ -n "$newest_kernel" && "$newest_kernel" != "$running_kernel" ]]; then
    echo ""
    msg kernel_reboot_hint "$newest_kernel" "$running_kernel"
    msg reboot_command
    echo ""
  fi
}

# Clean up temp files on exit
cleanup() {
  rm -f /tmp/docker.tgz /tmp/docker-ce-install.log /tmp/docker-ce-install-retry.log /tmp/docker-ce-install-mirror.log 2>/dev/null || true
}
trap cleanup EXIT

# ============================================================
# TEST_MODE: Validate OS support only (for CI / container matrix)
# ============================================================
if [[ "${TEST_MODE:-0}" == "1" ]]; then
  OS="${OVERRIDE_OS_ID:-$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')}"
  VERSION_ID="${OVERRIDE_OS_VERSION_ID:-$(awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release | tr -d '"')}"
  VERSION_MAJOR="${VERSION_ID%%.*}"
  CODENAME="${OVERRIDE_CODENAME:-$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release 2>/dev/null | tr -d '"')}"
  PKG_MANAGER=""
  REPO_PATH=""

  case "$OS" in
    # ---- RPM-based (CentOS-compatible repo) ----
    centos|rhel|rocky|almalinux|ol)
      case "$VERSION_MAJOR" in
        8|9|10) PKG_MANAGER="dnf" ;;
        *)
          echo "UNSUPPORTED: $OS $VERSION_ID (only 8/9/10)"
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
        echo "UNSUPPORTED: openEuler $VERSION_ID (only 20+)"
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
        echo "UNSUPPORTED: Anolis $VERSION_ID (only 8+)"
        exit 1
      fi
      ;;

    alinux)
      if [[ "$VERSION_MAJOR" -ge 4 ]]; then
        PKG_MANAGER="dnf"
        REPO_PATH="centos/9"
      elif [[ "$VERSION_MAJOR" -ge 3 ]]; then
        PKG_MANAGER="dnf"
        REPO_PATH="centos/8"
      else
        PKG_MANAGER="yum"
        REPO_PATH="centos/8"
      fi
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

    # ---- Debian-based ----
    ubuntu)
      PKG_MANAGER="apt-get"
      case "$VERSION_ID" in
        24.04) CODENAME="noble" ;;
        22.04) CODENAME="jammy" ;;
        20.04) CODENAME="focal" ;;
        18.04) CODENAME="bionic" ;;
      esac
      if [[ -z "$CODENAME" ]]; then
        echo "UNSUPPORTED: Ubuntu $VERSION_ID (cannot detect codename)"
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
        echo "UNSUPPORTED: Debian $VERSION_ID (cannot detect codename)"
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
# Version numbers (auto-detect latest, fallback to defaults)
# ============================================================
fetch_versions() {
  msg fetching_versions
  DOCKER_BINARY_VERSION=$(get_latest_version "moby/moby" "29.2.1")
  DOCKER_COMPOSE_V2_VERSION=$(get_latest_version "docker/compose" "2.36.0")
  msg version_info "$DOCKER_BINARY_VERSION" "$DOCKER_COMPOSE_V2_VERSION"
}

# ============================================================
# Mirror source management
# ============================================================

# try_mirror_download <url_suffix> <output_file> [timeout_seconds]
# Try all mirror sources in order, return 0 on first success
try_mirror_download() {
  local suffix="$1" output="$2" timeout="${3:-60}"
  for mirror in "${MIRROR_LIST[@]}"; do
    local url="${mirror}${suffix}"
    msg try_download "$url"
    if curl -fsSL "$url" -o "$output" --connect-timeout 10 --max-time "$timeout" 2>/dev/null; then
      msg download_ok
      return 0
    fi
  done
  msg download_all_failed
  return 1
}

# setup_rpm_repo <pkg_manager> <centos_version>
# Configure Docker CE repo for RPM-based distros
setup_rpm_repo() {
  local pkg_mgr="$1" centos_ver="$2"

  sudo "$pkg_mgr" install -y "${pkg_mgr}-utils" 2>/dev/null || true

  msg configuring_repo "centos/${centos_ver}"

  for mirror in "${MIRROR_LIST[@]}"; do
    local base_url="${mirror}/linux/centos/${centos_ver}/\$basearch/stable"
    local gpg_url="${mirror}/linux/centos/gpg"

    msg try_source "$mirror"
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
      msg source_ok "$mirror"
      return 0
    fi
  done

  msg source_all_failed
  return 1
}

# setup_fedora_repo <fedora_version>
# Configure Docker CE repo for Fedora
setup_fedora_repo() {
  local fedora_ver="$1"

  sudo dnf install -y dnf-plugins-core 2>/dev/null || true

  msg configuring_repo "fedora/${fedora_ver}"

  for mirror in "${MIRROR_LIST[@]}"; do
    local base_url="${mirror}/linux/fedora/${fedora_ver}/\$basearch/stable"
    local gpg_url="${mirror}/linux/fedora/gpg"

    msg try_source "$mirror"
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
      msg source_ok "$mirror"
      return 0
    fi
  done

  msg source_all_failed
  return 1
}

# setup_deb_repo <os_id> <codename>
# Configure Docker CE APT repo for Debian/Ubuntu/Kali
setup_deb_repo() {
  local os_id="$1" codename="$2"

  # Kali is Debian-based, use debian repo
  local repo_os="$os_id"
  [[ "$os_id" == "kali" ]] && repo_os="debian"

  # Install prerequisites
  sudo apt-get update -qq 2>/dev/null || true
  sudo apt-get install -y ca-certificates curl gnupg 2>/dev/null || true

  msg configuring_apt "${repo_os}/${codename}"

  for mirror in "${MIRROR_LIST[@]}"; do
    local gpg_url="${mirror}/linux/${repo_os}/gpg"
    local repo_url="${mirror}/linux/${repo_os}"

    msg try_source "$mirror"

    # Import GPG key
    sudo install -m 0755 -d /etc/apt/keyrings 2>/dev/null || true
    if curl -fsSL "$gpg_url" 2>/dev/null | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg 2>/dev/null; then
      sudo chmod a+r /etc/apt/keyrings/docker.gpg

      # Add repository
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] ${repo_url} ${codename} stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

      if sudo apt-get update -qq 2>/dev/null; then
        msg apt_source_ok "$mirror"
        return 0
      fi
    fi
  done

  msg apt_source_all_failed
  return 1
}

# ============================================================
# Pre-install preparation
# ============================================================

# Remove conflicting packages (Podman, Buildah, etc.)
# Required on EL systems where these are pre-installed
remove_conflicting_packages() {
  local pkg_mgr="$1"
  local conflicts=(podman buildah containers-common docker docker-client
    docker-client-latest docker-common docker-latest docker-latest-logrotate
    docker-logrotate docker-engine)
  local found=false

  for pkg in "${conflicts[@]}"; do
    if rpm -q "$pkg" &>/dev/null 2>&1; then
      found=true
      break
    fi
  done

  if [[ "$found" == "true" ]]; then
    msg removing_conflicts
    sudo "$pkg_mgr" remove -y "${conflicts[@]}" 2>/dev/null || true
    msg conflicts_removed
  fi
}

# Ensure required kernel modules are available on EL10+
# EL10 removed ip_tables module; Docker needs xt_addrtype, br_netfilter, overlay
prepare_kernel_modules() {
  local pkg_mgr="$1"
  local version_major="$2"

  # Only needed for EL10+
  if [[ "$version_major" -lt 10 ]]; then
    return 0
  fi

  # Install kernel-modules-extra for the RUNNING kernel first,
  # so modules can be loaded without a reboot.
  local running_kernel
  running_kernel=$(uname -r)
  if ! rpm -q "kernel-modules-extra-${running_kernel}" &>/dev/null 2>&1; then
    msg installing_kernel_modules
    # Try current kernel version first; fall back to generic (latest) if unavailable
    if ! sudo "$pkg_mgr" install -y "kernel-modules-extra-${running_kernel}" 2>/dev/null; then
      sudo "$pkg_mgr" install -y kernel-modules-extra 2>/dev/null || true
    fi
    msg kernel_modules_installed
  fi

  # Load required kernel modules
  msg loading_kernel_modules
  local all_loaded=true
  for mod in xt_addrtype br_netfilter overlay; do
    if ! modprobe "$mod" 2>/dev/null; then
      all_loaded=false
    fi
  done

  if [[ "$all_loaded" == "true" ]]; then
    # Persist across reboots
    for mod in xt_addrtype br_netfilter overlay; do
      echo "$mod" | sudo tee "/etc/modules-load.d/${mod}.conf" > /dev/null 2>/dev/null || true
    done
    msg kernel_modules_loaded
  else
    msg kernel_modules_load_failed
  fi
}

# ============================================================
# Docker installation functions
# ============================================================

# install_docker_rpm <pkg_manager>
# Install Docker CE via RPM package manager
install_docker_rpm() {
  local pkg_mgr="$1"

  msg installing_docker

  # Handle iSulad conflict (openEuler)
  if rpm -q iSulad &>/dev/null; then
    msg isulad_detected
    sudo "$pkg_mgr" remove -y iSulad 2>/dev/null || true
  fi

  set +e

  # Try batch install
  if sudo "$pkg_mgr" install -y --allowerasing docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>&1; then
    msg docker_installed
    set -e
    return 0
  fi

  msg batch_install_failed

  # Install core components one by one
  for pkg in containerd.io docker-ce-cli docker-ce docker-buildx-plugin docker-compose-plugin; do
    msg installing_pkg "$pkg"
    if sudo "$pkg_mgr" install -y --allowerasing "$pkg" 2>&1; then
      msg pkg_installed "$pkg"
    else
      msg pkg_failed "$pkg"
    fi
  done

  set -e

  # Verify core components
  if command -v docker &>/dev/null && { [ -f /usr/lib/systemd/system/docker.service ] || [ -f /etc/systemd/system/docker.service ]; }; then
    msg core_installed
    return 0
  fi

  msg pkg_fallback_binary
  install_docker_binary
}

# install_docker_deb
# Install Docker CE via APT
install_docker_deb() {
  msg installing_docker

  set +e

  if sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>&1; then
    msg docker_installed
    set -e
    return 0
  fi

  msg batch_install_failed

  for pkg in containerd.io docker-ce-cli docker-ce docker-buildx-plugin docker-compose-plugin; do
    msg installing_pkg "$pkg"
    if sudo apt-get install -y "$pkg" 2>&1; then
      msg pkg_installed "$pkg"
    else
      msg pkg_failed "$pkg"
    fi
  done

  set -e

  if command -v docker &>/dev/null; then
    msg core_installed
    return 0
  fi

  msg apt_fallback_binary
  install_docker_binary
}

# install_docker_binary
# Download and install Docker static binary (final fallback)
install_docker_binary() {
  msg downloading_binary "$DOCKER_BINARY_VERSION"

  if ! try_mirror_download "/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKER_BINARY_VERSION}.tgz" /tmp/docker.tgz 120; then
    msg binary_all_failed
    msg check_network
    exit 1
  fi

  msg extracting
  sudo tar -xzf /tmp/docker.tgz -C /usr/bin --strip-components=1
  sudo chmod +x /usr/bin/docker*

  # SELinux warning
  if command -v getenforce &> /dev/null && [ "$(getenforce 2>/dev/null)" != "Disabled" ]; then
    echo ""
    msg selinux_warning "$(getenforce)"
    msg selinux_tip
    echo ""
  fi

  # Create systemd service files
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
  msg binary_installed
}

# ============================================================
# Docker Compose installation
# ============================================================
install_docker_compose() {
  msg installing_compose

  # Check if docker-compose-plugin is already installed via package manager
  if docker compose version &>/dev/null 2>&1; then
    msg compose_already "$(docker compose version 2>/dev/null || echo 'unknown')"
    return 0
  fi

  # Try downloading standalone Docker Compose v2 binary
  msg downloading_compose "$DOCKER_COMPOSE_V2_VERSION"

  local compose_arch
  case "$DOCKER_ARCH" in
    x86_64)  compose_arch="x86_64" ;;
    aarch64) compose_arch="aarch64" ;;
    armv7l|armhf) compose_arch="armv7" ;;
    *)       compose_arch="$DOCKER_ARCH" ;;
  esac

  local compose_suffix="/linux/compose/v${DOCKER_COMPOSE_V2_VERSION}/docker-compose-linux-${compose_arch}"

  # Try mirror sources for docker-compose v2 binary
  local downloaded=false
  for mirror in "${MIRROR_LIST[@]}"; do
    local url
    if [[ "$mirror" == "https://download.docker.com" ]]; then
      # Official source uses GitHub Releases
      url="https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_V2_VERSION}/docker-compose-linux-${compose_arch}"
    else
      url="${mirror}${compose_suffix}"
    fi

    msg try_download "$url"
    if sudo curl -fsSL "$url" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 60 2>/dev/null; then
      downloaded=true
      msg download_ok
      break
    fi
  done

  if [[ "$downloaded" == "true" ]]; then
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true
    msg compose_installed "$DOCKER_COMPOSE_V2_VERSION"
  else
    msg compose_failed
    msg compose_tip
  fi
}

# ============================================================
# Start Docker service
# ============================================================
start_docker_service() {
  msg starting_docker

  # Check if docker.service file exists
  if [ ! -f /etc/systemd/system/docker.service ] && [ ! -f /usr/lib/systemd/system/docker.service ]; then
    msg service_missing
    exit 1
  fi

  sudo systemctl daemon-reload 2>/dev/null || true

  # Ensure containerd is started first (required by Docker)
  if systemctl list-unit-files containerd.service &>/dev/null; then
    sudo systemctl enable containerd 2>/dev/null || true
    if ! systemctl is-active --quiet containerd 2>/dev/null; then
      sudo systemctl start containerd 2>/dev/null || true
      sleep 1
    fi
  fi

  if sudo systemctl enable docker 2>/dev/null; then
    msg autostart_ok
  else
    msg autostart_failed
  fi
  if sudo systemctl start docker 2>/dev/null; then
    msg service_started
    DOCKER_RUNNING=true
  else
    msg service_start_failed
    sudo journalctl -xeu docker.service --no-pager -n 20 2>/dev/null || \
      sudo systemctl status docker --no-pager -l 2>/dev/null || true

    # Check if a newer kernel is installed but not yet booted
    check_kernel_reboot_needed

    msg service_start_tip
    DOCKER_RUNNING=false
  fi
}

# ============================================================
# Mirror acceleration & daemon.json configuration
# ============================================================

# configure_daemon_json <mirror_mode> [custom_domain]
# mirror_mode: "none", "public", "custom"
configure_daemon_json() {
  local mirror_mode="$1"
  local custom_domain="${2:-}"

  msg configuring_mirror

  sudo mkdir -p /etc/docker

  # Backup existing config
  if [ -f /etc/docker/daemon.json ]; then
    sudo cp /etc/docker/daemon.json "/etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)"
    msg backup_ok
  fi

  # Clean user input
  custom_domain="${custom_domain#http://}"
  custom_domain="${custom_domain#https://}"

  # Build mirror_list and insecure_registries
  local mirror_list insecure_registries
  case "$mirror_mode" in
    public)
      mirror_list='["https://docker.m.daocloud.io"]'
      insecure_registries='[]'
      ;;
    custom)
      if [[ -n "$custom_domain" ]]; then
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
      ;;
    *)
      # none — no mirrors
      mirror_list='[]'
      insecure_registries='[]'
      ;;
  esac

  # DNS config (only add if system has no DNS)
  local dns_line=""
  if [[ "${SKIP_DNS:-}" != "true" ]]; then
    if ! grep -q "nameserver" /etc/resolv.conf 2>/dev/null; then
      dns_line=',
  "dns": ["119.29.29.29", "114.114.114.114"]'
      msg no_dns_added
    else
      msg dns_exists
    fi
  fi

  cat <<JSONEOF | sudo tee /etc/docker/daemon.json > /dev/null
{
  "registry-mirrors": $mirror_list,
  "insecure-registries": $insecure_registries$dns_line
}
JSONEOF

  msg daemon_json_ok

  # Display configured mirrors
  if [[ "$mirror_mode" != "none" ]]; then
    msg current_mirrors
    if [[ "$mirror_mode" == "custom" && -n "$custom_domain" ]]; then
      msg mirror_priority "$custom_domain"
      [[ "$custom_domain" == *.example.run ]] && msg mirror_fallback "${custom_domain%.example.run}.example.dev"
    fi
    echo "  - https://docker.m.daocloud.io"
  fi
}

# Ask user to select mirror config interactively
# Sets MIRROR_MODE and CUSTOM_DOMAIN
ask_mirror_choice() {
  echo ""
  msg select_mirror
  msg mirror_opt_none
  msg mirror_opt_public
  msg mirror_opt_custom

  while true; do
    # shellcheck disable=SC2059
    printf "$(msg enter_choice "1/2/3")" ""
    read -r MIRROR_INPUT
    MIRROR_INPUT="${MIRROR_INPUT:-1}"
    case "$MIRROR_INPUT" in
      1) MIRROR_MODE="none"; break ;;
      2) MIRROR_MODE="public"; break ;;
      3) MIRROR_MODE="custom"; break ;;
      *) msg invalid_choice ;;
    esac
  done

  CUSTOM_DOMAIN=""
  if [[ "$MIRROR_MODE" == "custom" ]]; then
    # shellcheck disable=SC2059
    printf "%s" "$(msg enter_custom_domain)"
    read -r CUSTOM_DOMAIN
  fi
}

# Reload and restart Docker
restart_docker() {
  msg reloading_docker
  sudo systemctl daemon-reexec 2>/dev/null || true
  sudo systemctl restart docker 2>/dev/null || true

  msg waiting_docker
  sleep 3

  if systemctl is-active --quiet docker 2>/dev/null; then
    msg service_restarted
    DOCKER_RUNNING=true
  else
    msg service_restart_failed
    DOCKER_RUNNING=false
  fi
}

# Configure user permissions
setup_user_group() {
  msg configuring_user

  add_user_to_docker_group() {
    local target_user="$1"
    if ! groups "$target_user" 2>/dev/null | grep -q "\bdocker\b"; then
      if [[ "$AUTO_YES" == "true" ]]; then
        sudo usermod -aG docker "$target_user" 2>/dev/null || true
        msg group_added "$target_user"
        msg group_relogin
      else
        msg group_warning "$target_user"
        # shellcheck disable=SC2059
        printf "%s" "$(msg group_confirm "$target_user")"
        read -r confirm
        confirm=${confirm:-Y}
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
          sudo usermod -aG docker "$target_user" 2>/dev/null || true
          msg group_added "$target_user"
          msg group_relogin
        else
          msg group_skipped
        fi
      fi
    else
      msg group_already "$target_user"
    fi
  }

  if [ -n "${SUDO_USER:-}" ]; then
    add_user_to_docker_group "$SUDO_USER"
  elif [ "$(id -u)" -ne 0 ]; then
    add_user_to_docker_group "$USER"
  else
    msg group_root
  fi
}

# ============================================================
# Non-Linux system detection and guidance
# ============================================================
show_macos_guide() {
  echo "=========================================="
  msg macos_detected
  echo "=========================================="
  msg macos_unsupported
  echo ""
  msg macos_install_methods
  echo ""
  echo "---"
  msg macos_homebrew
  echo "---"
  echo "  1. Install Homebrew:"
  # shellcheck disable=SC2016
  echo '     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  echo ""
  echo "  2. Install Docker Desktop:"
  echo "     brew install --cask docker"
  echo ""
  echo "  3. Launch Docker Desktop"
  echo ""
  echo "---"
  msg macos_download
  echo "---"
  echo "  https://www.docker.com/products/docker-desktop"
  echo ""
  echo "---"
  msg macos_mirror_config
  echo "---"
  echo '  Docker Desktop -> Settings -> Docker Engine -> Add:'
  echo '  {'
  echo '    "registry-mirrors": ["https://docker.m.daocloud.io"]'
  echo '  }'
  echo "=========================================="
}

show_windows_guide() {
  echo "=========================================="
  msg windows_detected
  echo "=========================================="
  msg windows_unsupported
  echo ""
  msg windows_install_methods
  echo ""
  echo "---"
  msg windows_desktop
  echo "---"
  echo "  https://www.docker.com/products/docker-desktop"
  echo ""
  echo "---"
  msg windows_wsl
  echo "---"
  echo "  1. wsl --install"
  echo "  2. Run this script inside WSL 2"
  echo ""
  echo "---"
  msg macos_mirror_config
  echo "---"
  echo '  Docker Desktop -> Settings -> Docker Engine -> Add:'
  echo '  {'
  echo '    "registry-mirrors": ["https://docker.m.daocloud.io"]'
  echo '  }'
  echo ""
  echo "  Docs: https://docs.docker.com/desktop/install/windows-install/"
  echo "=========================================="
}

# ============================================================
# OS detection: Map OS -> install strategy
# ============================================================
# Sets global variables:
#   INSTALL_TYPE:    rpm / deb / fedora
#   PKG_MANAGER:     yum / dnf / apt-get
#   CENTOS_VERSION:  8 / 9 / 10 (rpm only)
#   DEB_CODENAME:    bookworm / jammy etc (deb only)
detect_install_strategy() {
  local os_lower
  os_lower=$(echo "$OS" | tr '[:upper:]' '[:lower:]')

  case "$os_lower" in
    # ------ RPM-based (CentOS-compatible repo) ------
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
        msg unsupported_version "$OS" "$VERSION_ID" "8/9/10+"
        exit 1
      fi
      msg detected_os "$OS" "$VERSION_ID" "CentOS ${CENTOS_VERSION}"
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
        msg unsupported_version "openEuler" "$VERSION_ID" "20+"
        exit 1
      fi
      msg detected_os "openEuler" "$VERSION_ID" "CentOS ${CENTOS_VERSION}"
      ;;

    opencloudos)
      INSTALL_TYPE="rpm"
      CENTOS_VERSION="9"
      PKG_MANAGER="dnf"
      msg detected_os "OpenCloudOS" "$VERSION_ID" "CentOS 9"
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
        msg unsupported_version "Anolis OS" "$VERSION_ID" "8+"
        exit 1
      fi
      msg detected_os "Anolis OS" "$VERSION_ID" "CentOS ${CENTOS_VERSION}"
      ;;

    alinux)
      INSTALL_TYPE="rpm"
      if [[ "${VERSION_ID%%.*}" -ge 4 ]]; then
        CENTOS_VERSION="9"
        PKG_MANAGER="dnf"
      elif [[ "${VERSION_ID%%.*}" -ge 3 ]]; then
        CENTOS_VERSION="8"
        PKG_MANAGER="dnf"
      else
        CENTOS_VERSION="8"
        PKG_MANAGER="yum"
      fi
      msg detected_os "Alibaba Cloud Linux" "$VERSION_ID" "CentOS ${CENTOS_VERSION}"
      ;;

    kylin)
      INSTALL_TYPE="rpm"
      # Kylin is based on RHEL
      if command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
        CENTOS_VERSION="8"
      else
        msg unsupported_version "Kylin" "$VERSION_ID" "dnf-based"
        exit 1
      fi
      msg detected_os "Kylin" "$VERSION_ID" "CentOS ${CENTOS_VERSION}"
      ;;

    fedora)
      INSTALL_TYPE="fedora"
      PKG_MANAGER="dnf"
      CENTOS_VERSION="${VERSION_ID}"
      msg detected_os "Fedora" "$VERSION_ID" "Fedora"
      ;;

    # ------ Debian-based ------
    ubuntu)
      INSTALL_TYPE="deb"
      PKG_MANAGER="apt-get"
      # Ubuntu version codename mapping
      case "$VERSION_ID" in
        24.04) DEB_CODENAME="noble" ;;
        22.04) DEB_CODENAME="jammy" ;;
        20.04) DEB_CODENAME="focal" ;;
        18.04) DEB_CODENAME="bionic" ;;
        *)
          # Try from /etc/os-release
          DEB_CODENAME=$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release | tr -d '"')
          if [[ -z "$DEB_CODENAME" ]]; then
            msg cannot_detect_codename "Ubuntu" "$VERSION_ID"
            exit 1
          fi
          ;;
      esac
      msg detected_os "Ubuntu" "$VERSION_ID ($DEB_CODENAME)" "Ubuntu"
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
            msg cannot_detect_codename "Debian" "$VERSION_ID"
            exit 1
          fi
          ;;
      esac
      msg detected_os "Debian" "$VERSION_ID ($DEB_CODENAME)" "Debian"
      ;;

    kali)
      INSTALL_TYPE="deb"
      PKG_MANAGER="apt-get"
      # Kali uses corresponding Debian codename
      DEB_CODENAME=$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release | tr -d '"')
      if [[ -z "$DEB_CODENAME" ]]; then
        DEB_CODENAME="bookworm"
      fi
      msg detected_os "Kali Linux" "" "Debian ($DEB_CODENAME)"
      ;;

    *)
      msg unsupported_os "$OS" "$VERSION_ID"
      msg supported_list
      exit 1
      ;;
  esac
}

# ============================================================
# Main flow
# ============================================================
main() {
  parse_args "$@"

  # Initialize i18n
  if [[ "$LANG_CHOICE" == "zh" ]]; then
    init_messages_zh
  else
    init_messages_en
  fi

  setup_sudo

  echo "=========================================="
  msg welcome
  echo "=========================================="
  msg official_site
  echo ""

  # Detect non-Linux systems
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

  # Determine operation mode
  local run_mode=""

  if [[ -n "$MODE_ARG" ]]; then
    # Non-interactive: mode from CLI
    run_mode="$MODE_ARG"
  else
    # Interactive: ask user
    msg select_mode
    msg mode_install
    msg mode_mirror
    echo ""

    while true; do
      # shellcheck disable=SC2059
      printf "$(msg enter_choice "1/2")" ""
      read -r mode_input
      mode_input="${mode_input:-1}"
      case "$mode_input" in
        1) run_mode="install"; break ;;
        2) run_mode="mirror"; break ;;
        *) msg invalid_choice ;;
      esac
    done
  fi

  # ---- Mirror-only mode ----
  if [[ "$run_mode" == "mirror" ]]; then
    echo ""
    msg mode_mirror_label
    echo ""

    if ! command -v docker &> /dev/null; then
      msg docker_not_installed
      exit 1
    fi

    # Determine mirror settings
    if [[ -n "$MIRROR_CHOICE_ARG" ]]; then
      # Non-interactive
      case "$MIRROR_CHOICE_ARG" in
        none)
          msg mirror_required
          exit 1
          ;;
        public)
          MIRROR_MODE="public"
          CUSTOM_DOMAIN=""
          ;;
        *)
          MIRROR_MODE="custom"
          CUSTOM_DOMAIN="$MIRROR_CHOICE_ARG"
          ;;
      esac
    else
      ask_mirror_choice
    fi

    configure_daemon_json "$MIRROR_MODE" "$CUSTOM_DOMAIN"

    if systemctl is-active --quiet docker 2>/dev/null; then
      sudo systemctl daemon-reexec 2>/dev/null || true
      sudo systemctl restart docker 2>/dev/null || true
      sleep 3
      if systemctl is-active --quiet docker; then
        msg service_restart_ok
      else
        msg service_restart_err
      fi
    else
      msg service_not_running
    fi

    echo ""
    msg mirror_config_done
    exit 0
  fi

  # ---- Install mode ----
  echo ""
  msg mode_install_label

  # Check if Docker is already installed
  if command -v docker &> /dev/null; then
    local existing_version
    existing_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
    echo ""
    msg docker_exists "$existing_version"
    msg docker_exists_warn
    echo ""

    if [[ "$AUTO_YES" != "true" ]]; then
      msg confirm_continue
      msg confirm_back
      echo ""

      while true; do
        # shellcheck disable=SC2059
        printf "$(msg enter_choice "1/2")" ""
        read -r confirm_input
        case "$confirm_input" in
          1) msg user_confirmed; break ;;
          2) msg going_back; exec bash "$0" "$@"; exit ;;
          *) msg invalid_choice ;;
        esac
      done
    fi
  fi

  # Fetch latest versions
  fetch_versions

  # Step: Check system info
  msg checking_system
  OS="${OVERRIDE_OS_ID:-$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')}"
  ARCH=$(uname -m)
  VERSION_ID="${OVERRIDE_OS_VERSION_ID:-$(awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release | tr -d '"')}"
  msg system_info "$OS" "$VERSION_ID" "$ARCH"

  # Map architecture
  case "$ARCH" in
    x86_64)             DOCKER_ARCH="x86_64" ;;
    aarch64|arm64)      DOCKER_ARCH="aarch64" ;;
    armv7l|armhf)       DOCKER_ARCH="armhf" ;;
    armv6l|armel)       DOCKER_ARCH="armel" ;;
    s390x)              DOCKER_ARCH="s390x" ;;
    ppc64le)            DOCKER_ARCH="ppc64le" ;;
    *)                  DOCKER_ARCH="$ARCH" ;;
  esac
  msg docker_arch "$DOCKER_ARCH"

  # Detect install strategy
  detect_install_strategy

  # Pre-install: remove conflicting packages and prepare kernel modules (RPM-based)
  case "$INSTALL_TYPE" in
    rpm|fedora)
      remove_conflicting_packages "$PKG_MANAGER"
      prepare_kernel_modules "$PKG_MANAGER" "${VERSION_ID%%.*}"
      ;;
  esac

  # Configure Docker source
  msg configuring_source

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

  # Start Docker
  start_docker_service

  # Install Docker Compose
  install_docker_compose

  # Mirror configuration
  if [[ -n "$MIRROR_CHOICE_ARG" ]]; then
    # Non-interactive mirror config
    case "$MIRROR_CHOICE_ARG" in
      none|"")
        MIRROR_MODE="none"
        CUSTOM_DOMAIN=""
        ;;
      public)
        MIRROR_MODE="public"
        CUSTOM_DOMAIN=""
        ;;
      *)
        MIRROR_MODE="custom"
        CUSTOM_DOMAIN="$MIRROR_CHOICE_ARG"
        ;;
    esac
  elif [[ "$AUTO_YES" == "true" ]]; then
    # Auto-yes with no mirror arg = no mirror
    MIRROR_MODE="none"
    CUSTOM_DOMAIN=""
  else
    ask_mirror_choice
  fi

  if [[ "$MIRROR_MODE" != "none" ]]; then
    configure_daemon_json "$MIRROR_MODE" "$CUSTOM_DOMAIN"
    restart_docker
  fi

  # Configure user permissions
  setup_user_group

  echo ""
  if [[ "${DOCKER_RUNNING:-false}" == "true" ]]; then
    msg install_done
    msg docker_version_info "$(docker --version 2>/dev/null || echo 'unknown')"
  else
    msg install_done_warning
  fi
  msg official_site
}

# Run main
main "$@"
