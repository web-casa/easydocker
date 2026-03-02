# EasyDocker

Docker 一键安装配置脚本，为 Docker 官方安装脚本未覆盖的 Linux 发行版提供支持。

## 快速开始

```bash
bash <(curl -sSL https://raw.githubusercontent.com/web-casa/easydocker/main/docker.sh)
```

或使用 `wget`：

```bash
bash <(wget -qO- https://raw.githubusercontent.com/web-casa/easydocker/main/docker.sh)
```

## 使用方法

```
bash docker.sh [选项]

选项：
  --lang en|zh       界面语言（默认：en 英文）
  --mirror <值>      镜像加速配置：none、public 或自定义域名
                     （默认：none，使用 Docker 官方源）
  --mode <值>        操作模式：install（安装）或 mirror（仅配置镜像）
  -y, --yes          跳过交互确认（自动确认）
  -h, --help         显示帮助信息
```

### 示例

```bash
# 交互模式（默认英文）
bash docker.sh

# 交互模式（中文）
bash docker.sh --lang zh

# 非交互安装，不配置镜像加速
bash docker.sh --mode install --yes

# 非交互安装，使用公共镜像加速
bash docker.sh --mode install --mirror public --yes

# 非交互安装，使用自定义镜像加速
bash docker.sh --mode install --mirror hub.example.com --yes

# 仅修改镜像加速（交互）
bash docker.sh --mode mirror

# 仅修改镜像加速（非交互）
bash docker.sh --mode mirror --mirror public
```

## 操作模式

### 模式一：安装配置（`--mode install`）

完整的 Docker 安装流程：

1. 检测 Linux 发行版，自动配置对应的 Docker CE 仓库
2. 安装 Docker CE + Docker Compose
3. 启动 Docker 服务并设置开机自启
4. （可选）配置镜像加速
5. 配置用户权限

### 模式二：仅修改镜像（`--mode mirror`）

适用于已安装 Docker 的服务器，仅更新镜像加速配置。

## 镜像加速

默认不配置镜像加速，直接使用 Docker 官方源。海外服务器推荐使用默认配置。

国内服务器可通过 `--mirror` 参数配置加速：

| 值 | 行为 |
|----|------|
| `none`（默认） | 不使用镜像加速，使用 Docker 官方源 |
| `public` | 使用 DaoCloud 公共加速（`docker.m.daocloud.io`） |
| `<域名>` | 使用自定义域名优先，DaoCloud 兜底 |

交互模式下提供三个选项：

```
1) 不使用镜像加速（默认）
2) 使用公共加速域名 (docker.m.daocloud.io)
3) 使用自定义加速域名
```

使用 `--mirror hub.example.com` 时生成的 `daemon.json` 示例：

```json
{
  "registry-mirrors": ["https://hub.example.com", "https://docker.m.daocloud.io"],
  "insecure-registries": ["hub.example.com"]
}
```

## 支持的发行版

### RPM 系（使用 CentOS 兼容仓库）

| 发行版 | 支持版本 | 仓库映射 |
|--------|----------|----------|
| CentOS / RHEL | 8, 9, 10 | el8/el9/el10 |
| Rocky Linux | 8, 9 | el8/el9 |
| AlmaLinux | 8, 9 | el8/el9 |
| Oracle Linux | 8, 9 | el8/el9 |
| openEuler | 20+ | 20→el8, 22+→el9 |
| OpenCloudOS | 9 | el9 |
| Anolis OS | 8, 23 | 8→el8, 23→el9 |
| Alibaba Cloud Linux | 3+ | el8 |
| 银河麒麟 (Kylin) | V10+ | el8 |
| Fedora | 最新版 | Fedora 仓库 |

### Debian 系（使用 APT 仓库）

| 发行版 | 支持版本 |
|--------|----------|
| Ubuntu | 18.04, 20.04, 22.04, 24.04+ |
| Debian | 11 (Bullseye), 12 (Bookworm), 13 (Trixie) |
| Kali Linux | 最新版（使用 Debian 兼容仓库） |

### 非 Linux 系统

macOS 和 Windows 用户运行脚本后会显示对应平台的 Docker Desktop 安装指引。

## 安装源自动切换

脚本内置多个国内镜像源，按以下顺序依次尝试，确保在各种网络环境下都能完成安装：

1. 阿里云镜像
2. 腾讯云镜像
3. 华为云镜像
4. 中科大镜像
5. 清华大学镜像
6. Docker 官方源

## 特性

- 多镜像源自动切换，下载失败自动重试
- 包管理器安装失败时自动回退到二进制安装
- Docker Compose v2 自动安装
- 镜像加速可选配置（默认不加速，适配海外服务器）
- 中英文双语支持（`--lang zh`）
- 非交互模式，适用于自动化部署（`--mode install --yes`）
- CI 自动验证（17 个发行版矩阵 + ShellCheck 静态分析）

## 开发

### 本地测试

```bash
bash tests/run_os_matrix.sh
```

### CI

- 工作流文件：`.github/workflows/os-compat-ci.yml`
- 触发条件：`push` / `pull_request` 到 `main`
- 测试 Job：
  - **ShellCheck** — 静态分析
  - **RPM 矩阵** — Rocky 8/9, CentOS Stream 10, Alma 8/9, Oracle 8/9, Anolis 23, OpenCloudOS 9, openEuler 24.03
  - **Debian 矩阵** — Ubuntu 24.04/22.04/20.04, Debian 12/11
  - **Fedora 矩阵** — Fedora 41/40

## License

MIT
