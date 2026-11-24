---
name: device-fleet
description: Use when inspecting, SSHing into, configuring, or troubleshooting Semyon's server, NAS, PC, laptop, router, Tailscale, or T3 Code hosts.

metadata:
  harnesses: [claude, codex, opencode, cursor, gemini, hermes]
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

## Dotfiles on laptop and pc

There `~/dotfiles` is the live config. Hyprland, noctalia, scripts and user units point into it, and Hyprland reloads the moment a file changes. A stash, checkout, merge or rebase removes files for a moment, and Hyprland keeps that error until the next reload (2026-11-17: a stash left the laptop on "cannot open hyprland.lua").

- Don't stash there to deploy. `git merge` works on a dirty tree when the dirty files don't overlap. When they do, ask first.
- After any git command that rewrites files there, run `hyprctl reload` and check `hyprctl configerrors` is empty. Over SSH, set `XDG_RUNTIME_DIR=/run/user/$(id -u)` and `HYPRLAND_INSTANCE_SIGNATURE=$(ls $XDG_RUNTIME_DIR/hypr | head -1)` first.

## Laptop browser quizzes

Use the `mcq-remote` skill to take over a quiz or browser tab on the laptop.

## T3 Code and Tailscale

Do **not** default to `npx t3@nightly serve`. The server runs T3's native runtime (`~/.t3/runtime/versions/<ver>/t3`) under upstream `t3code.service`, which T3 installs and updates itself (`t3 update`). The old custom `t3-code-headless.service` and its wrappers were removed on 2026-11-18. `references/t3-code.md` has history. Read-only checks:

```bash
systemctl --user status t3code.service --no-pager -l
systemctl --user cat t3code.service --no-pager
journalctl --user -u t3code.service -n 80 --no-pager
```

Restart, enable, disable, or alter it only at user request. Never use Tailscale Funnel/public exposure without explicit request.

## Inventory

`references/computers.md` is canonical. Keep identity (hostname, aliases, role, OS/model, owner if needed); access (SSH, LAN, Tailscale/DNS, proxy/jump host, caveats); agent readiness (Codex, Node/npm/npx, tmux, Docker, T3, Ollama, browser/GUI); risks (storage, router, power, exposure, stale DNS, offline); and source/last-verified evidence. Summarize durable facts, not transient dumps.

## Resources

- `references/computers.md` — inventory/access matrix.
- `references/t3-code.md` — verified T3 installation/startup.
- `scripts/fleet-scout.sh` — safe non-sudo inventory refresh.
- `scripts/t3-audit.sh` — local/SSH T3 install/service audit.
