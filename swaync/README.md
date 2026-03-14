# SwayNC Configuration

SwayNC is a notification daemon for Wayland that displays notifications in a modern, customizable interface. This package contains the configuration and styling.

## Overview

SwayNC provides:
- **Notification daemon** for Wayland-based desktops (Hyprland, Sway, etc.)
- **Customizable appearance** with theme support
- **Catppuccin Mocha theme** for consistency
- **Layout and behavior** configuration
- **Control center** for managing notifications

## Deployment

### Prerequisites

Install SwayNC (if not already installed):

```bash
sudo pacman -S swaynotificationcenter  # Arch/CachyOS
sudo apt install sway-notification-center  # Ubuntu/Debian
sudo dnf install sway-notification-center  # Fedora
brew install sway-notification-center     # macOS
```

### Deploy with Stow

```bash
cd ~/dotfiles
stow swaync
```

This creates symlinks from `~/.config/swaync/` to the repository files.

Verify deployment:

```bash
ls -la ~/.config/swaync/
# Should show symlinks to ~/dotfiles/swaync/.config/swaync/
```

### Deploy with Related Packages

Deploy with Hyprland and Waybar:

```bash
cd ~/dotfiles
stow hyprland waybar swaync
```

Or all packages:

```bash
cd ~/dotfiles
stow home hyprland waybar swaync
```

## File Structure

```
swaync/
└── .config/swaync/
    ├── config.json         # Main configuration (layout, behavior)
    └── style.css           # Theme and styling (Catppuccin Mocha)
```

## Configuration

### Main Configuration (config.json)

Controls SwayNC behavior:

```json
{
  "positionX": "right",        // Horizontal position: left, center, right
  "positionY": "top",          // Vertical position: top, center, bottom
  "layer": "overlay",          // Window layer: overlay, top, bottom
  "control-center-positionX": "right",
  "control-center-positionY": "top",
  "control-center-width": 400,
  "control-center-height": 600,
  "control-center-margin-top": 10,
  "control-center-margin-bottom": 10,
  "control-center-margin-right": 10,
  "control-center-margin-left": 10,
  "notification-icon-size": 48,
  "notification-body-image-height": 100,
  "notification-body-image-width": 200,
  "timeout": 10,               // Default timeout in seconds
  "timeout-critical": 0,       // Critical notifications: 0 = no timeout
  "notification-window-width": 500,
  "keyboard-shortcuts": true,
  "image-visibility": "when-available"
}
```

### Key Settings

- **Position**: Where notifications appear on screen
- **Timeout**: How long before notification auto-dismisses
- **Control Center**: Persistent notification history window
- **Keyboard Shortcuts**: `j`/`k` for navigation, `space` to dismiss
- **Icon Size**: Size of notification icons
- **Image Visibility**: Show/hide notification images

### Styling (style.css)

Catppuccin Mocha color scheme:

```css
/* Catppuccin Mocha Variables */
@define-color crust #11111b;
@define-color mantle #181825;
@define-color base #1e1e2e;
@define-color surface0 #313244;
@define-color surface1 #45475a;
@define-color surface2 #585b70;
@define-color overlay0 #6c7086;
@define-color overlay1 #7f849c;
@define-color overlay2 #9399b2;
@define-color subtext0 #a6adc8;
@define-color subtext1 #bac2de;
@define-color text #cdd6f4;
@define-color rosewater #f5e0dc;
@define-color flamingo #f2cdcd;
@define-color pink #f5c2e7;
@define-color mauve #cba6f7;
@define-color red #f38ba8;
@define-color maroon #eba0ac;
@define-color peach #fab387;
@define-color yellow #f9e2af;
@define-color green #a6e3a1;
@define-color teal #94e2d5;
@define-color sky #89dceb;
@define-color sapphire #74c7ec;
@define-color blue #89b4fa;
@define-color lavender #b4befe;
```

## Starting SwayNC

### Manual Start

```bash
swaync &
swaync-client  # Show control center
```

### Auto-Start with Hyprland

Add to `~/.config/hypr/hyprland.conf`:

```conf
exec-once = swaync
```

Or use Hyprland's startup script in your HyDE config.

### Systemd User Service (Optional)

Create `~/.config/systemd/user/swaync.service`:

```ini
[Unit]
Description=SwayNC notification daemon
After=graphical-session-pre.target
PartOf=graphical-session.target

[Service]
Type=dbus
BusName=org.freedesktop.Notifications
ExecStart=/usr/bin/swaync
Restart=on-failure

[Install]
WantedBy=graphical-session.target
```

Enable and start:

```bash
systemctl --user enable swaync
systemctl --user start swaync
```

## Usage

### Key Bindings (Default)

- `j` - Next notification
- `k` - Previous notification
- `Space` - Dismiss notification
- `a` - Dismiss all
- `q` - Close control center

### Control Center Commands

```bash
# Show control center
swaync-client -t

# Close control center
swaync-client -t

# Toggle control center
swaync-client --toggle-control-center

# Get notification count
swaync-client -c

# Dismiss notifications
swaync-client -d all
```

### Integration with Scripts

Use SwayNC in Hyprland keybindings:

```conf
# .config/hypr/hyprland.conf
bind = SUPER, N, exec, swaync-client --toggle-control-center
bind = SUPER, X, exec, swaync-client -d all
```

## Customization

### Edit Configuration

After deployment:

```bash
nvim ~/.config/swaync/config.json
nvim ~/.config/swaync/style.css
```

Or edit in repository:

```bash
nvim ~/dotfiles/swaync/.config/swaync/config.json
cd ~/dotfiles
stow -R swaync
```

### Custom Colors

Modify CSS variables in `style.css`:

```css
/* Override specific color */
@define-color red #f38ba8;      /* Catppuccin red */
@define-color red #ff0000;      /* Custom red */
```

### Notification Position

Change position in `config.json`:

```json
{
  "positionX": "right",   // left, center, right
  "positionY": "top"      // top, center, bottom
}
```

### Adjust Timeouts

```json
{
  "timeout": 10,          // Regular notifications: 10 seconds
  "timeout-critical": 0   // Critical: never auto-dismiss
}
```

## Troubleshooting

### SwayNC Not Showing Notifications

```bash
# Check if daemon is running
pgrep swaync

# Start manually
swaync

# Check logs
journalctl -xe | grep swaync

# Verify D-Bus
busctl list | grep -i notification
```

### Notifications Not Dismissing

```bash
# Check timeout settings
cat ~/.config/swaync/config.json | jq .timeout

# Verify key bindings
grep -E "^bind|Space" ~/.config/hypr/hyprland.conf
```

### Style Changes Not Applied

```bash
# Reload SwayNC
pkill swaync
swaync &

# Check CSS syntax
cat ~/.config/swaync/style.css | head -20
```

### Control Center Not Opening

```bash
# Check toggle command
swaync-client --toggle-control-center

# Check for errors
swaync-client --help

# Restart daemon
systemctl --user restart swaync  # if using systemd
# or
pkill swaync && swaync &
```

## D-Bus Integration

SwayNC registers as the standard D-Bus notification service:

```
Service: org.freedesktop.Notifications
Path: /org/freedesktop/Notifications
```

This means applications using the standard D-Bus notification API will automatically use SwayNC.

### Test Notifications

```bash
# Send test notification via D-Bus
notify-send "Title" "Message"
notify-send -u critical "Critical" "Urgent message"

# With icon
notify-send -i notification-camera-flash "Photo" "Picture taken"
```

## Advanced Configuration

### Application-Specific Behavior

You can configure timeout and behavior per application in more advanced setups:

```json
{
  "app-timeout": {
    "discord": 0,       // Discord notifications never auto-dismiss
    "slack": 5,         // Slack dismisses after 5 seconds
    "gmail": 10         // Gmail: 10 seconds (default)
  }
}
```

Check SwayNC documentation for current capabilities.

### Performance Optimization

For large notification volumes:

```json
{
  "max-notifications": 50,    // Limit notification queue
  "notification-icon-size": 32  // Smaller icons = less memory
}
```

## Integration with System

### Hyprland Integration

SwayNC works seamlessly with Hyprland:
- Respects Hyprland monitor configuration
- Appears in correct position on multi-monitor setups
- Uses Wayland protocol for window positioning

### Audio Feedback

Add notification sound (optional):

```bash
# Install sound player (if not present)
sudo pacman -S pulsemixer alsa-utils

# Configure in Hyprland or shell
alias notify='notify-send && paplay /usr/share/sounds/freedesktop/stereo/complete.oga'
```

## Performance

SwayNC is lightweight (~30MB memory):
- Minimal CPU usage when idle
- Efficient notification handling
- Responsive to keyboard/mouse input

## Attribution

- **SwayNC Project**: https://github.com/ErikReider/SwayNotificationCenter
- **Catppuccin**: Color scheme and theming
  - Website: https://catppuccin.com/

## Related Packages

- **`hyprland/`** - Hyprland window manager (desktop environment)
- **`waybar/`** - Status bar (often used alongside SwayNC)
- **`home/`** - Shell configuration with notification aliases

## References

- **SwayNC GitHub**: https://github.com/ErikReider/SwayNotificationCenter
- **D-Bus Notifications Spec**: https://dbus.freedesktop.org/doc/dbus-daemon.1.html
- **Catppuccin Mocha**: https://catppuccin.com/palette
- **Freedesktop Notification API**: https://specifications.freedesktop.org/notification-spec/

