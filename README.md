# EasyDocker

Docker 一键安装配置脚本，为不受 Docker 官方安装脚本支持的 Linux 发行版提供安装支持。

## 快速开始

```bash
bash <(curl -sSL https://raw.githubusercontent.com/web-casa/easydocker/main/docker.sh)
```

如果使用 `wget`：

```bash
bash <(wget -qO- https://raw.githubusercontent.com/web-casa/easydocker/main/docker.sh)
```

> 国内服务器如果无法访问 GitHub，可使用 ghproxy 等加速服务，或先手动下载 `docker.sh` 再执行。

## 功能模式

脚本运行后会提示选择操作模式：

```
请选择操作模式：
1) 一键安装配置（推荐）
2) 修改镜像加速域名
```

### 模式 1：一键安装配置

完整的 Docker 安装流程，包括：

1. 检测系统发行版并自动配置对应的 Docker CE 仓库
2. 安装 Docker CE + Docker Compose
3. 配置镜像加速（见下方说明）
4. 启动 Docker 服务并配置开机自启

### 模式 2：仅修改镜像加速域名

适用于已安装 Docker、仅需更新镜像加速配置的场景。

## 镜像加速配置

安装过程中（或模式 2）会提示选择镜像加速方案：

```
请选择镜像加速版本:
1) 使用公共加速域名 (docker.m.daocloud.io)
2) 使用自定义加速域名 (自定义 + docker.m.daocloud.io)
```

- **选项 1**：使用 DaoCloud 公共镜像加速，无需任何配置，开箱即用
- **选项 2**：填入你自己的镜像加速域名（如企业内部加速、自建代理等），脚本会将自定义域名设为优先，DaoCloud 作为兜底

配置完成后，脚本会自动写入 `/etc/docker/daemon.json` 并重启 Docker 服务使其生效。

生成的配置示例（选项 2，自定义域名为 `your-mirror.example.com`）：

```json
{
  "registry-mirrors": ["https://your-mirror.example.com", "https://docker.m.daocloud.io"],
  "insecure-registries": ["your-mirror.example.com"]
}
```

## 安装源自动切换

脚本内置多个国内镜像源，按以下顺序依次尝试，确保在各种网络环境下都能完成安装：

1. 阿里云镜像
2. 腾讯云镜像
3. 华为云镜像
4. 中科大镜像
5. 清华大学镜像
6. Docker 官方源

## 支持的发行版

### RPM 系（使用 CentOS 兼容仓库）

| 发行版 | 支持版本 | 仓库映射 |
|--------|----------|----------|
| CentOS / RHEL | 8, 9, 10 | 对应 el8/el9/el10 |
| Rocky Linux | 8, 9 | 对应 el8/el9 |
| AlmaLinux | 8, 9 | 对应 el8/el9 |
| Oracle Linux | 8, 9 | 对应 el8/el9 |
| openEuler | 20+ | 20→el8, 22+→el9 |
| OpenCloudOS | 9 | el9 兼容 |
| Anolis OS | 8, 23 | 8→el8, 23→el9 |
| Alibaba Cloud Linux | 3+ | el8 兼容 |
| 银河麒麟 (Kylin) | V10+ | el8 兼容 |
| Fedora | 最新版 | 使用 Fedora 仓库 |

### Debian 系（使用 APT 仓库）

| 发行版 | 支持版本 |
|--------|----------|
| Ubuntu | 18.04, 20.04, 22.04, 24.04+ |
| Debian | 11 (Bullseye), 12 (Bookworm), 13 (Trixie) |
| Kali Linux | 最新版（使用 Debian 兼容仓库） |

### 非 Linux 系统

macOS 和 Windows 用户运行脚本后会显示对应平台的安装指引（Docker Desktop）。

## 特性

- 多镜像源自动切换（阿里云 → 腾讯云 → 华为云 → 中科大 → 清华 → 官方）
- 包管理器安装失败时自动回退到二进制安装
- Docker Compose v2 自动安装
- 镜像加速自动配置（公共 / 自定义域名）
- CI 自动验证（17 个发行版矩阵 + ShellCheck 静态分析）

## 本地测试

```bash
bash tests/run_os_matrix.sh
```

## CI

- 工作流文件：`.github/workflows/os-compat-ci.yml`
- 触发条件：`push` / `pull_request` 到 `main`
- 测试矩阵：
  - **ShellCheck** — 静态分析
  - **RPM 矩阵** — Rocky 8/9, CentOS Stream 10, Alma 8/9, Oracle 8/9, Anolis 23, OpenCloudOS 9, openEuler 24.03
  - **Debian 矩阵** — Ubuntu 24.04/22.04/20.04, Debian 12/11
  - **Fedora 矩阵** — Fedora 41/40

## License

MIT
