# Fileshare cross-platform CLI binary delivery

Use when Semyon asks to publish a standalone CLI/tool binary through his self-hosted fileshare and verify that downloads work.

Erugo was replaced by Pingvin Share X on 2026-10-22; the file keeps its old name so existing links to it still resolve. Pingvin only serves files from shares, so there are no new `/storage/bin/<app>/<version>/` folders. The old ones under `/storage/` still serve from a read-only archive; do not write there.

## Pattern

Bundle the platform binaries with a checksum file, then publish the bundle as one share. Use `tar.gz` unless `zip` is definitely installed:

```bash
APP=canvas-export
VERSION=0.1.0
SRC=/path/to/dist/release
cd "$SRC"
sha256sum <artifact files> > SHA256SUMS.txt
tar -czf "/tmp/$APP-$VERSION-all-platforms.tar.gz" <artifact files> SHA256SUMS.txt
python3 /home/semyon/server-stacks/fileshare/publish-file.py --expires-days 30 \
  --title "$APP $VERSION" "/tmp/$APP-$VERSION-all-platforms.tar.gz"
```

When a single platform needs its own direct link, publish that binary as its own share the same way. Each run prints JSON with `sha256`, `share_url` and `download_url` (`https://fileshare.semyon.ie/shares/<share-id>/<filename>`).

## Verification

Always verify from the public URL, not just from the local file:

```bash
rm -rf /tmp/${APP}-download-test && mkdir /tmp/${APP}-download-test
cd /tmp/${APP}-download-test
curl --fail --silent --show-error -L -o bundle.tar.gz '<download_url>'
sha256sum bundle.tar.gz   # must equal the printed sha256
tar -xzf bundle.tar.gz
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
