# Normalized command history for the Hyper-V Debian OpenClaw VM build/recovery
# Working directory at start: C:\workspace\hyperv-debian-openclaw-skill\source

# 1. Hyper-V host checks
[Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent() | ForEach-Object { $_.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
(Get-ComputerInfo).WindowsEditionId
systeminfo
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All | Select-Object FeatureName, State | Format-Table -HideTableHeaders
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -like 'Microsoft-Hyper-V*' } | Select-Object FeatureName, State | Sort-Object FeatureName | Format-Table -HideTableHeaders
bcdedit /enum
bcdedit /set hypervisorlaunchtype auto
bcdedit /enum
Get-Service vmms,vmcompute | Select-Object Name, Status, StartType | Format-Table -HideTableHeaders
Get-VMHost | Select-Object ComputerName, LogicalProcessorCount, MemoryCapacity | Format-List

# 2. Hyper-V switch and disk checks
Get-VMSwitch | Select-Object Name, SwitchType, NetAdapterInterfaceDescription | Format-Table -HideTableHeaders
Get-PSDrive -Name C | Select-Object Name, @{Name='FreeGB';Expression={[math]::Round($_.Free/1GB,2)}}, @{Name='UsedGB';Expression={[math]::Round($_.Used/1GB,2)}} | Format-Table -HideTableHeaders
Get-PSDrive -Name D | Select-Object Name, @{Name='FreeGB';Expression={[math]::Round($_.Free/1GB,2)}}, @{Name='UsedGB';Expression={[math]::Round($_.Used/1GB,2)}} | Format-Table -HideTableHeaders

# 3. Debian live ISO exploration (abandoned)
Invoke-WebRequest -UseBasicParsing -Uri "https://mirrors.tuna.tsinghua.edu.cn/debian-cd/current-live/amd64/iso-hybrid/" | Select-Object -ExpandProperty Links | Select-Object href | Format-Table -HideTableHeaders
curl.exe -I -A "Mozilla/5.0" "https://mirrors.tuna.tsinghua.edu.cn/debian-cd/current-live/amd64/iso-hybrid/debian-live-13.3.0-amd64-gnome.iso"
curl.exe -L --http1.1 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" -H "Accept-Language: zh-CN,zh;q=0.9,en;q=0.8" -H "Referer: https://mirrors.tuna.tsinghua.edu.cn/debian-cd/current-live/amd64/iso-hybrid/" -r 0-1023 -o "C:\workspace\hyperv-debian-openclaw-skill\Downloads\debian-test.bin" "https://mirrors.tuna.tsinghua.edu.cn/debian-cd/current-live/amd64/iso-hybrid/debian-live-13.3.0-amd64-gnome.iso"
curl.exe -L -A "Debian APT-HTTP/1.3 (2.7.14)" -r 0-2047 -o "C:\workspace\hyperv-debian-openclaw-skill\Downloads\debian-test-apt.bin" "https://mirrors.tuna.tsinghua.edu.cn/debian-cd/current-live/amd64/iso-hybrid/debian-live-13.3.0-amd64-gnome.iso"
curl.exe -L -r 0-2047 -o "C:\workspace\hyperv-debian-openclaw-skill\Downloads\debian-test-http.bin" "http://mirrors.tuna.tsinghua.edu.cn/debian-cd/current-live/amd64/iso-hybrid/debian-live-13.3.0-amd64-gnome.iso"
Get-Content -Path "C:\workspace\hyperv-debian-openclaw-skill\Downloads\debian-live-13.3.0-amd64-gnome.iso" -TotalCount 20
cmd /c del /f /q C:\workspace\hyperv-debian-openclaw-skill\Downloads\debian-live-13.3.0-amd64-gnome.iso
cmd /c del /f /q C:\workspace\hyperv-debian-openclaw-skill\Downloads\debian-test-apt.bin C:\workspace\hyperv-debian-openclaw-skill\Downloads\debian-test-http.bin C:\workspace\hyperv-debian-openclaw-skill\Downloads\debian-test.bin

# 4. Create initial Hyper-V VM
New-Item -ItemType Directory -Path "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop" -Force
New-VM -Name "Debian-Desktop" -Generation 2 -MemoryStartupBytes 4GB -NewVHDPath "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\Debian-Desktop.vhdx" -NewVHDSizeBytes 80GB -SwitchName "Default Switch" -Path "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop"
Set-VMFirmware -VMName "Debian-Desktop" -EnableSecureBoot On -SecureBootTemplate MicrosoftUEFICertificateAuthority
Add-VMDvdDrive -VMName "Debian-Desktop"
Set-VMProcessor -VMName "Debian-Desktop" -Count 8
Set-VM -Name "Debian-Desktop" -DynamicMemory -MemoryMinimumBytes 2GB -MemoryMaximumBytes 8GB -AutomaticStopAction ShutDown -CheckpointType Disabled
Remove-VMHardDiskDrive -VMName "Debian-Desktop" -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 0
New-Item -ItemType Directory -Path "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop" -Force
New-VHD -Path "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\Debian-Desktop.vhdx" -SizeBytes 50GB -Dynamic
Add-VMHardDiskDrive -VMName "Debian-Desktop" -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 0 -Path "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\Debian-Desktop.vhdx"
cmd /c del /f /q C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\Debian-Desktop.vhdx

# 5. Discover Debian cloud images
curl.exe "https://cdimage.debian.org/images/cloud/trixie/latest/"
curl.exe "https://cdimage.debian.org/images/cloud/trixie/latest/debian-13-nocloud-amd64.json"
curl.exe "https://cdimage.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.json"
curl.exe "https://nodejs.org/dist/latest-v22.x/"
curl.exe -L "https://api.github.com/repos/clash-verge-rev/clash-verge-rev/releases/latest"
curl.exe -L "https://registry.npmjs.org/@openai%2fcodex/latest"
curl.exe -L "https://registry.npmjs.org/@google%2fgemini-cli/latest"
curl.exe -L "https://registry.npmjs.org/@anthropic-ai%2fclaude-code/latest"
curl.exe -L "https://registry.npmjs.org/openclaw/latest"

# 6. Install helper tools on Windows
winget install --id cloudbase.qemu-img --exact --accept-package-agreements --accept-source-agreements --disable-interactivity
winget install --id Microsoft.OSCDIMG --exact --accept-package-agreements --accept-source-agreements --disable-interactivity
winget install --id SoftwareFreedomConservancy.QEMU --exact --accept-package-agreements --accept-source-agreements --disable-interactivity

# 7. Build seed artifacts and download Debian images
curl.exe -L --output "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-nocloud-amd64.qcow2" "https://cdimage.debian.org/images/cloud/trixie/latest/debian-13-nocloud-amd64.qcow2"
curl.exe -L "https://cdimage.debian.org/images/cloud/trixie/latest/SHA512SUMS" | Select-String "debian-13-nocloud-amd64.qcow2"
(Get-FileHash "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-nocloud-amd64.qcow2" -Algorithm SHA512).Hash.ToLower()
& "C:\workspace\hyperv-debian-openclaw-skill\tools\qemu-img.exe" convert -p -f qcow2 -O vhdx -o subformat=dynamic "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-nocloud-amd64.qcow2" "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\Debian-Desktop-os.vhdx"
Resize-VHD -Path "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\Debian-Desktop-os.vhdx" -SizeBytes 50GB
& "C:\workspace\hyperv-debian-openclaw-skill\source\automation\debian-vm\build-seed.ps1"
& "C:\workspace\hyperv-debian-openclaw-skill\tools\oscdimg.exe" -j1 -lcidata -m -o "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\seed-files" "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\cidata.iso"

# 8. QEMU bootstrap attempts
"C:\workspace\hyperv-debian-openclaw-skill\tools\qemu-system-x86_64.exe" -machine q35 -accel tcg -m 4096 -smp 8 -cpu qemu64 -drive file=C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-nocloud-amd64.qcow2,if=virtio,format=qcow2 -cdrom C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\cidata.iso -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22 -display none -serial file:C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\qemu-serial.log -monitor none
"C:\workspace\hyperv-debian-openclaw-skill\tools\qemu-system-x86_64.exe" -machine q35 -accel tcg -m 4096 -smp 8 -cpu qemu64 -drive file=C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-nocloud-amd64.qcow2,if=virtio,format=qcow2 -cdrom C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\cidata.iso -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22 -display none -serial tcp:127.0.0.1:4444,server,nowait -monitor none

# 9. Switch to genericcloud image
curl.exe -L --output "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-genericcloud-amd64.qcow2" "https://cdimage.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
& "C:\workspace\hyperv-debian-openclaw-skill\tools\qemu-img.exe" resize "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-genericcloud-amd64.qcow2" 50G
"C:\workspace\hyperv-debian-openclaw-skill\tools\qemu-system-x86_64.exe" -machine q35 -accel tcg -m 4096 -smp 8 -cpu qemu64 -drive file=C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-genericcloud-amd64.qcow2,if=virtio,format=qcow2 -cdrom C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\cidata.iso -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22 -display none -serial file:C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\qemu-genericcloud-serial.log -monitor none

# 10. Guest-side provisioning over SSH in QEMU
ssh -p 2222 -i "%USERPROFILE%\.ssh\id_ed25519" claude@127.0.0.1 "sudo cloud-init status --wait"
ssh -p 2222 -i "%USERPROFILE%\.ssh\id_ed25519" claude@127.0.0.1 "sudo tail -n 120 /var/log/cloud-init-output.log"
ssh -p 2222 -i "%USERPROFILE%\.ssh\id_ed25519" claude@127.0.0.1 "sudo tail -n 120 /var/log/cloud-init.log"

# 11. Mirror and package fixes inside guest
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

# 12. Install Node and AI tools inside guest
curl -fsSLO https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt
curl -fsSLO https://nodejs.org/dist/latest-v22.x/node-v22.22.1-linux-x64.tar.xz
tar -C /usr/local --strip-components=1 -xJf node-v22.22.1-linux-x64.tar.xz
su - claude -c "npm config set prefix \"$HOME/.npm-global\""
su - claude -c "npm install -g @openai/codex @google/gemini-cli @anthropic-ai/claude-code openclaw"
su - claude -c "npm install -g --force --include=optional @openai/codex@latest"

# 13. Install Chrome and Clash inside guest
curl -fsSL -o /tmp/Clash.Verge_2.4.6_amd64.deb https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.4.6/Clash.Verge_2.4.6_amd64.deb
apt-get install -y /tmp/Clash.Verge_2.4.6_amd64.deb
curl -fsSLo /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt-get install -y /tmp/google-chrome-stable_current_amd64.deb

# 14. Localize guest and configure GNOME defaults
apt-get install -y ibus-libpinyin
update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh LC_TIME=zh_CN.UTF-8 LC_MONETARY=zh_CN.UTF-8 LC_MEASUREMENT=zh_CN.UTF-8 LC_PAPER=zh_CN.UTF-8 LC_ADDRESS=zh_CN.UTF-8 LC_NAME=zh_CN.UTF-8 LC_TELEPHONE=zh_CN.UTF-8
printf "user-db:user\nsystem-db:local\n" > /etc/dconf/profile/user
cat >/etc/dconf/db/local.d/00-gnome-local <<'EOF'
[org/gnome/shell]
favorite-apps=['org.gnome.Nautilus.desktop', 'google-chrome.desktop', 'org.gnome.Terminal.desktop', 'Clash Verge.desktop']

[org/gnome/desktop/interface]
clock-format='24h'

[org/gnome/system/locale]
region='zh_CN.UTF-8'

[org/gnome/desktop/input-sources]
sources=[('xkb', 'us'), ('ibus', 'libpinyin')]
EOF
dconf update
mkdir -p /home/claude/.config/autostart
cp "/usr/share/applications/Clash Verge.desktop" "/home/claude/.config/autostart/Clash Verge.desktop"

# 15. Switch desktop from XFCE to GNOME
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

# 16. Fix GNOME boot-to-tty issue through serial console
cat /etc/X11/default-display-manager
ls -l /etc/systemd/system/display-manager.service
echo 769876 | sudo -S systemctl start gdm3
printf "/usr/sbin/gdm3\n" > /etc/X11/default-display-manager
ln -sf /usr/lib/systemd/system/gdm.service /etc/systemd/system/display-manager.service
systemctl daemon-reload
systemctl start gdm3

# 17. Make Hyper-V-safe network configuration
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

# 18. Convert finished image back to Hyper-V
qemu-img convert -p -f qcow2 -O vhdx -o subformat=dynamic "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\images\debian-13-genericcloud-amd64.qcow2" "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\Debian-Desktop-os.vhdx"
Remove-VMHardDiskDrive -VMName "Debian-Desktop" -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 0
Add-VMHardDiskDrive -VMName "Debian-Desktop" -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 0 -Path "C:\workspace\hyperv-debian-openclaw-skill\HyperV\Debian-Desktop\Debian-Desktop-os.vhdx"
Set-VMDvdDrive -VMName "Debian-Desktop" -ControllerNumber 0 -ControllerLocation 1 -Path $null
Stop-VM -Name "Debian-Desktop" -TurnOff -Force
Start-VM -Name "Debian-Desktop"

# 19. Create and validate the example skill repo
python "C:\workspace\hyperv-debian-openclaw-skill\skills-local\codex\.system\skill-creator\scripts\init_skill.py" hyperv-debian-openclaw-vm --path "C:\workspace\hyperv-debian-openclaw-skill\skills\public" --resources scripts,references --interface display_name="Hyper-V Debian OpenClaw VM" --interface short_description="Build and repair a Debian GNOME VM for OpenClaw on Hyper-V" --interface default_prompt="Use $hyperv-debian-openclaw-vm to provision or repair a Debian GNOME VM with OpenClaw on Windows Hyper-V."
python "C:\workspace\hyperv-debian-openclaw-skill\skills-local\codex\.system\skill-creator\scripts\quick_validate.py" "C:\workspace\hyperv-debian-openclaw-skill\skills\public\hyperv-debian-openclaw-vm"
powershell -ExecutionPolicy Bypass -File "C:\workspace\hyperv-debian-openclaw-skill\skills\public\hyperv-debian-openclaw-vm\scripts\check_hyperv_prereqs.ps1"
powershell -ExecutionPolicy Bypass -File "C:\workspace\hyperv-debian-openclaw-skill\skills\public\hyperv-debian-openclaw-vm\scripts\collect_vm_report.ps1" -VmName "Debian-Desktop" -GuestIp "172.18.1.240"

# 20. Publish the example repo
git init -b main
git config user.name "Bahtya"
git config user.email "user@example.com"
git add .
git commit -m "Add Hyper-V Debian OpenClaw VM skill and playbook"
gh repo create Bahtya/hyperv-debian-openclaw-skill --public --source . --remote origin --push
git add .
git commit -m "Add final validation record and local skill install notes"
git tag -a v0.1.0 -m "Initial published skill release"
git push origin main --follow-tags
gh release create v0.1.0 --repo Bahtya/hyperv-debian-openclaw-skill --title "v0.1.0" --notes "Initial published example skill for building and repairing a Debian GNOME OpenClaw VM on Hyper-V."

# 21. Install the skill locally
robocopy "C:\workspace\hyperv-debian-openclaw-skill\skills\public\hyperv-debian-openclaw-vm" "C:\workspace\hyperv-debian-openclaw-skill\skills-local\codex\hyperv-debian-openclaw-vm" /E
robocopy "C:\workspace\hyperv-debian-openclaw-skill\skills\public\hyperv-debian-openclaw-vm" "C:\workspace\hyperv-debian-openclaw-skill\skills-local\agents\hyperv-debian-openclaw-vm" /E
