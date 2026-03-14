# Hyprland Locking System Configuration

## System Overview

Your locking system is built on **swaylock** (lock screen) + **swayidle** (idle daemon) with systemd integration.

### Why This Stack?
- **swaylock**: Wayland-native, lightweight, no complex dependencies
- **swayidle**: Reliable idle timeout management with event hooks
- **systemd**: Manages daemon lifecycle, survives Hyprland crashes
- **Caffeine mode**: Full inhibit of auto-lock/sleep when needed

---

## Configuration Files

### User Configuration (Already Set)
✓ **Swaylock config:** `~/.config/swaylock/config`
  - Catppuccin Mocha theme with Hyprland colors
  - Blur effect, vignette, password masking
  - Grace period: 2 seconds

✓ **Swayidle service:** `~/.config/systemd/user/swayidle.service`
  - Auto-starts on login
  - Part of graphical-session.target

✓ **Swayidle wrapper:** `~/.local/share/bin/swayidle-start.sh`
  - Manages idle timeline with caffeine mode support
  - Respects caffeine lock file to disable all timeouts

✓ **Hyprland config:** Updated to start swayidle service
  - Removed old hypridle daemon
  - Line 41: `exec-once = systemctl --user start swayidle`

✓ **Keybindings:** Updated in `~/.config/hypr/keybindings.conf`
  - Super+L: `swaylock -f` (direct lock)

### System Configuration (Requires SUDO - See Below)
⚠️ **SDDM session:** Not yet configured - needs `/etc/sddm.conf.d/hyprland.conf`
⚠️ **Power management:** Not yet configured - needs `/etc/systemd/logind.conf.d/`

---

## Auto-Lock and Sleep Timeline

When **caffeine mode is OFF** (default):

| Time | Action | Command |
|------|--------|---------|
| 4 min (240s) | Screen dims to 20% | `brightnesscontrol.sh s 0.2` |
| 5 min (300s) | Lock screen appears | `swaylock -f` |
| 6 min (360s) | Display power off | `swaymsg "output * power off"` |
| 30 min (1800s) | System suspends | `systemctl suspend` |

When **caffeine mode is ON**:
- All timeouts disabled
- Swayidle service stops
- Screen stays on, system doesn't auto-lock/sleep

---

## Keybindings

| Keybind | Action |
|---------|--------|
| **Super+L** | Lock screen immediately |
| **Power Button** | Sleep (after system setup) |
| **Lid Close** | Lock screen (after system setup) |
| **Click waybar ☕** | Toggle caffeine mode |

### Manual Caffeine Toggle
```bash
~/.local/share/bin/caffeine-toggle.sh
```

---

## System Setup (SUDO Required)

Run this script to complete the configuration:

```bash
sudo bash ~/setup-locking-system.sh
```

This script does:
1. Sets Hyprland as default SDDM session
2. Configures systemd-logind for power button (→ sleep) and lid switch (→ lock)
3. Reloads systemd daemon
4. Confirms swayidle service is enabled

**After running:** Restart your system or run:
```bash
sudo systemctl restart systemd-logind
```

---

## What Gets Removed

- ❌ `hypridle` daemon (old, was crashing)
- ❌ `hyprlock` screen (replaced by swaylock)
- ❌ Manual `loginctl lock-session` (now using swaylock directly)

---

## Troubleshooting

### Swayidle not starting on login
```bash
# Check service status
systemctl --user status swayidle

# Start manually
systemctl --user start swayidle

# View logs
journalctl --user -u swayidle -f
```

### Lock screen not appearing
```bash
# Test swaylock directly
swaylock -f

# Check swaylock config
cat ~/.config/swaylock/config
```

### Caffeine mode not working
```bash
# Check if lock file exists
ls -la /tmp/caffeine-mode.lock

# Manually toggle (resets state)
~/.local/share/bin/caffeine-toggle.sh
```

### Brightness restoration on wake from sleep
- Requires `brightnesscontrol.sh` script in `~/.local/share/bin/`
- Should exist in your system; if not, adjust swayidle-start.sh resume commands

### Lid switch or power button not working
- These require system-level setup (`setup-locking-system.sh`)
- Must be run with `sudo`

---

## Advanced: Custom Idle Timings

To change idle timings, edit `~/.local/share/bin/swayidle-start.sh`:

```bash
timeout 240 '...'  # Change 240 to desired seconds
```

Then restart swayidle:
```bash
systemctl --user restart swayidle
```

---

## Notes

- Swayidle respects `idlehint` for external idle inhibitors (Firefox fullscreen, etc.)
- Caffeine mode is per-session; status is stored in `/tmp/caffeine-mode.lock`
- Before-sleep hooks ensure lock happens even on manual suspend via UI

---

**Last Updated:** March 11, 2026
**System:** Hyprland on CachyOS with Wayland
