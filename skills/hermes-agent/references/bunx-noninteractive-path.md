# Bun/bunx hidden from non-interactive agent shells

## Symptom

A user says `bunx` is installed, but an agent command like this fails to find it:

```bash
command -v bunx
```

while `npx` is visible and works.

## Root cause pattern

Bun is often installed under:

```text
~/.bun/bin/bun
~/.bun/bin/bunx
```

and added to PATH only by interactive shell startup, commonly `~/.bashrc`:

```bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```

Hermes gateway and many coding-agent terminal tools run commands as non-interactive shells (`bash -c`) under a service environment. Non-interactive `bash -c` does not source `~/.bashrc`, and a systemd user service may have a fixed PATH that omits `~/.bun/bin`.

## Verification recipe

```bash
printf 'PATH=%s\n' "$PATH"
command -v bun bunx npx node npm || true

# Check absolute install location.
for p in "$HOME/.bun/bin/bun" "$HOME/.bun/bin/bunx"; do
  [ -e "$p" ] && stat -Lc '%A %U:%G %s %n' "$p" && "$p" --version
 done

# Compare shell modes.
bash -c  'command -v bunx || echo "bash -c: no bunx"'
bash -ic 'command -v bunx || echo "bash -ic: no bunx"' 2>/dev/null || true

# Inspect startup files.
for f in ~/.profile ~/.bashrc ~/.bash_profile ~/.zshrc ~/.zprofile; do
  [ -f "$f" ] || continue
  echo "-- $f --"
  grep -nE 'bun|BUN|PATH' "$f" | sed -n '1,40p'
done

# Hermes gateway/systemd path, when relevant.
systemctl --user show hermes-gateway --property=Environment --property=ExecStart --property=MainPID 2>&1
pid=$(systemctl --user show hermes-gateway --property=MainPID --value 2>/dev/null || true)
[ -n "$pid" ] && [ "$pid" != 0 ] && tr '\0' '\n' < "/proc/$pid/environ" | grep -E '^(PATH|BUN_INSTALL|SHELL|HOME)='
```

## Fixes

Use the least invasive fix that matches the task:

1. Immediate one-off command:
   ```bash
   "$HOME/.bun/bin/bunx" ccusage
   ```

2. Per-command environment:
   ```bash
   BUN_INSTALL="$HOME/.bun" PATH="$HOME/.bun/bin:$PATH" bunx ccusage
   ```

3. Durable shell fix: add Bun's PATH export to a startup file used by the relevant shell mode, not only the interactive one.

4. Durable service fix: add `~/.bun/bin` to the user service environment for the gateway/agent runner, then restart the service.

## Reporting guidance

Say: "`bunx` is installed but hidden from this agent shell's PATH."

Do not say: "`bunx` is not installed" unless absolute path probes and startup-mode checks also fail.
