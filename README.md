# easydocker

本仓库已按 `SeanChang/docker_proxy` 的 `docker.sh` 进行严格对齐，并在此基础上做以下增量：

- 清理非必要文档（仅保留本 README）
- 增加并验证 RHEL 系 `7/8/9/10` 支持（RHEL 10 使用兼容仓库策略）
- 提供本地 Docker 矩阵测试脚本
- 提供 GitHub Actions CI 自动验证

## 本地测试

```bash
bash tests/run_os_matrix.sh
```

## CI

- 工作流文件: `.github/workflows/os-compat-ci.yml`
- 触发: `push` / `pull_request`
- 校验矩阵: RHEL 7/8/9/10
