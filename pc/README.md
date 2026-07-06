# PC Profile

Desktop-specific notes and machine profile for this PC.

## Profile

- Machine profile: `pc`
- Hypridle: lock after 10 minutes, display off after 15 minutes, no automatic suspend
- Power helper: `~/.local/bin/power-mode.sh auto` applies performance-first CPU/GPU policy
- GPU tuning owner: LACT daemon, not Waybar

## GPU

See `.config/dotfiles/pc/gpu-rx6600xt-lact.md`.

The local system service source is recorded under `.config/dotfiles/pc/gpu/`:

- `.config/dotfiles/pc/gpu/apply-gpu-profile.sh`
- `.config/dotfiles/pc/gpu/gpu-performance-oc.service`
- `.config/dotfiles/pc/gpu/restore-amdgpu-overdrive.sh`
