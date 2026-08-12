# SSH + Helium browser control for sensitive personal workflows

Use this only when Semyon explicitly asks to operate his own signed-in workstation browser over SSH, such as a purchase or account task. Treat credentials and payment details as secrets throughout.

## Read-only discovery

1. Probe the workstation alias first with a short BatchMode SSH timeout.
2. Confirm the target browser process exists and locate the live graphical session using `loginctl` plus `systemctl --user show-environment` for only these variables: `XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY`, `HYPRLAND_INSTANCE_SIGNATURE`, and `DBUS_SESSION_BUS_ADDRESS`.
3. Inspect `hyprctl clients -j` to find the Helium window and its geometry. Do not assume an SSH shell has the graphical-session environment.
4. For visual verification, run `grim` in the live Wayland session, copy the screenshot back, and inspect it. Do not relay screenshots containing entered credentials.

## Browser/input control

- Launch/focus Helium under the discovered graphical-session environment, using the absolute binary `/opt/helium-browser-bin/helium` if needed.
- Prefer keyboard navigation where possible. If pointer control is required, ensure `ydotoold` is running on the workstation and use screenshot-derived, current coordinates only; never hard-code coordinates as a reusable assumption.
- `wtype` key names are case-sensitive (`Tab` works). For literal text, pass the value as the sole quoted argument: `wtype "$value"`. Do **not** prepend `--`; that can make `wtype` reject the input instead of typing it.
- Immediately screenshot and verify page state after each major transition (login, journey selection, seat selection, payment handoff). Check focus before any sensitive input because a window/workspace change can send keystrokes to the wrong app.

## Secret transport discipline

- Never paste passwords, Bitwarden session values, card data, or account credentials into chat, command arguments, shell history, files, screenshots, or normal tool output.
- If a user has already explicitly authorized the workstation flow and a session value must be used, accept it only through a hidden terminal `read -s` prompt in a PTY. Keep it in a transient variable, retrieve only the required vault fields, and pipe them over SSH stdin into an already-focused workstation input process. SSH stdin is encrypted; command lines and output must remain secret-free.
- Parse vault JSON locally and never print it. Keep only non-secret status/error strings in output.
- Unset transient variables and lock the Bitwarden vault after the attempt, whether successful or not.

## Purchase boundary

- Reconfirm the journey, fare class, price, and passenger type from the live page before any payment initiation.
- Stop at a 3-D Secure/Revolut approval prompt and tell Semyon exactly what to approve. Do not claim a ticket exists until a booking confirmation/reference is visibly verified.
- If input validation or focus is uncertain, stop and verify rather than retrying credentials blindly.
