# Android / MIUI ADB file-install and cloned-profile triage

Use when Semyon's Android phone is plugged into the laptop and file downloads/APKs behave strangely, especially on Xiaomi/HyperOS/MIUI.

## Discovery

From the server/session host, reach the laptop first:

```bash
ssh laptop 'adb devices -l'
```

Useful probes:

```bash
ssh laptop 'adb shell pm list users'
ssh laptop 'adb shell getprop ro.product.manufacturer; adb shell getprop ro.product.model; adb shell getprop ro.miui.ui.version.name; adb shell getprop ro.build.version.release'
ssh laptop 'adb shell pm list packages --user 0 | sort'
ssh laptop 'adb shell pm list packages --user 999 | sort'
```

On Xiaomi, `UserInfo{999:XSpace...}` commonly means Dual Apps / cloned-app storage. Cloned apps have separate downloads:

```text
main user:   /storage/emulated/0/Download  == /sdcard/Download
XSpace:      /storage/emulated/999/Download
```

If Chrome/Discord/share targets appear only in weird menus, inspect user 999 before assuming files are gone.

## Rescuing hidden cloned-profile downloads

Copy XSpace downloads into normal user-visible storage:

```bash
ssh laptop 'adb shell "mkdir -p /sdcard/Download/XSpace-Downloads-rescued && cp -an /storage/emulated/999/Download/. /sdcard/Download/XSpace-Downloads-rescued/ 2>/dev/null || true"'
```

Tell Semyon to inspect:

```text
Internal storage > Download > XSpace-Downloads-rescued
```

## APKs appearing as folders

APK files are ZIP containers. Some file managers may extract them or register as `application/vnd.android.package-archive` handlers. If a path like this is a directory, it is extracted junk, not the installable APK:

```text
/sdcard/Download/t3-code-preview.apk/
```

Safe cleanup pattern for task-specific junk only:

```bash
ssh laptop 'adb shell "rm -rf /sdcard/Download/<known-task-name>.apk /sdcard/Download/<known-task-name>..zip"'
```

Then push the real APK to obvious locations:

```bash
scp /local/artifact.apk laptop:/tmp/artifact.apk
ssh laptop 'adb push /tmp/artifact.apk /sdcard/Download/artifact.apk && adb shell "mkdir -p /sdcard/Documents/Installers && cp /sdcard/Download/artifact.apk /sdcard/Documents/Installers/artifact.apk"'
```

Grant install-from-this-source appops where useful:

```bash
ssh laptop 'for p in com.google.android.apps.nbu.files com.mi.android.globalFileexplorer com.cxinventor.file.explorer com.tachibana.downloader com.android.chrome com.brave.browser me.zhanghai.android.files; do adb shell appops set "$p" REQUEST_INSTALL_PACKAGES allow 2>/dev/null || true; done'
```

## MIUI install restrictions

`adb install` / `pm install` may fail even with USB debugging authorized:

```text
INSTALL_FAILED_USER_RESTRICTED: Install canceled by user
```

On Xiaomi this often means `Install via USB` / `USB debugging (Security settings)` is disabled and may require a Xiaomi account. Do not keep hammering ADB. Stage the APK in Downloads/Documents and have Semyon tap-install from the phone UI instead.

If trying direct `pm install`, use `/data/local/tmp`, not `/sdcard`, because system_server may be blocked from reading FUSE storage:

```bash
ssh laptop 'adb push /tmp/artifact.apk /data/local/tmp/artifact.apk && adb shell chmod 0644 /data/local/tmp/artifact.apk && adb shell pm install -r /data/local/tmp/artifact.apk'
```

## File manager recommendations learned

For fully-free broad file management with archives and remote files:

- MiXplorer: best zero-cost power-user option; free outside Play Store, strong archive/cloud/SMB/SFTP/WebDAV feature set.
- Amaze: best F-Droid/open-source choice; supports compress/extract, ZIP/RAR/APK reader, text editor, app manager, and network protocols with plugin.
- Solid Explorer: polished best-overall paid/trial option, not suitable when Semyon asks for fully free.

Do not remove apps or cloned profiles unless Semyon explicitly approves; XSpace/cloned apps may hold real data.