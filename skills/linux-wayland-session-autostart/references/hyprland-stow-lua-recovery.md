# Hyprland Lua recovery from a Stow source gap

Use when an active Hyprland session reports a missing Lua configuration although `~/.config/hypr/hyprland.lua` visibly exists as a symlink.

## Signal

```bash
test -L ~/.config/hypr/hyprland.lua && test ! -e ~/.config/hypr/hyprland.lua
```

The symlink is intact but its dotfiles source is absent. Do not replace it with a generic configuration.

## Proven recovery pattern

1. Identify the intended dotfiles source with `readlink -f` / the symlink target.
2. Inspect Git stashes before generating a replacement. For a stash made with `--include-untracked`, inspect `stash@{0}^3`; untracked config and helper files reside there rather than in the normal stash tree.
3. Restore the smallest coherent set to the dotfiles checkout:
   - `pc/.config/hypr/hyprland.lua`;
   - Lua override modules it `require`s;
   - helper executable(s) named by critical bindings.
4. Validate source before deployment:

```bash
luac -p pc/.config/hypr/hyprland.lua
bash -n pc/.local/share/bin/<helper>.sh
```

5. Commit/push only the recovered files. Re-deploy the relevant Stow package. Confirm the live config/helper paths resolve and are usable:

```bash
readlink -f ~/.config/hypr/hyprland.lua
test -s ~/.config/hypr/hyprland.lua
readlink -f ~/.local/share/bin/<helper>.sh
test -x ~/.local/share/bin/<helper>.sh
```

6. In the real graphical session, reload instead of restarting the compositor:

```bash
hyprctl reload
hyprctl configerrors
```

An empty `configerrors` result is required. Then inspect the exact live binding with `hyprctl binds -j` and verify the executable it launches; a registered Lua binding can still be inert when its helper is missing.

## Preservation boundary

Do not apply the entire stash, reset the working tree, or restart Hyprland solely to repair one missing source. Keep unrelated WIP in the stash and report reload validation separately from a future-login test.
