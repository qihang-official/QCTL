# Changelog

All notable changes to this project will be documented in this file.

## [v0.1.0-rc2] - 2026-03-05
### Added
- 线路模型重构：固定启航 AI 双线路（`cn` / `hk`）。
- 首次运行自动初始化（TTY）：自动探测最优线路、提示 API Key 获取地址、认证 + 余额校验、欢迎语输出。
- `qctl switch` 交互式切线（方向键 + 回车）与非交互模式 `--line --non-interactive`。
- billing 查询能力：`GET /v1/dashboard/billing/subscription`。
- 新增网络层单元测试与 CLI 交互选择测试。

### Changed
- 命令语义从 provider 切换为线路切换。
- `status --json` 字段从 `current_provider/provider_exists` 调整为 `current_line/line_exists`。
- 密钥存储从“按 provider”切换为“单全局 API Key（qhaigc/global）”。

### Removed
- 移除 `qctl providers list|add|remove|set-default`。
- 移除 `qctl switch provider <name>`。
- 移除 `providers.yaml` 读写与 provider 动态管理能力。

### Security
- 默认仅允许 user scope 写入。
- 不可信 `ANTHROPIC_BASE_URL` 默认拒绝。

### Notes
- 本次为 breaking 变更，不做 provider 迁移兼容。

## [v0.1.0-rc1] - 2026-03-05
### Added
- 初始可用 CLI：`init`、`status`、`providers`、`switch provider`、`test`、`doctor`、`backup`。
- Provider 线路域名族校验（`www -> api`，`www-hk -> api-hk`）与 Base URL 白名单校验。
- Claude settings 读写器（保留未知字段）与受管字段补丁。
- 原子写、快照备份、失败回滚能力。
- 凭证存储策略：keyring 优先，失败回退 AES-GCM 本地加密文件。
- `doctor` 基础检查：权限、scope 冲突、不可信 Base URL。
- 单元测试与命令流集成测试。
- CI 工作流（测试 + Linux 构建）。
- 版本信息注入与 `qctl version` 命令。

### Security
- 默认仅允许 user scope 写入。
- 不可信 `ANTHROPIC_BASE_URL` 默认拒绝，需显式 `--allow-untrusted-base-url`。

### Notes
- 当前发布目标平台为 Linux（amd64/arm64）。
- `doctor --fix` 目前只自动修复权限类问题。

