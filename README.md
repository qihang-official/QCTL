# QCTL (Qihang CLI)

QCTL 是一个面向 Linux/SSH 场景的 CLI 工具，用于统一管理 Claude Code 所需的启航 AI 配置，支持 CN/HK 双线路切换与安全写入。

## 为什么用 QCTL
- 一条命令完成初始化：自动探测线路、引导录入 Key、写入 Claude 配置。
- 双线路切换简单：交互式 `qctl switch` 或脚本化参数切换。
- 配置写入更安全：原子替换、自动备份、失败回滚。
- 凭证存储更稳妥：优先系统 keyring，回退本地 AES-GCM 加密存储。
- 自带诊断能力：`qctl test` 与 `qctl doctor` 快速定位网络/配置问题。

## 适用场景
- 在服务器、开发机、跳板机上快速完成 Claude Code 环境接入。
- 团队希望固定对接启航 AI，不允许随意更换 Base URL。
- 需要可审计、可恢复的配置变更流程。

## 快速开始
### 一键安装（推荐）
```bash
curl -fsSL https://raw.githubusercontent.com/qihang-official/QCTL/main/scripts/install.sh | bash
```

默认行为：
- 自动创建软链接。
- 交互终端中自动执行 `qctl init`。
- 非交互环境中自动执行 `qctl version`。

只安装、不自动运行：
```bash
curl -fsSL https://raw.githubusercontent.com/qihang-official/QCTL/main/scripts/install.sh | QCTL_AUTO_RUN=0 bash
```

安装指定版本：
```bash
curl -fsSL https://raw.githubusercontent.com/qihang-official/QCTL/main/scripts/install.sh | bash -s -- v0.1.0-rc2
```

### 从源码构建
```bash
go build -o qctl ./cmd/qctl
```

创建软链接（便于直接使用 `qctl`）：
```bash
sudo ln -sf "$(pwd)/qctl" /usr/local/bin/qctl
qctl version
```

无 sudo 方案：
```bash
mkdir -p "$HOME/.local/bin"
ln -sf "$(pwd)/qctl" "$HOME/.local/bin/qctl"
export PATH="$HOME/.local/bin:$PATH"
qctl version
```

## 常见使用流程
### 1) 首次初始化（交互）
```bash
qctl init
```

### 2) 脚本/CI 初始化（非交互）
```bash
export QHAIGC_API_KEY='sk-xxx'
qctl init --line cn --api-key-env QHAIGC_API_KEY --non-interactive
```

### 3) 切换线路
```bash
qctl switch
qctl switch --line hk --non-interactive
```

### 4) 查看状态
```bash
qctl status
qctl status --json
```

## 命令总览
- `qctl init [--line <cn|hk|qhaigc-cn|qhaigc-hk>] [--api-key <key>] [--api-key-env <ENV>] [--model <sonnet|opus|haiku>] [--non-interactive]`
- `qctl switch [--line <cn|hk|qhaigc-cn|qhaigc-hk>] [--non-interactive]`
- `qctl status [--json] [--no-probe]`
- `qctl test [--line <name>] [--latency] [--auth]`
- `qctl doctor [--fix]`
- `qctl backup list|restore <id>`
- `qctl completion <shell>`
- `qctl version`

## 固定线路
- `cn`
  - 官网：`https://www.qhaigc.net`
  - API：`https://api.qhaigc.net`
- `hk`
  - 官网：`https://www-hk.qhaigc.net`
  - API：`https://api-hk.qhaigc.net`

## 配置路径
- QCTL 主目录：`~/.config/qctl/`
- QCTL 全局配置：`~/.config/qctl/config.yaml`
- Claude 用户配置：`~/.claude/settings.json`

## 安全边界
- 默认仅允许 `user scope` 写入。
- 默认仅信任 `api.qhaigc.net`、`api-hk.qhaigc.net`。
- 测试或无 keyring 环境可设置 `QCTL_DISABLE_KEYRING=1`。

## 开发与测试
```bash
make fmt
make vet
make test
```

## 发布
### 自动发布到分发仓库
- 仓库变量：`RELEASE_REPOSITORY`（示例：`qihang-official/QCTL`）。
- 仓库密钥：`RELEASE_REPO_TOKEN`（需对分发仓库具备 `contents:write` 权限）。
- 未配置 `RELEASE_REPOSITORY` 时，默认发布到当前仓库。
- `main` 分支每次更新会自动同步到分发仓库 `main`：`scripts/install.sh`、`README.md`、`CHANGELOG.md`。

### 本地发布检查
```bash
make release-check
```

### 构建发布包
```bash
make release-build VERSION=v0.1.0-rc1
```

产物位于 `dist/<version>/`：
- `qctl-linux-amd64.tar.gz`
- `qctl-linux-arm64.tar.gz`
- `sha256sums.txt`
