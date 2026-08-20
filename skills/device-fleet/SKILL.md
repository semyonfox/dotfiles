---
name: device-fleet
description: "Use when inspecting, SSHing into, configuring, or troubleshooting Semyon's server, NAS, PC, laptop, router, Tailscale, or T3 Code hosts."

metadata:
  harness: [claude, codex]
---

# Device Fleet

Work safely across Semyon's machines. Keep durable, non-secret facts in `references/computers.md`; device changes are higher risk than ordinary repo edits.

## Start safely

1. Read `references/computers.md` before selecting a target or access path.
2. If reachability may have changed, run `scripts/fleet-scout.sh` from this skill directory; set `FLEET_SSH_PROBE=1` only for useful remote read-only probes.
3. For T3 Code, first read `references/t3-code.md` and run `scripts/t3-audit.sh`.
4. Prefer SSH aliases in `~/.ssh/config`, then documented LAN IPs, then documented Tailscale IPs/MagicDNS. Test MagicDNS with `getent hosts <name>`; do not assume it works.
5. Probe with `ssh -o BatchMode=yes -o ConnectTimeout=8 <target> '<read-only command>'` so missing keys/passwords fail quickly.
6. Record newly discovered durable facts in `references/computers.md`, dated and marked verified, inferred, or stale.

## Safety boundaries

- Never read or document private-key contents, tokens, browser stores, password managers, recovery codes, or saved secrets; never record sudo passwords. For sudo, ask once in this conversation and state command and reason.
- Require explicit approval before reboot/power-cycle/reimage/repartition, storage-pool changes, router changes, public exposure, or firewall/VPN/Tailscale ACL changes.
- Start with `hostnamectl`, `uname`, `ip`, `ss`, `systemctl is-active/status`, `docker ps`, `tailscale status`, and SSH checks; avoid destructive discovery.
- Separate LAN-only, Tailscale-only, and stale paths. Preserve remote user work: check running sessions/jobs and dirty repositories before stopping services or changing directories.

## Remote pattern

Choose the suitable host: `server` is the default control node/always-on agent-T3 host; `nas` is storage/Docker/NAS (disks and shares are high risk); `pc` is LAN desktop/GPU/GUI work; `laptop` is mobile CachyOS, best documented over Tailscale, with T3 Code already on port `3773`.

For long work, use tmux:

```bash
ssh <target>
tmux new -As agent-<short-task-name>
```

Keep noninteractive SSH read-only unless a change was requested:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=8 <target> 'hostname; uname -a; ip -brief addr'
```

## T3 Code and Tailscale

Do **not** default to `npx t3@nightly serve`: the verified server setup uses global `t3` plus an enabled user systemd service. `references/t3-code.md` has the exact unit, wrappers, ports, and safe management commands. Read-only checks:

```bash
systemctl --user status t3-code-headless.service --no-pager -l
systemctl --user cat t3-code-headless.service --no-pager
journalctl --user -u t3-code-headless.service -n 80 --no-pager
```

Restart, enable, disable, or alter it only at user request. Never use Tailscale Funnel/public exposure without explicit request.

## Inventory

`references/computers.md` is canonical. Keep identity (hostname, aliases, role, OS/model, owner if needed); access (SSH, LAN, Tailscale/DNS, proxy/jump host, caveats); agent readiness (Codex, Node/npm/npx, tmux, Docker, T3, Ollama, browser/GUI); risks (storage, router, power, exposure, stale DNS, offline); and source/last-verified evidence. Summarize durable facts, not transient dumps.

## Resources

- `references/computers.md` — inventory/access matrix.
- `references/t3-code.md` — verified T3 installation/startup.
- `scripts/fleet-scout.sh` — safe non-sudo inventory refresh.
- `scripts/t3-audit.sh` — local/SSH T3 install/service audit.
