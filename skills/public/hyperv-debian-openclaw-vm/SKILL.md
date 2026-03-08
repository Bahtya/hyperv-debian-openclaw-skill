---
name: hyperv-debian-openclaw-vm
description: Use this skill when you need to build, repair, audit, or document a Debian GNOME virtual machine on Windows Hyper-V for OpenClaw and AI CLI tooling. It is specifically for workflows involving Hyper-V enablement, Debian cloud images, GNOME/gdm3, SSH/XRDP, Chrome, Clash Verge, and preinstalling OpenClaw, Codex, Gemini CLI, and Claude Code.
---

# Hyperv Debian Openclaw Vm

## Overview

This skill packages a proven workflow for producing a Debian GNOME VM on Windows Hyper-V with OpenClaw and related CLI tooling preinstalled. Use it when you need to provision from scratch, recover from broken display-manager/network/cloud-init states, or turn the process into repeatable host-side automation and documentation.

## Workflow

1. Run the host-side preflight check before touching the VM:
   `scripts/check_hyperv_prereqs.ps1`
2. Read [references/build-workflow.md](references/build-workflow.md) for the standard build order.
3. Read [references/pitfalls.md](references/pitfalls.md) if the request mentions cloud-init, mirror failures, tty login, GNOME not starting, SSH disconnects, or Hyper-V network drift.
4. Read [references/inventory.md](references/inventory.md) when you need to verify the target end state or compare a broken VM against the expected configuration.
5. Use `scripts/collect_vm_report.ps1` after changes to capture the Hyper-V side state and guest port reachability.

## Decision Rules

- Prefer Debian official `genericcloud` images over Live ISO when the goal is automation.
- Prefer `cidata.iso` over ad hoc virtual-disk seed media for NoCloud delivery.
- If host-side debugging is opaque in Hyper-V, finish the first provisioning pass in QEMU, then convert the result back to `vhdx`.
- If a China mirror returns repeated `403` for package pools, switch mirrors instead of retrying the same source.
- If GNOME packages are installed but the VM lands on `login:`, inspect:
  `systemctl status gdm3`
  `/etc/X11/default-display-manager`
  `/etc/systemd/system/display-manager.service`
- If the guest works in QEMU but loses DHCP in Hyper-V, inspect netplan for interface-name or MAC pinning introduced by cloud-init.

## Typical Requests

- "Build me a Debian GNOME VM on Hyper-V with OpenClaw, Codex, Gemini, Claude, Chrome, and Clash."
- "The VM only boots to tty login instead of GNOME."
- "Cloud-init worked in QEMU but the Hyper-V guest has no IP."
- "Write down the exact build steps, config inventory, and debugging playbook for this VM."
- "Collect the current Hyper-V VM state and compare it to the expected target."

## Resources

### scripts/

- `scripts/check_hyperv_prereqs.ps1`
  Use this first on the Windows host to verify admin rights, Windows edition, Hyper-V feature state, and virtualization prerequisites.
- `scripts/collect_vm_report.ps1`
  Use this after changes to capture Hyper-V VM state, attached disks, firmware, switch mapping, guest IPs, and optional SSH/RDP reachability.

### references/

- [references/build-workflow.md](references/build-workflow.md)
  The canonical provisioning order and decision points.
- [references/pitfalls.md](references/pitfalls.md)
  Read when debugging mirrors, cloud-init, GNOME/gdm3, tty fallback, or network drift.
- [references/inventory.md](references/inventory.md)
  The expected final host/guest/user/software state.

## Validation

- Run `scripts/check_hyperv_prereqs.ps1` on the host before provisioning.
- Run `scripts/collect_vm_report.ps1 -VmName <name> -GuestIp <ip>` after provisioning or repairs.
- Confirm the guest reaches the target described in [references/inventory.md](references/inventory.md).
