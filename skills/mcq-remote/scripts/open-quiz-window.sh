#!/usr/bin/env bash
# open a blank zen window on its own profile with marionette on 2829.
# separate profile = separate instance, so the everyday zen never gets
# navigator.webdriver. run on the laptop: ssh laptop bash -s < open-quiz-window.sh
set -euo pipefail

profile=$HOME/.local/share/zen-mcq
port=2829

if (exec 3<>/dev/tcp/127.0.0.1/$port) 2>/dev/null; then
    echo "marionette already listening on $port, reusing the open quiz window"
    exit 0
fi

mkdir -p "$profile"
# recommended remote prefs would reset session and update behaviour, keep them off
cat > "$profile/user.js" <<EOF
user_pref("marionette.port", $port);
user_pref("remote.prefs.recommended", false);
user_pref("browser.startup.page", 0);
user_pref("browser.startup.homepage", "about:blank");
user_pref("zen.welcome-screen.seen", true);
EOF

wl_socket=$(hyprctl instances -j | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["wl_socket"])')
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export WAYLAND_DISPLAY=$wl_socket
export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
export XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=Hyprland MOZ_ENABLE_WAYLAND=1

setsid -f zen-browser --profile "$profile" --marionette about:blank \
    </dev/null >/dev/null 2>&1

for _ in $(seq 70); do
    if (exec 3<>/dev/tcp/127.0.0.1/$port) 2>/dev/null; then
        echo "quiz window open, marionette on 127.0.0.1:$port"
        exit 0
    fi
    sleep 0.5
done
echo "marionette did not come up on $port within 35s" >&2
exit 1
