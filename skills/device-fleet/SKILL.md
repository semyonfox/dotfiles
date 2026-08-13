---
name: device-fleet
description: "Use when inspecting, SSHing into, configuring, or troubleshooting Semyon's machines — server, NAS, PC, laptop, router, Tailscale, or T3 Code hosts. Follow the documented inventory and safe remote-access workflow."

metadata:
  harness: [codex]
---

# Device Fleet

## Overview

Use this skill to work safely across Semyon's personal machines. Keep durable facts in `references/computers.md`, refresh them with non-secret discovery, and treat device changes as higher-risk than normal repo edits.

## First Steps

1. Read `references/computers.md` before choosing a target device or access path.
2. If reachability might have changed, run `scripts/fleet-scout.sh` from this skill directory. Set `FLEET_SSH_PROBE=1` only when remote read-only probes are useful.
3. For T3 Code, read `references/t3-code.md` and run `scripts/t3-audit.sh` before giving instructions or changing services.
4. Prefer existing SSH aliases in `~/.ssh/config`; fall back to documented LAN IPs, then documented Tailscale IPs or MagicDNS names.
5. Use `ssh -o BatchMode=yes -o ConnectTimeout=8 <target> '<read-only command>'` for probes so missing keys or passwords fail quickly.
6. Update `references/computers.md` after discovering new durable facts. Mark facts as verified, inferred, or stale, and include the date.

## Safety Rules

- Never read private key contents, tokens, browser stores, password managers, recovery codes, or saved secrets while documenting the fleet.
- Do not record sudo passwords. If a task needs sudo, ask once in the current conversation and explain the exact command and reason.
- Do not reboot, power-cycle, reimage, repartition, modify storage pools, alter router settings, expose services publicly, or change firewall/VPN/Tailscale ACLs without explicit user approval.
- Avoid destructive discovery. Use `hostnamectl`, `uname`, `ip`, `ss`, `systemctl is-active/status`, `docker ps`, `tailscale status`, and SSH connectivity checks before using heavier tools.
- Separate LAN-only, Tailscale-only, and stale access paths. Do not assume MagicDNS works; test it with `getent hosts <name>` first.
- Preserve user work on remote machines. Check for running sessions, active jobs, or dirty repositories before stopping services or changing directories.

## Remote Work Pattern

Use the machine best suited to the task:

- `server`: default control node and always-on agent/T3 Code host.
- `nas`: storage and Docker/NAS work; treat disks and shares as high risk.
- `pc`: desktop/GPU/GUI-adjacent work on the LAN.
- `laptop`: mobile CachyOS machine, currently best documented over Tailscale; T3 Code is already listening on port `3773`.

For long-running shell work, use tmux when available:

```bash
ssh <target>
tmux new -As agent-<short-task-name>
```

When running noninteractive commands through SSH, keep them read-only unless the user asked for a change:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=8 <target> 'hostname; uname -a; ip -brief addr'
```

## T3 Code And Tailscale

Do not default to `npx t3@nightly serve` for Semyon's fleet. The verified server setup uses an installed global `t3` binary plus an enabled user systemd service. Read `references/t3-code.md` for the exact unit, wrapper scripts, ports, and safe management commands.

Safe read-only checks:

```bash
systemctl --user status t3-code-headless.service --no-pager -l
systemctl --user cat t3-code-headless.service --no-pager
journalctl --user -u t3-code-headless.service -n 80 --no-pager
```

Only restart, enable, disable, or alter the service when the user asks for that change. Do not use Tailscale Funnel or public internet exposure unless the user explicitly asks for it.

## Inventory Maintenance

Use `references/computers.md` as the canonical fleet inventory. Keep it practical:

- Identity: hostname, aliases, role, OS, model, owner/user if needed.
- Access: SSH alias, LAN IP, Tailscale IP/DNS, proxy/jump host, known caveats.
- Agent readiness: Codex, Node/npm/npx, tmux, Docker, T3 Code, Ollama, browser/GUI availability.
- Risk notes: storage, router, power, service exposure, stale DNS, offline devices.
- Evidence: command/source and last-verified date.

Do not copy transient command dumps into the inventory unless they will help future agents. Summarize the durable parts and leave one-line evidence.

## Resources

- `references/computers.md`: canonical device inventory and access matrix.
- `references/t3-code.md`: verified T3 Code installation and startup details.
- `scripts/fleet-scout.sh`: safe non-sudo discovery report for refreshing the inventory.
- `scripts/t3-audit.sh`: local or SSH T3 Code service/install audit.
