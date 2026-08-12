# Erugo cross-platform CLI binary delivery

Use when Semyon asks to publish a standalone CLI/tool binary through his self-hosted Erugo fileshare and verify that downloads work.

## Pattern

Prefer Erugo static public storage for direct artifact URLs:

```bash
APP=canvas-export
VERSION=0.1.0
SRC=/path/to/dist/release
DEST=/home/semyon/server-stacks/fileshare/erugo-storage/app/public/bin/$APP/$VERSION
mkdir -p "$DEST"
cp "$SRC"/* "$DEST"/
chmod 0644 "$DEST"/*
chmod 0755 "$DEST"/*linux* "$DEST"/*macos* 2>/dev/null || true
(
  cd "$DEST"
  sha256sum * > SHA256SUMS.txt
)
```

Public URLs become:

```text
https://fileshare.semyon.ie/storage/bin/<app>/<version>/<filename>
https://fileshare.semyon.ie/storage/bin/<app>/<version>/SHA256SUMS.txt
```

For a bundle, use `tar.gz` unless `zip` is definitely installed:

```bash
cd "$DEST"
tar -czf "$APP-$VERSION-all-platforms.tar.gz" <artifact files> SHA256SUMS.txt
sha256sum "$APP-$VERSION-all-platforms.tar.gz" >> SHA256SUMS.txt
```

## Verification

Always verify from the public URL, not just from the local Erugo storage path:

```bash
BASE="https://fileshare.semyon.ie/storage/bin/$APP/$VERSION"
rm -rf /tmp/${APP}-download-test && mkdir /tmp/${APP}-download-test
cd /tmp/${APP}-download-test

for f in <artifact files> SHA256SUMS.txt; do
  curl --fail --silent --show-error -L -o "$f" "$BASE/$f"
done
sha256sum -c SHA256SUMS.txt
file <artifact files>
```

If the current host can run one of the binaries, execute a harmless command too:

```bash
chmod +x ./<linux-x64-binary>
./<linux-x64-binary> --help
```

For other OS/arch targets, report the honest verification level: checksum/download and executable format (`ELF`, `Mach-O`, `PE32+`) are verified; runtime execution is not unless you actually ran it on that platform.

## Bun single-file CLI release targets

For TypeScript CLIs using Bun `--compile`, useful cross-platform targets are:

```bash
bun build ./src/index.ts --compile --target=bun-linux-x64-baseline --outfile ./dist/release/<name>-linux-x64
bun build ./src/index.ts --compile --target=bun-linux-arm64 --outfile ./dist/release/<name>-linux-arm64
bun build ./src/index.ts --compile --target=bun-windows-x64-baseline --outfile ./dist/release/<name>-windows-x64.exe
bun build ./src/index.ts --compile --target=bun-darwin-x64 --outfile ./dist/release/<name>-macos-x64
bun build ./src/index.ts --compile --target=bun-darwin-arm64 --outfile ./dist/release/<name>-macos-arm64
```

Use `baseline` for x64 when distributing to unknown machines; it is more compatible than modern CPU targets.

## Reporting

Keep the final handoff short:

- direct URLs for each platform and checksums
- what was actually executed locally
- what was only format/checksum verified
- exact command examples for Linux/macOS and Windows PowerShell
