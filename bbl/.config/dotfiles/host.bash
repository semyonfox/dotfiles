# bbl Ubuntu host override, t_0e922822. No production or provider updater.
export EDITOR=vi VISUAL=vi
unset SDL_VIDEODRIVER WINE_CPU_TOPOLOGY STAGING_SHARED_MEMORY PROTON_LOG STEAM_RUNTIME_LAUNCH_DEBUG
unalias dprune cc cx oc gcheck gmodes pplus todo pomodoro zed 2>/dev/null || true
update() { "$HOME/.local/bin/bbl-update" "$@"; }
