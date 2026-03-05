# QCTL (Qihang CLI)

QCTL 是面向 Linux/SSH 场景的 Claude Code 配置管理 CLI，固定对接启航 AI，并提供 CN/HK 双线路切换能力。

## 功能特性
- 固定供应商：仅启航 AI。
- 线路管理：CN/HK 双线路，`qctl switch` 交互切换（方向键 + 回车）。
- 首次运行自动初始化（TTY）：自动探测最优线路、提示 API Key 获取地址、校验并读取余额。
- Claude settings 安全写入：原子替换、自动备份、失败回滚。
- 凭证管理：系统 keyring 优先，回退本地 AES-GCM 加密存储。
- 安全防护：Base URL 白名单、线路域名族一致性校验。
- 诊断能力：`qctl test` 与 `qctl doctor`。

## 快速开始
### 0. 一键下载安装并运行（推荐）
```bash
curl -fsSL https://raw.githubusercontent.com/qihang-official/QCTL/main/scripts/install.sh | bash
```

指定版本安装：
```bash
curl -fsSL https://raw.githubusercontent.com/qihang-official/QCTL/main/scripts/install.sh | bash -s -- v0.1.0-rc2
```

### 1. 构建
```bash
go build -o qctl ./cmd/qctl
```

### 1.1 创建软连接（可直接输入 qctl）
方案 A（推荐，系统级）：
```bash
sudo ln -sf "$(pwd)/qctl" /usr/local/bin/qctl
```

方案 B（无 sudo，用户级）：
```bash
mkdir -p "$HOME/.local/bin"
ln -sf "$(pwd)/qctl" "$HOME/.local/bin/qctl"
export PATH="$HOME/.local/bin:$PATH"
```

验证：
```bash
qctl version
```

### 2. 首次初始化（交互）
```bash
./qctl init
```

### 3. 非交互初始化（脚本/CI）
```bash
export QHAIGC_API_KEY='sk-xxx'
./qctl init --line cn --api-key-env QHAIGC_API_KEY --non-interactive
```

### 4. 切换线路
```bash
./qctl switch
./qctl switch --line hk --non-interactive
```

### 5. 查看状态
```bash
./qctl status
./qctl status --json
```

## 常用命令
- `qctl init [--line <cn|hk|qhaigc-cn|qhaigc-hk>] [--api-key <key>] [--api-key-env <ENV>] [--model <sonnet|opus|haiku>] [--non-interactive]`
- `qctl switch [--line <cn|hk|qhaigc-cn|qhaigc-hk>] [--non-interactive]`
- `qctl status [--json] [--no-probe]`
- `qctl test [--line <name>] [--latency] [--auth]`
- `qctl doctor [--fix]`
- `qctl backup list|restore <id>`
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

## 安全说明
- 默认仅允许 `user scope` 写入。
- 默认仅信任：`api.qhaigc.net`、`api-hk.qhaigc.net`。
- 测试或无 keyring 环境可设置：`QCTL_DISABLE_KEYRING=1`。

## 开发与测试
```bash
make fmt
make vet
make test
```

## 发布准备
### 配置自动发布到分发仓库
- 仓库变量：`RELEASE_REPOSITORY`，值示例：`qihang-official/QCTL`。
- 仓库密钥：`RELEASE_REPO_TOKEN`，需要对分发仓库有 `contents:write` 权限（PAT 或 Fine-grained token）。
- 未配置 `RELEASE_REPOSITORY` 时，默认发布到当前仓库。
- `main` 分支每次更新会自动同步以下文件到分发仓库 `main`：`scripts/install.sh`、`README.md`、`CHANGELOG.md`。

### 本地发布检查
```bash
make release-check
```

### 构建发布包
```bash
make release-build VERSION=v0.1.0-rc1
```

发布产物输出到：`dist/<version>/`
- `qctl-linux-amd64.tar.gz`
- `qctl-linux-arm64.tar.gz`
- `sha256sums.txt`
