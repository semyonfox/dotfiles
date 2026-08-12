# Helium + Fontconfig unexpected monospace rendering

## Symptom

On Linux, Helium browser chrome and some content surfaces render with a typewriter/monospace face, while GTK and browser font preferences appear correct.

## Upstream evidence

- Helium issue #2051: <https://github.com/imputnet/helium/issues/2051>
  - Reported on Arch Linux with Helium 0.14.2.1.
  - Reproduction: changing the minimum font size in `helium://settings/fonts` could cause UI/certain webpages to select FreeMono/Liberation Mono-like faces.
  - A follow-up linked Chromium issue `519984267` and reported Fontconfig 2.18.2 remained affected while downgrade to 2.17.1 resolved the issue.
- Helium source: <https://github.com/imputnet/helium> (GPL-3.0).
- Linux packaging/build source: <https://github.com/imputnet/helium-linux>.

## Verified deployment details

On CachyOS/Arch, a machine with `fontconfig 2:2.18.2-1.1` reproduced the issue. The official Arch Archive package `fontconfig 2:2.17.1-1` had matching dependency ABI (`bash`, `expat`, `freetype2`, `glibc`, `libexpat.so=1-64`, `libfreetype.so=6-64`) and restored proportional Helium UI after install/restart.

Use the Archive package and its `.sig`; inspect first with `pacman -Qip`. Perform the installation with local user authentication, never collect a password through chat or remote shell.

Example package source shape:

```text
https://archive.archlinux.org/packages/f/fontconfig/
fontconfig-2%3A2.17.1-1-x86_64.pkg.tar.zst
```

## Verification checklist

```sh
pacman -Q fontconfig
for family in system-ui ui-sans-serif sans-serif serif monospace; do
  printf '%s => ' "$family"
  fc-match -f '%{family}: %{style} | %{file}\n' "$family"
done
```

Then close Helium completely, rebuild cache (`fc-cache -rf`), relaunch, and capture the actual tab rail/browser chrome. Package resolution alone does not prove that a Chromium UI problem is gone.

## Role-based policy used after recovery

```text
system-ui / ui-sans-serif / sans-serif: Segoe UI primary, Noto Sans fallback
serif:                                  Noto Serif
monospace / ui-monospace:               Consolas
```

Segoe UI is appropriate for small Windows-parity UI when locally licensed/available. Noto provides broad-script fallback. Keep a true monospaced code face; a proportional family must not be forced into monospace requests.

## Maintenance

This is a temporary workaround. A later system update may replace Fontconfig 2.17.1. Before updating Fontconfig, check the Helium/Chromium upstream issue for confirmation that the regression is fixed. Do not create a permanent `IgnorePkg` pin automatically: it trades away normal updates and needs an explicit security/maintenance decision.
