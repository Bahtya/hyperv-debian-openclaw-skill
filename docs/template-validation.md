# 可发布模板验证记录

这份记录对应的是 `templates/cloud-init/` 里的“可发布模板版” OpenClaw 虚拟机方案。

目标不是证明“这套 YAML 看起来合理”，而是证明它能在一台全新的 Hyper-V 虚拟机里完成首启配置，并把 OpenClaw、GNOME、XRDP、SSH 一起带起来。

## 验证时间

- 2026-03-09

## 验证方式

验证流程是完整重建，而不是在旧虚拟机上增量修补：

1. 使用 Debian 官方 `genericcloud` 基础镜像重新生成系统盘
2. 按模板渲染新的 `user-data` 和 `meta-data`
3. 重新打包 `cidata.iso`
4. 新建一台 Hyper-V 验证虚拟机并冷启动
5. 等待 `cloud-init` 全量执行完成
6. 检查 SSH、XRDP、GNOME、OpenClaw gateway 和模型调用

这轮验证的 VM 是：

- `Debian-Template-Validation`

## 这次修正了什么

这轮重建不是一次通过，中间确认并修掉了几类真实问题：

### 1. cloud-init 用户配置写法过时

模板原来仍然使用 `chpasswd`。  
这会带来弃用警告，也不利于模板长期维护。

现在改成：

- `users[].plain_text_passwd`

### 2. 首启安装链路对网络抖动过于敏感

在实际重建中，`npm install -g ...` 曾经因为 `ECONNRESET` 中断，导致 `cloud-init` 最终失败。

现在模板里增加了：

- `retry()` 重试函数
- `apt-get update/install` 重试
- Node.js 下载重试
- Chrome signing key 下载重试
- npm fetch retry 参数
- 把 `openclaw` 和其他 CLI 的全局安装拆成几步，降低一次性失败面

### 3. 验证虚拟机系统盘太小

第一次完整重建时，`pipewire` 解包阶段直接报：

- `No space left on device`

问题不在模板逻辑本身，而在验证盘仍然沿用了 cloud image 的原始小容量。

验证结论因此明确下来：

- 模板验证时，系统盘必须先扩容
- 这次实际用的是 `50GB`

### 4. gdm3 在首启后没有立即在线

之前模板只做了：

- `systemctl enable ssh xrdp gdm3`

这会导致服务被启用，但在首轮验证里 `gdm3` 可能仍然是 `inactive`，需要手动再拉起一次。

现在改成：

- `systemctl enable --now ssh xrdp gdm3`

这样首启结束后，图形登录管理器就已经在线。

## 最终通过的验证结果

在最后一轮完整重建里，模板通过了下面这些检查。

### cloud-init

- `cloud-init status --wait --long` 返回 `status: done`
- 数据源为 `DataSourceNoCloud [seed=/dev/sr0]`
- `errors: []`

### 系统与服务

- `ssh`: `active`
- `xrdp`: `active`
- `gdm3`: `active`
- `openclaw-gateway.service`: `active`

### 端口

- `22` 可达
- `3389` 可达
- `18789` 可达

### 预装软件

- Node.js: `v22.22.1`
- npm: `10.9.4`
- OpenClaw: `2026.3.7`
- Google Chrome: `145.0.7632.159`

### OpenClaw

- `openclaw gateway status --json` 返回 `rpc.ok: true`
- gateway 已监听 `0.0.0.0:18789`
- 使用模板里预置的 `zai/glm-5` provider 可以完成真实 agent 调用

## 结论

截至 2026-03-09，这套“可发布模板版” `cloud-init` 已经完成了一轮从零开始的完整重建验证。

它现在可以稳定做到：

- 用 Debian 官方 `genericcloud` 做基础盘
- 通过 `NoCloud` seed 首启注入配置
- 安装 GNOME、XRDP、SSH、Chrome、OpenClaw 和常用 AI CLI
- 自动启动 OpenClaw gateway daemon
- 让宿主机直接访问 OpenClaw Web UI

仍然需要模板使用者自己补的，依然是这些敏感配置：

- `ZAI_API_KEY`
- `OPENCLAW_GATEWAY_TOKEN`
- 如需飞书，再补 Feishu 凭据
