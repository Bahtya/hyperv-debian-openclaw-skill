# Inventory

## 何时阅读

当你需要核对“最终应交付成什么样”时阅读本文件。

## 宿主机

- Hyper-V enabled
- Generation 2 VM
- Secure Boot template: `MicrosoftUEFICertificateAuthority`
- 8 vCPU
- 4 GB startup memory
- 2-8 GB dynamic memory
- 50 GB VHDX on `D:`

## 来宾机

- Debian 13
- GNOME
- gdm3
- xrdp
- ssh
- Asia/Shanghai
- zh_CN.UTF-8
- ibus-libpinyin

## 用户

- username: `claude`
- shell: `/bin/bash`
- sudo: enabled
- example lab password: `769876`

## AI / 开发工具

- Node 22
- npm 10
- Python 3
- Git
- GitHub CLI
- Codex CLI
- Gemini CLI
- Claude Code
- OpenClaw

## 桌面工具

- Google Chrome
- Clash Verge

## 验收端口

- SSH: `22`
- XRDP: `3389`

## GNOME 关键文件

- `/etc/X11/default-display-manager`
- `/etc/systemd/system/display-manager.service`
- `/home/claude/.dmrc`
- `/home/claude/.xsession`
