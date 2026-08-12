# Android APK artifact delivery quirks

Use this when delivering APKs or other Android install artifacts through Semyon's self-hosted fileshare/Discord.

## Pitfall: APKs are ZIPs internally

Android file managers may identify an `.apk` as a ZIP/archive because the APK container is ZIP-based. Xiaomi/MIUI Files, Google Files, and CX File Explorer may then show it as a folder or only offer extraction instead of installation.

Do not tell the user to extract it. The fix is to make Android treat the file as a package installer target:

1. Ensure the downloaded filename ends in `.apk`.
2. Serve with headers:
   - `Content-Type: application/vnd.android.package-archive`
   - `Content-Disposition: attachment; filename="<name>.apk"`
   - `X-Content-Type-Options: nosniff`
3. Prefer a small web route/script that streams the APK with those headers over a generic static/file-share endpoint that may emit `application/zip`.
4. Verify from outside with `curl -I` and a download test (`curl -LOJ`, `file`, `sha256sum`) before sending the link.
5. If the user already extracted it, tell them to delete the extracted folder and re-download/open the `.apk` with Package Installer / Install packages.

## User-facing delivery style

When sending a link intended to be tapped on mobile, put the raw URL on its own line, not inside a code block, so Discord/mobile clients make it clickable.

## Example PHP streamer

```php
<?php
$path = '/var/www/html/storage/app/public/apk/example.apk';
if (!is_file($path)) {
    http_response_code(404);
    header('Content-Type: text/plain');
    echo "APK not found\n";
    exit;
}
header('Content-Type: application/vnd.android.package-archive');
header('Content-Disposition: attachment; filename="example.apk"');
header('Content-Length: ' . filesize($path));
header('X-Content-Type-Options: nosniff');
readfile($path);
```
