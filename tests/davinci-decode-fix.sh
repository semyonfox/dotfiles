#!/usr/bin/env bash
# runs davinci-decode-fix on tiny generated clips with real ffmpeg. VA-API is off so the
# result doesn't depend on the machine's GPU
set -u

repo="$(cd "$(dirname "$0")/.." && pwd)"
fix="$repo/home/.local/bin/davinci-decode-fix"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
export HOME="$root/home" XDG_CACHE_HOME="$root/cache" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data"
export NOTIFY=false VAAPI_DEVICE=/nonexistent
cache="$XDG_CACHE_HOME/resolve-media"
media="$root/media"
mkdir -p "$HOME" "$media"

fails=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; fails=$((fails + 1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

gen() {
    local out="$1"; shift
    ffmpeg -hide_banner -loglevel error -nostdin -y -f lavfi -i testsrc=s=320x240:r=25:d=2 \
        -f lavfi -i sine=d=2 -shortest "$@" "$out"
}
gen "$media/phone.mp4" -c:v libx264 -c:a aac
gen "$media/dolby.mp4" -c:v libx264 -c:a ac3
gen "$media/yt.mkv" -c:v libx264 -c:a libopus
gen "$media/edit.mov" -c:v dnxhd -profile:v dnxhr_lb -pix_fmt yuv422p -c:a pcm_s16le
ffmpeg -hide_banner -loglevel error -nostdin -f lavfi -i sine=d=2 -c:a libopus "$media/voice.opus"
key() { printf '%s' "$1" | sha1sum | cut -c1-16; }
codec() { ffprobe -v error -select_streams "$1" -show_entries stream=codec_name -of csv=p=0 "$2" | head -n 1; }
row() { printf '%s\n' "$@" >"$root/list"; "$fix" --lookup "$root/list"; }
wait_for() { local i; for i in $(seq 1 100); do [[ -e $1 ]] && return 0; sleep 0.1; done; return 1; }

"$fix" "$media"
p="$cache/$(key "$media/phone.mp4")"
y="$cache/$(key "$media/yt.mkv")"
v="$cache/$(key "$media/voice.opus")"
d="$cache/$(key "$media/edit.mov")"

check 'AAC in MP4 is left alone' '[[ ! -e $p.fixed.mkv && ! -e $p.fixed.wav ]]'
check 'AC3 in MP4 is left alone' '[[ ! -e $cache/$(key "$media/dolby.mp4").fixed.mkv ]]'
check 'H.264 gets a DNxHR proxy' '[[ $(codec v "$p.proxy.mov") == dnxhd ]]'
check 'Opus in MKV gets a fixed copy with PCM audio' '[[ $(codec a "$y.fixed.mkv") == pcm_s16le ]]'
check 'the fixed copy keeps the original video untouched' '[[ $(codec v "$y.fixed.mkv") == h264 ]]'
check 'an Opus file becomes a WAV with no proxy' '[[ -f $v.fixed.wav && ! -e $v.proxy.mov ]]'
check 'DNxHR footage needs nothing' '[[ ! -e $d.src ]]'
check 'nothing is written next to the originals' '[[ $(ls "$media" | wc -l) == 5 ]]'

out="$(row "$media/yt.mkv" "$media/edit.mov")"
check 'lookup returns the fixed copy and proxy' "grep -qxF \$'ready\t$media/yt.mkv\t$y.fixed.mkv\t$y.proxy.mov' <<<\"\$out\""
check 'lookup skips what needs nothing' "grep -qxF \$'skip\t$media/edit.mov\t\t' <<<\"\$out\""
check 'lookup claims a fixed copy it hands out' '[[ -f $y.claimed ]]'
out="$(row "$y.fixed.mkv")"
check 'a clip already on its fixed copy maps back to it' "grep -qxF \$'ready\t$y.fixed.mkv\t$y.fixed.mkv\t$y.proxy.mov' <<<\"\$out\""
link="$cache/audio/voice.wav"
check 'an audio-only fix gets a readable name to import' '[[ $(realpath "$link") == "$v.fixed.wav" ]]'
out="$(row "$link")"
check 'a clip imported through that name needs no swap' "grep -qxF \$'ready\t$link\t$link\t' <<<\"\$out\""
rm "$v.claimed"

gen "$media/new.mp4" -c:v libx264 -c:a aac
n="$cache/$(key "$media/new.mp4")"
out="$(row "$media/new.mp4")"
check 'lookup queues a clip with nothing ready' "[[ \$(cut -f1 <<<\"\$out\") == queued ]]"
check 'the queue makes the proxy in the background' 'wait_for "$n.proxy.mov"'

touch -d '+1 minute' "$media/phone.mp4"
out="$(row "$media/phone.mp4")"
check 'a changed source drops its old proxy and queues a new one' "[[ \$(cut -f1,4 <<<\"\$out\") == queued$'\t' ]]"
wait_for "$p.proxy.mov"
sleep 0.5

rm "$media/yt.mkv" "$media/voice.opus"
"$fix" --prune
check 'prune drops a proxy whose source is gone' '[[ ! -e $y.proxy.mov ]]'
check 'prune keeps a claimed fixed copy, a project still points at it' '[[ -f $y.fixed.mkv ]]'
check 'prune drops an unclaimed fixed copy whose source is gone' '[[ ! -e $v.fixed.wav ]]'
check 'prune drops its audio name too' '[[ ! -L $link ]]'

CACHE_MAX_GB=0 "$fix" --prune
check 'over the size cap, proxies go' '[[ -z $(find "$cache" -name "*.proxy.mov") ]]'
check 'over the size cap, claimed fixed copies stay' '[[ -f $y.fixed.mkv ]]'

(( fails == 0 )) || { printf '%d failed\n' "$fails"; exit 1; }
