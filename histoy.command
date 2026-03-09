# Filtered command history for the Hyper-V Debian OpenClaw VM workflow
# Scope: cloud-init/image preparation -> QEMU bootstrap -> Hyper-V attach -> host-side port/UI checks
# Working directory at start: C:\workspace\hyperv-debian-openclaw-skill\source

# 1. Discover Debian cloud images and required package sources
curl.exe "https://cdimage.debian.org/images/cloud/trixie/latest/"
curl.exe "https://cdimage.debian.org/images/cloud/trixie/latest/debian-13-nocloud-amd64.json"
curl.exe "https://cdimage.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.json"
curl.exe "https://nodejs.org/dist/latest-v22.x/"
curl.exe -L "https://api.github.com/repos/clash-verge-rev/clash-verge-rev/releases/latest"
curl.exe -L "https://registry.npmjs.org/@openai%2fcodex/latest"
curl.exe -L "https://registry.npmjs.org/@google%2fgemini-cli/latest"
curl.exe -L "https://registry.npmjs.org/@anthropic-ai%2fclaude-code/latest"
curl.exe -L "https://registry.npmjs.org/openclaw/latest"

# 2. Install helper tools on Windows
winget install --id cloudbase.qemu-img --exact --accept-package-agreements --accept-source-agreements --disable-interactivity
winget install --id Microsoft.OSCDIMG --exact --accept-package-agreements --accept-source-agreements --disable-interactivity
winget install --id SoftwareFreedomConservancy.QEMU --exact --accept-package-agreements --accept-source-agreements --disable-interactivity

# 3. Download Debian cloud images and prepare the seed artifacts
curl.exe -L --output "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-nocloud-amd64.qcow2" "https://cdimage.debian.org/images/cloud/trixie/latest/debian-13-nocloud-amd64.qcow2"
curl.exe -L "https://cdimage.debian.org/images/cloud/trixie/latest/SHA512SUMS" | Select-String "debian-13-nocloud-amd64.qcow2"
(Get-FileHash "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-nocloud-amd64.qcow2" -Algorithm SHA512).Hash.ToLower()
& "C:\workspace\hyperv-debian-openclaw-skill\tools\qemu-img.exe" convert -p -f qcow2 -O vhdx -o subformat=dynamic "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-nocloud-amd64.qcow2" "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\Debian-Desktop-os.vhdx"
Resize-VHD -Path "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\Debian-Desktop-os.vhdx" -SizeBytes 50GB
& "C:\workspace\hyperv-debian-openclaw-skill\source\automation\debian-vm\build-seed.ps1"
& "C:\workspace\hyperv-debian-openclaw-skill\tools\oscdimg.exe" -j1 -lcidata -m -o "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\seed-files" "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\cidata.iso"

# 4. Switch to the genericcloud image and resize it
curl.exe -L --output "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-genericcloud-amd64.qcow2" "https://cdimage.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
& "C:\workspace\hyperv-debian-openclaw-skill\tools\qemu-img.exe" resize "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-genericcloud-amd64.qcow2" 50G

# 5. Bootstrap the guest in QEMU with the cloud-init seed
"C:\workspace\hyperv-debian-openclaw-skill\tools\qemu-system-x86_64.exe" -machine q35 -accel tcg -m 4096 -smp 8 -cpu qemu64 -drive file=C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-genericcloud-amd64.qcow2,if=virtio,format=qcow2 -cdrom C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\cidata.iso -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22 -display none -serial file:C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\qemu-genericcloud-serial.log -monitor none
ssh -p 2222 -i "%USERPROFILE%\.ssh\id_ed25519" claude@127.0.0.1 "sudo cloud-init status --wait"
ssh -p 2222 -i "%USERPROFILE%\.ssh\id_ed25519" claude@127.0.0.1 "sudo tail -n 120 /var/log/cloud-init-output.log"
ssh -p 2222 -i "%USERPROFILE%\.ssh\id_ed25519" claude@127.0.0.1 "sudo tail -n 120 /var/log/cloud-init.log"

# 6. Provision the guest: mirrors, desktop, OpenClaw, Chrome, Clash, locale
cat >/etc/apt/sources.list.d/localmirror.sources <<'EOF'
Types: deb
URIs: http://mirrors.ustc.edu.cn/debian/
Suites: trixie trixie-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://mirrors.ustc.edu.cn/debian-security/
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
apt-get update
apt-get install -y ca-certificates curl wget git git-lfs jq unzip ripgrep build-essential python3 python3-pip python3-venv gh dbus-x11 xauth xorg xfce4 lightdm xrdp xorgxrdp fonts-noto-cjk
systemctl enable ssh xrdp lightdm
systemctl set-default graphical.target
curl -fsSLO https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt
curl -fsSLO https://nodejs.org/dist/latest-v22.x/node-v22.22.1-linux-x64.tar.xz
tar -C /usr/local --strip-components=1 -xJf node-v22.22.1-linux-x64.tar.xz
su - claude -c "npm config set prefix \"$HOME/.npm-global\""
su - claude -c "npm install -g @openai/codex @google/gemini-cli @anthropic-ai/claude-code openclaw"
su - claude -c "npm install -g --force --include=optional @openai/codex@latest"
curl -fsSL -o /tmp/Clash.Verge_2.4.6_amd64.deb https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge_2.4.6_amd64.deb
apt-get install -y /tmp/Clash.Verge_2.4.6_amd64.deb
curl -fsSLo /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt-get install -y /tmp/google-chrome-stable_current_amd64.deb
apt-get install -y ibus-libpinyin
update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh LC_TIME=zh_CN.UTF-8 LC_MONETARY=zh_CN.UTF-8 LC_MEASUREMENT=zh_CN.UTF-8 LC_PAPER=zh_CN.UTF-8 LC_ADDRESS=zh_CN.UTF-8 LC_NAME=zh_CN.UTF-8 LC_TELEPHONE=zh_CN.UTF-8

# 7. Switch to GNOME and repair display-manager/network pieces
printf "gdm3 shared/default-x-display-manager select gdm3\n" | debconf-set-selections
apt-get install -y gdm3 gnome-shell gnome-session task-gnome-desktop
groupmod -n netdev-user netdev
addgroup --system netdev
usermod -aG netdev claude
dpkg --configure -a
apt-get purge -y xfce4 xfce4-* lightdm lightdm-gtk-greeter
apt-get autoremove -y
printf "[Desktop]\nSession=gnome\n" > /home/claude/.dmrc
printf "gnome-session\n" > /home/claude/.xsession
systemctl disable lightdm
systemctl restart gdm3
printf "/usr/sbin/gdm3\n" > /etc/X11/default-display-manager
ln -sf /usr/lib/systemd/system/gdm.service /etc/systemd/system/display-manager.service
systemctl daemon-reload
systemctl start gdm3
cat >/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg <<'EOF'
network: {config: disabled}
EOF
cat >/etc/netplan/01-generic-dhcp.yaml <<'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    all-en:
      match:
        name: "en*"
      dhcp4: true
      dhcp6: true
    all-eth:
      match:
        name: "eth*"
      dhcp4: true
      dhcp6: true
EOF
rm -f /etc/netplan/50-cloud-init.yaml
netplan generate

# 8. Convert the configured image back to VHDX and attach it to Hyper-V
qemu-img convert -p -f qcow2 -O vhdx -o subformat=dynamic "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-genericcloud-amd64.qcow2" "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\Debian-Desktop-os.vhdx"
Remove-VMHardDiskDrive -VMName "Debian-Desktop" -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 0
Add-VMHardDiskDrive -VMName "Debian-Desktop" -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 0 -Path "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\Debian-Desktop-os.vhdx"
Set-VMDvdDrive -VMName "Debian-Desktop" -ControllerNumber 0 -ControllerLocation 1 -Path $null
Stop-VM -Name "Debian-Desktop" -TurnOff -Force
Start-VM -Name "Debian-Desktop"

# 9. Host-side validation: ports and OpenClaw reachability
powershell -ExecutionPolicy Bypass -File "C:\workspace\hyperv-debian-openclaw-skill\skills\public\hyperv-debian-openclaw-vm\scripts\collect_vm_report.ps1" -VmName "Debian-Desktop" -GuestIp "<guest-ip>"
Test-NetConnection -ComputerName "<guest-ip>" -Port 22
Test-NetConnection -ComputerName "<guest-ip>" -Port 3389
Test-NetConnection -ComputerName "<guest-ip>" -Port 18789
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL -i "%USERPROFILE%\.ssh\id_ed25519" claude@<guest-ip> "export PATH=\"$HOME/.npm-global/bin:$HOME/.local/bin:/usr/local/bin:$PATH\"; openclaw gateway status --json"

# 10. Host-side OpenClaw Web UI access
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL -i "%USERPROFILE%\.ssh\id_ed25519" -N -L 18789:127.0.0.1:18789 claude@<guest-ip>
start "" "http://127.0.0.1:18789/#token=<gateway-token>"
