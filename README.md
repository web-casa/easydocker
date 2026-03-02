# easydocker

Docker 一键安装配置脚本，为不受 Docker 官方安装脚本支持的 Linux 发行版提供安装支持。

## 支持的发行版

### RPM 系（使用 CentOS 兼容仓库）

| 发行版 | 支持版本 | 仓库映射 |
|--------|----------|----------|
| CentOS / RHEL | 8, 9, 10 | 对应 el8/el9/el10 |
| Rocky Linux | 8, 9 | 对应 el8/el9 |
| AlmaLinux | 8, 9 | 对应 el8/el9 |
| Oracle Linux | 8, 9 | 对应 el8/el9 |
| openEuler | 20+ | el8/el9 兼容 |
| OpenCloudOS | 9 | el9 兼容 |
| Anolis OS | 8+ | el8 兼容 |
| Alibaba Cloud Linux | 3+ | el8 兼容 |
| 银河麒麟 (Kylin) | V10+ | el8 兼容 |
| Fedora | 最新版 | 使用 Fedora 仓库 |

### Debian 系（使用 APT 仓库）

| 发行版 | 支持版本 |
|--------|----------|
| Ubuntu | 18.04, 20.04, 22.04, 24.04+ |
| Debian | 11 (Bullseye), 12 (Bookworm), 13 (Trixie) |
| Kali Linux | 最新版（使用 Debian 兼容仓库） |

## 特性

- 🔄 多镜像源自动切换（阿里云 → 腾讯云 → 华为云 → 中科大 → 清华 → 官方）
- 📦 包管理器安装失败时自动回退到二进制安装
- 🐳 Docker Compose v2 自动安装
- 🚀 镜像加速自动配置
- 🧪 CI 自动验证（RHEL 8/9/10 矩阵）

## 使用方法

```bash
bash docker.sh
```

## 本地测试

```bash
bash tests/run_os_matrix.sh
```

## CI

- 工作流文件: `.github/workflows/os-compat-ci.yml`
- 触发: `push` / `pull_request`
- 校验矩阵: RHEL 8/9/10
