# EasyDocker

One-click Docker installation script for Linux distros not covered by the official Docker install script.

## Quick Start

```bash
bash <(curl -sSL https://raw.githubusercontent.com/web-casa/easydocker/main/docker.sh)
```

Or with `wget`:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/web-casa/easydocker/main/docker.sh)
```

## Usage

```
bash docker.sh [OPTIONS]

Options:
  --lang en|zh       UI language (default: en)
  --mirror <value>   Mirror config: none, public, or a custom domain
                     (default: none — uses Docker official registry)
  --mode <value>     Operation mode: install or mirror
  -y, --yes          Skip interactive confirmations
  -h, --help         Show help message
```

### Examples

```bash
# Interactive mode (English, default)
bash docker.sh

# Interactive mode (Chinese)
bash docker.sh --lang zh

# Non-interactive install, no mirror
bash docker.sh --mode install --yes

# Non-interactive install with public mirror acceleration
bash docker.sh --mode install --mirror public --yes

# Non-interactive install with custom mirror
bash docker.sh --mode install --mirror hub.example.com --yes

# Change mirror config only (interactive)
bash docker.sh --mode mirror

# Change mirror config only (non-interactive)
bash docker.sh --mode mirror --mirror public
```

## Operation Modes

### Mode: Install (`--mode install`)

Full Docker installation flow:

1. Detect Linux distro and configure the appropriate Docker CE repository
2. Install Docker CE + Docker Compose
3. Start Docker service and enable autostart
4. (Optional) Configure mirror acceleration
5. Configure user permissions

### Mode: Mirror (`--mode mirror`)

For servers with Docker already installed — update mirror acceleration config only.

## Mirror Acceleration

By default, the script uses Docker's official registry (no mirrors). This is the best choice for servers outside China.

For servers in China, use `--mirror` to configure acceleration:

| Value | Behavior |
|-------|----------|
| `none` (default) | No mirror, use Docker official registry |
| `public` | Use DaoCloud public mirror (`docker.m.daocloud.io`) |
| `<domain>` | Use custom domain as priority, DaoCloud as fallback |

In interactive mode, the script presents three choices:

```
1) No mirror acceleration (default)
2) Use public mirror (docker.m.daocloud.io)
3) Use custom mirror domain
```

Example `daemon.json` when using `--mirror hub.example.com`:

```json
{
  "registry-mirrors": ["https://hub.example.com", "https://docker.m.daocloud.io"],
  "insecure-registries": ["hub.example.com"]
}
```

## Supported Distributions

### RPM-based (CentOS-compatible repo)

| Distribution | Versions | Repo Mapping |
|-------------|----------|--------------|
| CentOS / RHEL | 8, 9, 10 | el8/el9/el10 |
| Rocky Linux | 8, 9 | el8/el9 |
| AlmaLinux | 8, 9 | el8/el9 |
| Oracle Linux | 8, 9 | el8/el9 |
| openEuler | 20+ | 20→el8, 22+→el9 |
| OpenCloudOS | 9 | el9 |
| Anolis OS | 8, 23 | 8→el8, 23→el9 |
| Alibaba Cloud Linux | 3+ | el8 |
| Kylin | V10+ | el8 |
| Fedora | Latest | Fedora repo |

### Debian-based (APT repo)

| Distribution | Versions |
|-------------|----------|
| Ubuntu | 18.04, 20.04, 22.04, 24.04+ |
| Debian | 11 (Bullseye), 12 (Bookworm), 13 (Trixie) |
| Kali Linux | Latest (Debian-compatible repo) |

### Non-Linux

macOS and Windows users will see platform-specific Docker Desktop installation guidance.

## Install Source Failover

The script tries multiple mirror sources in order for best network compatibility:

1. Alibaba Cloud Mirror
2. Tencent Cloud Mirror
3. Huawei Cloud Mirror
4. USTC Mirror
5. Tsinghua University Mirror
6. Docker Official

## Features

- Multi-source automatic failover for package downloads
- Automatic fallback to binary install if package manager fails
- Docker Compose v2 auto-install
- Optional mirror acceleration (default: none)
- i18n support (English / Chinese)
- Non-interactive mode for automation (`--mode install --yes`)
- CI validation (17-distro matrix + ShellCheck)

## Development

### Run tests locally

```bash
bash tests/run_os_matrix.sh
```

### CI

- Workflow: `.github/workflows/os-compat-ci.yml`
- Trigger: `push` / `pull_request` to `main`
- Jobs:
  - **ShellCheck** — Static analysis
  - **RPM Matrix** — Rocky 8/9, CentOS Stream 10, Alma 8/9, Oracle 8/9, Anolis 23, OpenCloudOS 9, openEuler 24.03
  - **Debian Matrix** — Ubuntu 24.04/22.04/20.04, Debian 12/11
  - **Fedora Matrix** — Fedora 41/40

## License

MIT
