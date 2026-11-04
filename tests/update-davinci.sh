#!/usr/bin/env bash
# drives update-davinci with stubs for everything that touches the network or root
set -u

repo="$(cd "$(dirname "$0")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
stubs="$root/stubs"
mkdir -p "$stubs"
export TRACE="$root/trace"
export HOME="$root/home"
export XDG_CACHE_HOME="$root/cache"
export XDG_DOWNLOAD_DIR="$root/downloads"
export DF_AVAIL=500
unset TERMINAL

stub() {
    printf '#!/usr/bin/env bash\n%s\n' "$2" > "$stubs/$1"
    chmod +x "$stubs/$1"
}

stub pacman 'printf "pacman %s\n" "$*" >> "$TRACE"
[[ $1 == -Q ]] && { [[ -n ${INSTALLED:-} ]] || exit 1; printf "davinci-resolve-studio %s-1\n" "$INSTALLED"; }
exit 0'
stub sudo 'printf "sudo %s\n" "$*" >> "$TRACE"
[[ $1 == -n ]] && { [[ ${SUDO_OK:-0} == 1 ]]; exit; }
exit 0'
stub curl 'printf "curl %s\n" "$*" >> "$TRACE"
for a in "$@"; do
    case "$a" in
        */latest-stable-version/*) printf "{\"linux\":{\"downloadId\":\"abc\"}}"; exit 0 ;;
        */register/us/download/*) printf "%s" "${DOWNLOAD_URL:-https://sw.blackmagicdesign.com/DaVinciResolve/v21.1.2/DaVinci_Resolve_Studio_21.1.2_Linux.zip?Signature=x}"; exit 0 ;;
    esac
done
while [[ $# -gt 0 ]]; do [[ $1 == -o ]] && { : > "$2"; break; }; shift; done'
stub bsdtar 'exit 0'
stub git 'printf "git %s\n" "$*" >> "$TRACE"; exit 0'
stub makepkg 'printf "makepkg %s pkgver=%s srcdest=%s\n" "$*" "$(sed -n "s/^pkgver=//p" PKGBUILD)" "$SRCDEST" >> "$TRACE"
grep -B1 "patchelf --set-rpath" PKGBUILD | grep -q "chrome-sandbox.*continue" && bash -n PKGBUILD && printf "recipe-skips-sandbox\n" >> "$TRACE"
[[ ${BUILD_FAILS:-0} == 1 ]] && exit 1
: > "davinci-resolve-studio-$(sed -n "s/^pkgver=//p" PKGBUILD)-1-x86_64.pkg.tar.zst"'
stub pgrep '[[ ${RESOLVE_RUNNING:-0} == 1 ]]'
stub df 'printf "Avail\n%sG\n" "$DF_AVAIL"'
stub vercmp 'if [[ $1 == "$2" ]]; then echo 0; elif [[ $(printf "%s\n%s\n" "$1" "$2" | sort -V | head -n 1) == "$1" ]]; then echo -1; else echo 1; fi'
stub notify-send 'printf "notify %s\n" "$*" >> "$TRACE"; exit 0'
stub systemctl 'exit 1'
stub systemd-run 'printf "systemd-run %s\n" "$*" >> "$TRACE"; exit 0'
export PATH="$stubs:$PATH"

script="$repo/home/.local/bin/update-davinci"
aur="$HOME/davinci-resolve-studio"

reset() {
    rm -rf "$HOME" "$XDG_CACHE_HOME" "$XDG_DOWNLOAD_DIR"
    mkdir -p "$aur/.git" "$XDG_CACHE_HOME/davinci-update" "$XDG_DOWNLOAD_DIR"
    printf 'pkgver=%s\npkgrel=3\n  while x; do\n    patchelf --set-rpath a "${_file}"\n  done\n' "${1:-21.1.1}" > "$aur/PKGBUILD"
    : > "$aur/davinci-resolve-studio.install"
    : > "$aur/davinci-control-panels-setup.sh"
    : > "$TRACE"
}

check() {
    local name=$1; shift
    if "$@"; then
        printf 'PASS: %s\n' "$name"
    else
        printf 'FAIL: %s\ntrace:\n' "$name" >&2
        cat "$TRACE" >&2
        exit 1
    fi
}
traced() { grep -q -- "$1" "$TRACE"; }
not_traced() { ! grep -q -- "$1" "$TRACE"; }
ready() { compgen -G "$XDG_CACHE_HOME/davinci-update/davinci-resolve-studio-$1-*" >/dev/null; }

# not installed: nothing happens at all
reset
INSTALLED= "$script" > "$root/out" 2>&1 </dev/null
check 'missing package exits 0' test $? -eq 0
check 'missing package never hits the network' not_traced '^curl'

# already current
reset
INSTALLED=21.1.2 "$script" > "$root/out" 2>&1 </dev/null
check 'current version exits 0' test $? -eq 0
check 'current version downloads nothing' not_traced ' -o '
check 'current version builds nothing' not_traced '^makepkg'

# feed is ahead of the AUR, which is the case that made this script necessary
reset 21.1.1
INSTALLED=21.1.1 "$script" > "$root/out" 2>&1 </dev/null
check 'build succeeds' test $? -eq 0
check 'zip stays in Downloads' test -f "$XDG_DOWNLOAD_DIR/DaVinci_Resolve_Studio_21.1.2_Linux.zip"
check 'no partial left behind' test ! -e "$XDG_DOWNLOAD_DIR/DaVinci_Resolve_Studio_21.1.2_Linux.zip.part"
check 'recipe bumped to the feed version' traced 'makepkg.*pkgver=21.1.2'
check 'makepkg reads the zip from Downloads' traced "makepkg.*srcdest=$XDG_DOWNLOAD_DIR"
check 'patchelf skips only chrome-sandbox' traced 'recipe-skips-sandbox'
check 'unverifiable checksum is skipped' traced 'makepkg.*--skipchecksums'
check 'no terminal means it asks rather than installs' traced '^notify'
check 'no terminal means no sudo' not_traced '^sudo'
check 'package is staged' ready 21.1.2
check 'AUR checkout is left alone' grep -qx 'pkgver=21.1.1' "$aur/PKGBUILD"

# AUR matches the feed, so its checksum must still be enforced
reset 21.1.2
INSTALLED=21.1.1 "$script" > "$root/out" 2>&1 </dev/null
check 'AUR checksum is kept when versions match' not_traced 'makepkg.*--skipchecksums'

# a staged package doesn't get rebuilt
reset 21.1.2
: > "$XDG_CACHE_HOME/davinci-update/davinci-resolve-studio-21.1.2-1-x86_64.pkg.tar.zst"
INSTALLED=21.1.1 "$script" > "$root/out" 2>&1 </dev/null
check 'staged package is reused' not_traced '^makepkg'

# a second run during a build must not touch it
reset
touch "$XDG_CACHE_HOME/davinci-update/lock"
flock "$XDG_CACHE_HOME/davinci-update/lock" env INSTALLED=21.1.1 "$script" > "$root/out" 2>&1 </dev/null
check 'second run exits 0' test $? -eq 0
check 'second run builds nothing' not_traced '^makepkg'

# failures must not leave something that looks installable
reset
BUILD_FAILS=1 INSTALLED=21.1.1 "$script" > "$root/out" 2>&1 </dev/null
check 'build failure is reported' test $? -ne 0
check 'build failure stages nothing' sh -c '! ls "$XDG_CACHE_HOME"/davinci-update/*.pkg.tar.zst 2>/dev/null'
check 'build failure tells the desktop' traced 'notify.*Resolve update failed'
check 'build failure frees its space' test ! -e "$XDG_CACHE_HOME/davinci-update/build"

# low disk stops before spending 11 GB of bandwidth
reset
DF_AVAIL=5 INSTALLED=21.1.1 "$script" > "$root/out" 2>&1 </dev/null
check 'low disk is reported' test $? -ne 0
check 'low disk downloads nothing' not_traced ' -o '

# a link that isn't Blackmagic's is refused
reset
DOWNLOAD_URL='https://example.com/DaVinci_Resolve_Studio_21.1.2_Linux.zip' INSTALLED=21.1.1 "$script" > "$root/out" 2>&1 </dev/null
check 'foreign download link is refused' test $? -ne 0
check 'foreign link is never fetched' not_traced 'example.com'

# install tidies old installers but keeps the rollback one
reset
staged="$XDG_CACHE_HOME/davinci-update/davinci-resolve-studio-21.1.2-1-x86_64.pkg.tar.zst"
: > "$staged"
for v in 21.0.2 21.1.1 21.1.2; do : > "$XDG_DOWNLOAD_DIR/DaVinci_Resolve_Studio_${v}_Linux.zip"; done
: > "$XDG_DOWNLOAD_DIR/keep-me.zip"
INSTALLED=21.1.1 "$script" --install > "$root/out" 2>&1 </dev/null
check 'install exits 0' test $? -eq 0
check 'installs through pacman' traced "sudo pacman -U --noconfirm $staged"
check 'new installer kept' test -f "$XDG_DOWNLOAD_DIR/DaVinci_Resolve_Studio_21.1.2_Linux.zip"
check 'previous installer kept' test -f "$XDG_DOWNLOAD_DIR/DaVinci_Resolve_Studio_21.1.1_Linux.zip"
check 'older installer removed' test ! -e "$XDG_DOWNLOAD_DIR/DaVinci_Resolve_Studio_21.0.2_Linux.zip"
check 'unrelated downloads untouched' test -f "$XDG_DOWNLOAD_DIR/keep-me.zip"

# background mode must not install over a running Resolve
reset
: > "$XDG_CACHE_HOME/davinci-update/davinci-resolve-studio-21.1.2-1-x86_64.pkg.tar.zst"
RESOLVE_RUNNING=1 SUDO_OK=1 INSTALLED=21.1.1 "$script" --background > "$root/out" 2>&1 </dev/null
check 'running Resolve blocks background install' not_traced 'sudo pacman'
check 'it detaches instead' traced '^systemd-run'

# background mode with cached sudo and Resolve closed installs straight away
reset
: > "$XDG_CACHE_HOME/davinci-update/davinci-resolve-studio-21.1.2-1-x86_64.pkg.tar.zst"
SUDO_OK=1 INSTALLED=21.1.1 "$script" --background > "$root/out" 2>&1 </dev/null
check 'cached sudo installs a ready package' traced 'sudo pacman -U'
check 'nothing left to detach' not_traced '^systemd-run'

# background mode without sudo detaches and never prompts
reset
INSTALLED=21.1.1 "$script" --background > "$root/out" 2>&1 </dev/null
check 'no sudo detaches' traced '^systemd-run'
check 'detach does no work itself' not_traced '^makepkg'
