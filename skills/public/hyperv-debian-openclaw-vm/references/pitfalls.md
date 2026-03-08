# Pitfalls

## 何时阅读

当你遇到以下问题时阅读本文件：

- 虚拟机只进 tty `login:`
- `apt install` 大量失败
- cloud-init 跑过但 Hyper-V 里没网
- SSH 端口可达但会话立刻断开

## 清华源 403

症状：

- `apt update` 可能成功
- 具体 `.deb` 包在 `pool/` 路径返回 `403 Forbidden`

处理：

- 不要继续死磕清华源
- 切到 USTC 或 Debian 官方源

## `nocloud` 镜像首启落到 `systemd-firstboot`

症状：

- 串口出现 first boot 向导

处理：

- 改用 `genericcloud`

## QEMU 网卡名带入 Hyper-V

症状：

- QEMU 正常联网
- Hyper-V 起机后不配网

根因：

- `50-cloud-init.yaml` 绑定了 `enp0s2` 和 QEMU MAC

处理：

- 禁用 cloud-init 后续网络配置接管
- 改成通配 `en*` / `eth*`
- 用 `networkd` renderer，除非你明确装了 `NetworkManager`

## GNOME 装了但没进图形登录

症状：

- 出现 `debian-desktop login:`

重点排查：

- `/etc/X11/default-display-manager`
- `/etc/systemd/system/display-manager.service`
- `systemctl status gdm3`

典型修复：

- 把默认显示管理器改成 `/usr/sbin/gdm3`
- 让 `display-manager.service` 指向 `/usr/lib/systemd/system/gdm.service`

## `network-manager` postinst 失败

症状：

- `dpkg --configure -a` 卡在 `network-manager`
- 报 `The group netdev already exists and is not a system group`

处理：

- 把已有普通组 `netdev` 改名
- 重新创建系统组 `netdev`
- 再次 `dpkg --configure -a`

## SSH 端口通但会话立刻关闭

不要第一时间把它判断成系统没起来。

先确认：

- `gdm3` 是否正常
- 登录管理器链路是否完整
- 来宾串口是否能进 shell

很多时候 SSH 异常只是显示管理器和用户态服务尚未稳定后的副作用。
