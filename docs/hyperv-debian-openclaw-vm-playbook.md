# Hyper-V Debian OpenClaw VM 制作与排障手册

## 目标

本文档记录一次在 Windows 11 + Hyper-V 上制作 Debian GNOME 虚拟机的完整过程，目标环境用于运行：

- OpenClaw
- Codex CLI
- Gemini CLI
- Claude Code
- Google Chrome
- Clash Verge

最终虚拟机形态：

- Hyper-V 二代虚拟机
- Debian 13
- GNOME + gdm3
- XRDP 与 SSH 可访问
- 用户名 `claude`
- 示例实验密码 `769876`

说明：

- 该密码仅适合一次性实验环境，不应直接照搬到长期环境。
- 本次制作中，清华源在当前网络出口对大量 `.deb` 返回 `403`，最终改用中科大镜像完成系统包安装。

## 最终配置清单

### 宿主机

- Windows 11 专业版
- Hyper-V 已启用
- 虚拟交换机：`Default Switch`
- 虚拟机名：`Debian-Desktop`
- CPU：8 vCPU
- 内存：4 GB 启动，动态内存 2-8 GB
- 系统盘：`C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\Debian-Desktop-os.vhdx`
- 系统盘容量：50 GB

### 来宾机

- Debian 13
- 时区：`Asia/Shanghai`
- 语言：`zh_CN.UTF-8`
- 中文输入法：`ibus-libpinyin`
- 显示管理器：`gdm3`
- 桌面环境：`GNOME`
- 远程访问：`ssh`、`xrdp`

### 预装软件

- `node` 22.22.1
- `npm` 10.9.4
- `python3` 3.13.5
- `git` 2.47.3
- `gh` 2.46.0
- `@openai/codex` 0.111.0
- `@google/gemini-cli` 0.32.1
- `@anthropic-ai/claude-code` 2.1.71
- `openclaw` 2026.3.2
- `google-chrome-stable` 145.0.7632.159
- `clash-verge` 2.4.6

## 制作步骤

### 1. 启用 Hyper-V

宿主机先确认以下条件：

- 当前账号具备管理员权限
- Windows 版本支持 Hyper-V
- BIOS/UEFI 已启用虚拟化

关键检查项：

- `Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All`
- `systeminfo`
- `bcdedit /enum`

启用后需要确认：

- `Microsoft-Hyper-V*` 相关特性全部 `Enabled`
- `hypervisorlaunchtype` 为 `Auto`
- 重启后 `systeminfo` 显示 `A hypervisor has been detected`

### 2. 创建 Hyper-V 虚拟机骨架

创建一台二代虚拟机：

- Generation 2
- Switch 选择 `Default Switch`
- Secure Boot 模板选择 `MicrosoftUEFICertificateAuthority`
- 预留 DVD 驱动器用于后续种子盘

### 3. 放弃 Live ISO 图形安装路线

最初尝试使用 Debian Live GNOME ISO。

问题：

- Live GNOME 安装路径不适合做真正零交互自动化
- 清华镜像对当前网络/客户端指纹存在访问限制
- PowerShell、curl、BITS 等多种下载方式被拒绝或返回封禁页

结论：

- 不再走 Live ISO 图形安装
- 改为 Debian 官方 cloud image + cloud-init 路线

### 4. 选择正确的 Debian cloud image

尝试过两类镜像：

- `nocloud`
- `genericcloud`

实际结果：

- `nocloud` 镜像会在第一次引导时落到 `systemd-firstboot` 交互流程
- `genericcloud` 镜像自带 `cloud-init`、`cloud-initramfs-growroot`、`openssh-server`，更适合自动化

最终选型：

- 使用 Debian 官方 `debian-13-genericcloud-amd64.qcow2`

### 5. 用 QEMU 完成首轮自动化，再回灌 Hyper-V

直接在 Hyper-V 里调试 cloud-init 成本很高，日志观察也不方便。

最终采用双阶段方案：

1. 在 QEMU 中挂载 `genericcloud` 镜像和 `cidata.iso`
2. 通过 `hostfwd=tcp::2222-:22` 暴露 SSH
3. 先在 QEMU 里完成系统安装、软件预装、桌面切换和本地化
4. 完成后把 `qcow2` 转成 `vhdx`
5. 再把成品盘挂回 Hyper-V

这是本次流程里最关键的工程化决策。

### 6. cloud-init 数据源设计

尝试过两种 NoCloud 介质：

- VHDX 种子盘
- `cidata.iso`

更稳定的方案是：

- 用 `cidata.iso`
- 盘标使用标准小写 `cidata`

包含文件：

- `meta-data`
- `user-data`

### 7. 来宾系统内安装软件

安装分为两层：

- 系统包：桌面环境、显示管理器、XRDP、Chrome 依赖、输入法等
- 用户级 npm 全局包：OpenClaw / Codex / Gemini / Claude

Node 选择策略：

- Debian 自带 `nodejs` 不保证满足 OpenClaw 最新要求
- 直接安装 Node 官方 `latest-v22.x` 的 Linux x64 二进制包

npm 全局安装：

- 使用 `~/.npm-global`
- 为 `claude` 写入 `PATH`

### 8. 桌面环境从 XFCE 切换为 GNOME

中间阶段为了快速打通图形与远程桌面，曾暂时使用：

- `XFCE`
- `lightdm`

后续按需求切回：

- `GNOME`
- `gdm3`

并清理：

- `xfce4`
- `lightdm`
- `lightdm-gtk-greeter`

### 9. 中国本地化

最终完成的本地化内容：

- 时区：`Asia/Shanghai`
- locale：`zh_CN.UTF-8`
- GNOME 区域：`zh_CN.UTF-8`
- 中文输入法：`ibus-libpinyin`
- 24 小时制
- GNOME 收藏夹含 Chrome / Terminal / Clash Verge

### 10. 结果回灌 Hyper-V

在 QEMU 环境中完成修复后，使用 `qemu-img`：

- `qcow2 -> vhdx`

然后：

- 关闭 Hyper-V VM
- 卸载旧盘
- 挂载新 `vhdx`
- 卸载种子 ISO
- 冷启动验证

## 探索过程中踩过的坑

### 坑 1：清华源目录能访问，但大量 `.deb` 下载返回 403

现象：

- `apt update` 可能成功
- `apt install` 对大量包池路径返回 `403 Forbidden`
- 同一个源内，不同包命中结果不一致

结论：

- 当前网络出口下，清华源不稳定，不适合作为本流程的实际安装源
- 实装时切换到 USTC 镜像

### 坑 2：Debian Live GNOME ISO 不适合零交互自动安装

现象：

- 图形安装流程需要人工操作
- 不利于复用和调试

结论：

- 放弃 Live ISO
- 改用 `genericcloud` 镜像

### 坑 3：`nocloud` 镜像会掉进 `systemd-firstboot`

现象：

- 首启串口出现 first boot 向导
- 不是 cloud-init 主流程

结论：

- 对这种自动化构建场景优先用 `genericcloud`

### 坑 4：cloud-init 网络配置绑定了 QEMU 的网卡名和 MAC

现象：

- 在 QEMU 中网络正常
- 转回 Hyper-V 后系统起来但不配网

根因：

- `/etc/netplan/50-cloud-init.yaml` 把 DHCP 写死在 `enp0s2` + QEMU MAC

修复：

- 禁用 cloud-init 后续网络接管
- 使用通配名的 netplan：
  - `en*`
  - `eth*`
- renderer 改为系统存在的 `networkd`

### 坑 5：GNOME 已安装，但启动后只落到 tty login

现象：

- 控制台显示 `debian-desktop login:`
- 不是 GNOME 图形登录界面

根因：

- `/etc/X11/default-display-manager` 仍残留 `lightdm`
- `/etc/systemd/system/display-manager.service` 缺失

修复：

- 写回 `/usr/sbin/gdm3`
- 重建 `display-manager.service -> /usr/lib/systemd/system/gdm.service`

### 坑 6：Hyper-V 下 SSH 偶发“端口通但会话立即关闭”

现象：

- `22` 端口可达
- SSH 在 `banner` 或 `kex_exchange_identification` 阶段被远端关闭

处理方式：

- 不把它当成桌面环境失败的证据
- 优先从串口和 QEMU 侧继续修系统
- 等显示管理器和网络链路稳定后再回查 SSH

## 调试方案

### 宿主机侧

常用检查：

- `Get-VM`
- `Get-VMHardDiskDrive`
- `Get-VMDvdDrive`
- `Get-VMFirmware`
- `Get-VMNetworkAdapter`
- `Get-NetNeighbor -InterfaceAlias "vEthernet (Default Switch)"`
- `Test-NetConnection <ip> -Port 22`
- `Test-NetConnection <ip> -Port 3389`

### 来宾机串口/控制台

关键判断：

- 是否到达 `login:` 提示
- `systemctl is-active gdm3`
- `systemctl is-active ssh`
- `cat /etc/X11/default-display-manager`
- `ls -l /etc/systemd/system/display-manager.service`

### cloud-init/首启问题

重点看：

- `/var/log/cloud-init.log`
- `/var/log/cloud-init-output.log`
- 自定义首启脚本日志

### 桌面问题

优先检查：

- `gdm3` 是否安装
- `gdm.service` 是否可手动启动
- `display-manager.service` 是否指向 `gdm.service`
- `default-display-manager` 是否错误残留为 `lightdm`

### 网络问题

优先检查：

- `/etc/netplan/*.yaml`
- 是否存在 QEMU 专属 MAC 绑定
- renderer 是否指向未安装的 NetworkManager

## 环境清单

### Windows 工具

- Hyper-V PowerShell 模块
- `qemu-img`
- QEMU
- `oscdimg`
- `gh`

### Debian 关键组件

- `gdm3`
- `gnome-shell`
- `gnome-session`
- `xrdp`
- `google-chrome-stable`
- `clash-verge`
- `ibus-libpinyin`
- Node 22
- npm 全局 AI CLI

## 复用建议

如果以后要把本流程封装成 skill，建议拆成：

- 宿主机预检
- cloud image 选型
- QEMU 首装
- Hyper-V 回灌
- GNOME 修复
- 本地化
- 最终验收

这样技能正文可以保持简洁，而把细节都沉到 references 和脚本里。
