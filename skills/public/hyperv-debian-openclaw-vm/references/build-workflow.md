# Build Workflow

## 何时阅读

在以下场景先阅读本文件：

- 要在 Windows Hyper-V 上新建 Debian GNOME 虚拟机
- 要把 OpenClaw、Codex、Gemini、Claude、Chrome、Clash 一次性预装进去
- 要把一次性手工过程整理成可复用自动化流程

## 标准流程

1. 宿主机预检
2. 启用并验证 Hyper-V
3. 创建 Hyper-V 虚拟机骨架
4. 选择 Debian `genericcloud` 镜像
5. 用 `cidata.iso` 提供 cloud-init 数据
6. 在 QEMU 中完成首轮装机和修复
7. 完成来宾内软件安装和本地化
8. 把 `qcow2` 转回 `vhdx`
9. 冷启动 Hyper-V 验证

## 宿主机预检

必须确认：

- 当前 PowerShell 有管理员权限
- Windows 版本支持 Hyper-V
- `systeminfo` 显示虚拟化已在固件中启用

优先检查命令：

- `Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All`
- `systeminfo`
- `bcdedit /enum`

## 镜像选型

优先级：

1. `genericcloud`
2. 其他 cloud image
3. Live ISO 仅用于人工安装

不要默认使用：

- `nocloud` 镜像做首轮无人值守装机
- Live GNOME ISO 做零交互自动化

## 推荐的装机策略

先在 QEMU 中完成：

- cloud-init
- 软件安装
- 网络修复
- 显示管理器修复
- 本地化

然后再转回 Hyper-V。

这样更容易：

- 观察串口
- 直接 SSH
- 低成本回滚

## 预装内容建议

系统包：

- `gdm3`
- `gnome-shell`
- `gnome-session`
- `xrdp`
- `google-chrome-stable`
- `clash-verge`
- `ibus-libpinyin`

开发环境：

- Node 22
- `python3`
- `git`
- `gh`

npm 全局包：

- `@openai/codex`
- `@google/gemini-cli`
- `@anthropic-ai/claude-code`
- `openclaw`

## 最终验收

至少验证：

- `22` 端口
- `3389` 端口
- `gdm3` 启动
- GNOME 图形登录界面
- `codex`, `gemini`, `claude`, `openclaw`
- Chrome 和 Clash 桌面入口
