# Final Validation Record

## Scope

This file records the final observed state of the Hyper-V Debian OpenClaw VM build used to produce this repository and skill example.

## Verified Successes

- Hyper-V was enabled successfully on the Windows host.
- A Debian 13 VM was provisioned on Hyper-V.
- The guest was rebuilt around a GNOME + gdm3 desktop stack.
- Google Chrome was installed successfully.
- Clash Verge was installed successfully.
- OpenClaw, Codex CLI, Gemini CLI, and Claude Code were installed for the `claude` user.
- The VM was localized for China-oriented usage:
  - timezone `Asia/Shanghai`
  - locale `zh_CN.UTF-8`
  - GNOME region `zh_CN.UTF-8`
  - `ibus-libpinyin`
- The example skill passed `quick_validate.py`.
- The host-side scripts executed successfully during validation:
  - `check_hyperv_prereqs.ps1`
  - `collect_vm_report.ps1`
- The skill was published to GitHub:
  - `https://github.com/Bahtya/hyperv-debian-openclaw-skill`
- The skill was copied into both local skill trees:
  - `~/.codex/skills/hyperv-debian-openclaw-vm`
  - `~/.agents/skills/hyperv-debian-openclaw-vm`

## Important Deviations

- The original requirement requested Tsinghua mirrors.
- In this environment, Tsinghua mirrors returned repeated `403 Forbidden` responses for many `.deb` package paths.
- The effective installation therefore switched to USTC mirrors for Debian system packages.

## Residual Risk / Follow-up

- During late-stage Hyper-V validation, TCP port checks for `22` and `3389` were successful, but interactive SSH sessions were intermittently closed immediately by the guest.
- This did not block continuing via QEMU/serial-based recovery, but it means final Hyper-V SSH stability should be re-checked in a follow-up pass.
- GNOME display-manager startup was repaired by restoring:
  - `/etc/X11/default-display-manager -> /usr/sbin/gdm3`
  - `/etc/systemd/system/display-manager.service -> /usr/lib/systemd/system/gdm.service`

## Example Target State

- VM name: `Debian-Desktop`
- Generation: `2`
- CPU: `8`
- Startup memory: `4 GB`
- Dynamic memory: enabled
- System disk: `50 GB VHDX`
- Desktop: `GNOME`
- Display manager: `gdm3`
- Remote access: `SSH`, `XRDP`
- Primary user: `claude`

## Recommended Next Validation Pass

1. Cold boot the Hyper-V guest.
2. Confirm GNOME graphical login appears instead of tty login.
3. Confirm XRDP login works.
4. Confirm SSH no longer closes immediately after connection.
5. Re-run `scripts/collect_vm_report.ps1` with the current guest IP.
