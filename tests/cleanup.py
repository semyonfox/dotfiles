#!/usr/bin/env python3
"""Integration regressions for both shell wrappers against an isolated HOME."""
import contextlib
import fcntl
import hashlib
import importlib.machinery
import importlib.util
import io
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[1]
FRONT = REPO / "home/.local/bin/cleanup-caches"
loader = importlib.machinery.SourceFileLoader("cleanup_front", str(FRONT))
spec = importlib.util.spec_from_loader(loader.name, loader)
front = importlib.util.module_from_spec(spec)
sys.modules[loader.name] = front
loader.exec_module(front)

# speaks the real engine's log grammar so the summary parser is exercised.
# MOCK_INVENTORY_RC makes the dry-run size check fail the way a dead docker does
MOCK_ENGINE = r'''set -eu
{ printf 'ARGS'; printf ' <%s>' "$@"; printf '\n'
  printf 'NATIVE_ENV GOCACHE=%s GOFLAGS=%s GOENV=%s GOTOOLCHAIN=%s DOCKER_CONFIG=%s\n' "$GOCACHE" "$GOFLAGS" "$GOENV" "$GOTOOLCHAIN" "$DOCKER_CONFIG"
} >> "$TRACE"
[[ "$1 $2" == '--native-only --stdout' ]] || exit 99
[[ ${MOCK_ENGINE_RC:-0} == 0 ]] || exit "$MOCK_ENGINE_RC"
exec 9<"$HOME/fixture.lock"
flock -n 9 || { printf 'Cleanup skipped: another run holds the lock.\n'; exit 75; }
dry=0; [[ ${3:-} == --dry-run ]] && dry=1
inv=${MOCK_INVENTORY_RC:-0}
printf 'Started: now policy=test dry_run=%s\n' "$dry"
printf '\n--- category=default-buildkit target=- ---\n'
if (( dry )); then
  printf 'DRY_RUN: native command NOT executed; inventory allocated_bytes=unknown; proposed=docker builder prune -af\n'
  if (( inv )); then
    printf 'permission denied while trying to connect to the Docker daemon socket\n'
  else
    printf 'TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE\nImages          3         1         2.5GB     1.1GB (44%%)\nBuild Cache     70        0         1.5GB     1.5GB\n'
  fi
  printf 'CATEGORY=default-buildkit DRY_RUN=1 INVENTORY_EXIT_STATUS=%s PRUNE_EXECUTED=no\n' "$inv"
else
  printf 'Total reclaimed space: 0B\nNATIVE_RECLAIM Total reclaimed space: 0B\n'
  printf 'CATEGORY=default-buildkit EXIT_STATUS=0 TIMEOUT=no BEFORE_BYTES=unknown AFTER_BYTES=unknown\n'
fi
printf '\n--- category=dangling-images target=- ---\n'
if (( dry )); then
  printf 'DRY_RUN: native command NOT executed; inventory allocated_bytes=unknown; proposed=docker image prune -f\n'
  printf 'abc123 457MB\ndef456 1.3GB\n'
  printf 'CATEGORY=dangling-images DRY_RUN=1 INVENTORY_EXIT_STATUS=0 PRUNE_EXECUTED=no\n'
else
  printf 'Total reclaimed space: 0B\nNATIVE_RECLAIM Total reclaimed space: 0B\n'
  printf 'CATEGORY=dangling-images EXIT_STATUS=0 TIMEOUT=no BEFORE_BYTES=unknown AFTER_BYTES=unknown\n'
fi
printf '\n--- category=go-build target=%s ---\n' "$HOME/.cache/go-build"
if (( dry )); then
  printf 'DRY_RUN: native command NOT executed; inventory allocated_bytes=12288; proposed=go clean -cache\n'
  printf 'CATEGORY=go-build DRY_RUN=1 INVENTORY_EXIT_STATUS=0 PRUNE_EXECUTED=no\n'
else
  printf 'CATEGORY=go-build EXIT_STATUS=0 TIMEOUT=no BEFORE_BYTES=12288 AFTER_BYTES=0\n'
  printf 'ALLOCATED_CATEGORY_DELTA_BYTES=12288 (not unique physical reclaim)\n'
fi
printf '\nFinished: now\nFilesystem delta bytes (concurrent activity included): 12288\nFailed commands: %s\n' "$(( inv ? 1 : 0 ))"
exit "$(( inv ? 1 : 0 ))"
'''

MOCK_UV = r'''#!/bin/bash
printf 'uv lock-timeout=%s %s\n' "$UV_LOCK_TIMEOUT" "$*" >> "$TRACE"
if [[ ${MOCK_UV_RC:-0} == 2 ]]; then printf 'Timeout (1s) when waiting for lock on native-cache\n' >&2; fi
exit "${MOCK_UV_RC:-0}"
'''

# stands in for docker in every test. the Jenkins agent's export dir maps to
# $HOME/jenkins-cache, MOCK_JENKINS puts an agent on the host
MOCK_DOCKER = r'''#!/bin/bash
printf 'docker %s\n' "$*" >> "$TRACE"
case $1 in
  inspect) [[ -n ${MOCK_JENKINS:-} ]] && { echo true; exit 0; }; echo 'Error: No such object' >&2; exit 1 ;;
  top)
    printf 'PID ARGS\n1 /sbin/docker-init -- jenkins-agent-entrypoint\n2 java -jar /usr/share/jenkins/agent.jar\n'
    [[ -n ${MOCK_JENKINS_BUSY:-} ]] && printf '3 docker buildx build .\n'
    exit 0 ;;
  exec)
    shift 2
    args=()
    for a in "$@"; do args+=("${a//\/home\/jenkins\/cache\/buildkit/$HOME/jenkins-cache}"); done
    exec "${args[@]}" ;;
  image)
    case $2 in
      inspect) printf '%s\n' "${MOCK_IMAGE_TAGS:-[\"swim-api:abc1234\"]}" ;;
      rm) [[ -n ${MOCK_IMAGE_IN_USE:-} ]] && { echo 'conflict: image is being used by stopped container 1' >&2; exit 1; } ;;
    esac ;;
esac
exit 0
'''

DAYS_AGO = 3 * 86400


class CleanupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="cleanup-test-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        (self.home / ".local/bin").mkdir(parents=True)
        shutil.copyfile(FRONT, self.home / ".local/bin/cleanup-caches")
        self.engine = self.home / ".hermes/profiles/sean/scripts/hourly-build-cache-clean.sh"
        self.engine.parent.mkdir(parents=True)
        self.engine.write_text(MOCK_ENGINE)
        (self.home / "fixture.lock").touch()
        for name in ("code/repo/build/tracked", "code/repo/node_modules/active",
                     "t3code-mobile-builds/repair/private.apk", "go/bin/tool",
                     "go/pkg/mod/pkg/source", "actions-runners/runner/home/.cache/pnpm/v12/metadata/data",
                     ".cache/pnpm/v11/metadata/data", ".cache/pnpm/v12/metadata-full/data",
                     ".local/share/pnpm/store/v10/reference", ".local/share/pnpm/store/v11/data",
                     ".t3/history.sqlite", ".hermes/sessions/history", "Downloads/personal"):
            p = self.home / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text("retain " + name)
        # mock native tools and pgrep so best-effort runs never touch real caches
        self.trace = self.home / "trace"
        self.mockbin = self.home / "mockbin"
        self.mockbin.mkdir()
        for tool in ("pnpm", "npm", "pip3", "go"):
            (self.mockbin / tool).write_text(f'#!/bin/bash\nprintf "{tool} %s\\n" "$*" >> "$TRACE"\n')
        (self.mockbin / "docker").write_text(MOCK_DOCKER)
        (self.mockbin / "pgrep").write_text(
            '#!/bin/bash\n'
            'pattern=${@: -1}\n'
            '[[ -n ${MOCK_PGREP_RC:-} ]] && exit "$MOCK_PGREP_RC"\n'
            '[[ -n ${MOCK_BUSY:-} && $pattern == *"$MOCK_BUSY"* ]] && exit 0\n'
            'exit 1\n')
        for tool in self.mockbin.iterdir():
            tool.chmod(0o700)
        # CLEANUP_HOST_TMP keeps the node compile cache fallback inside the fixture
        self.env = dict(os.environ, HOME=str(self.home), TMPDIR=str(self.home),
                        XDG_CACHE_HOME=str(self.home / ".cache"), TRACE=str(self.trace),
                        CLEANUP_HOST_TMP=str(self.home / "hosttmp"),
                        PATH=f"{self.mockbin}:{os.environ['PATH']}")
        self.env.pop("NODE_COMPILE_CACHE", None)
        self.wrappers = {}
        for shell in ("bash", "zsh"):
            self.assertIsNotNone(shutil.which(shell), shell + " required, not silently skipped")
            text = (REPO / f"home/.{shell}_functions").read_text()
            body = text[text.index("cleanup() {"):].split("\n}", 1)[0] + "\n}\n"
            self.assertNotIn("rm -", body)
            self.assertNotIn("_maint_proc_cwds", text)
            self.wrappers[shell] = body

    def call(self, shell, *args, **env):
        # each call gets its own trace so an assertion can never pass on an earlier call
        self.trace.unlink(missing_ok=True)
        return subprocess.run([shell, "-c", self.wrappers[shell] + '\ncleanup "$@"', "cleanup-test", *args],
                              env=dict(self.env, **env), capture_output=True, text=True, timeout=30)

    def traced(self):
        return self.trace.read_text() if self.trace.exists() else ""

    def snapshot(self):
        # the mock engine always records its arguments, so the trace is not fixture state
        return {str(p.relative_to(self.home)): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in self.home.rglob("*") if p.is_file() and p != self.trace}

    def protected(self):
        return {k: v for k, v in self.snapshot().items()
                if not k.startswith((".cache/", "mockbin/"))}

    def box_lines(self, stdout):
        return [line for line in stdout.splitlines() if line.startswith("│")]

    def test_flag_combinations_preview_and_retention(self):
        for shell in self.wrappers:
            for args in (("--deep", "--dry-run"), ("--dry-run", "--deep"), ("--dry-run",)):
                with self.subTest(shell=shell, args=args):
                    before = self.snapshot()
                    p = self.call(shell, *args)
                    deep = "--deep" in args
                    self.assertEqual(p.returncode, 0, p.stderr + p.stdout)
                    self.assertIn("ARGS <--native-only> <--stdout> <--dry-run>", self.traced())
                    self.assertIn("System cleanup (deep, dry run)" if deep else "System cleanup (dry run)", p.stdout)
                    self.assertIn("Dry run, nothing was removed.", p.stdout)
                    self.assertNotIn("Cleanup complete", p.stdout)
                    self.assertEqual("Left alone, these are data rather than cache" in p.stdout, deep)
                    self.assertEqual(before, self.snapshot())
                    # docker sizes come from the inventory the engine prints, 1.5GB and 457MB + 1.3GB
                    self.assertRegex(p.stdout, r"Docker build cache +1\.4G +would prune")
                    self.assertRegex(p.stdout, r"dangling Docker images +1\.6G +would prune")
                    self.assertRegex(p.stdout, r"Go build cache +12\.0K +would prune")
                    self.assertRegex(p.stdout, r"pnpm metadata-full \(v12\) +[\d.]+K +would remove")
                    self.assertEqual(bool(re.search(r"Go module cache +[\d.]+K +would prune", p.stdout)), deep)
                    if deep:
                        for name in ("AI history and checkpoints", "Docker volumes"):
                            self.assertIn(name, p.stdout)

    def test_dry_run_keeps_busy_and_process_checks(self):
        # a preview must show what a live run would skip, and keep the same exit codes
        for shell in self.wrappers:
            before = self.snapshot()
            p = self.call(shell, "--dry-run", MOCK_BUSY="pnpm")
            self.assertEqual(p.returncode, 3, p.stdout)
            self.assertRegex(p.stdout, r"pnpm store +[\d.]+K +skipped: pnpm is installing")
            p = self.call(shell, "--dry-run", MOCK_PGREP_RC="3")
            self.assertEqual(p.returncode, 1, p.stdout)
            self.assertIn("refused: could not check for running processes", p.stdout)
            self.assertIn("Some checks failed", p.stdout)
            self.assertEqual(before, self.snapshot())

    def test_dry_run_shows_inventory_errors_and_timeouts(self):
        for shell in self.wrappers:
            p = self.call(shell, "--dry-run", MOCK_INVENTORY_RC="1")
            self.assertEqual(p.returncode, 1, p.stdout)
            self.assertRegex(p.stdout, r"Docker build cache +would prune, size check failed \(exit 1\)")
            self.assertIn("permission denied while trying to connect to the Docker daemon socket", p.stdout)
            self.assertIn("engine finished with failures (exit 1)", p.stdout)
            p = self.call(shell, "--dry-run", MOCK_INVENTORY_RC="124")
            self.assertRegex(p.stdout, r"Docker build cache +would prune, size check timed out")

    def test_invalid_and_duplicate_flags_do_not_call_engine(self):
        for shell in self.wrappers:
            for args in (("--bogus",), ("--dee",), ("--dry-ru",), ("--deep", "--deep"),
                         ("--dry-run", "--dry-run"), ("--deep=true",), ("file",)):
                with self.subTest(shell=shell, args=args):
                    p = self.call(shell, *args)
                    self.assertEqual(p.returncode, 2)
                    self.assertFalse(self.trace.exists())

    def test_help_has_no_engine_side_effect(self):
        for shell in self.wrappers:
            p = self.call(shell, "--help")
            self.assertEqual(p.returncode, 0)
            self.assertFalse(self.trace.exists())
            self.assertIn("usage: cleanup [-h] [--deep] [--dry-run]", p.stdout)

    def test_closed_stdout_keeps_exit_codes(self):
        # cron style callers may close fd 1, usage and help must still answer normally
        for args, rc in ((["--bogus"], 2), (["--help"], 0)):
            p = subprocess.run(["bash", "-c", 'exec >&-; python3 -B "$HOME/.local/bin/cleanup-caches" "$@"', "x", *args],
                               env=self.env, capture_output=True, text=True, timeout=30)
            self.assertEqual(p.returncode, rc, p.stderr)
            self.assertNotIn("Traceback", p.stderr)

    def test_live_native_and_blocked_protection(self):
        for shell in self.wrappers:
            before = self.protected()
            p = self.call(shell, "--deep")
            self.assertEqual(p.returncode, 0, p.stdout + p.stderr)
            self.assertRegex(p.stdout, r"\[1/8\] Build caches")
            self.assertRegex(p.stdout, r"Docker build cache +reclaimed 0B +pruned")
            self.assertRegex(p.stdout, r"Go build cache +12\.0K -> 0B +pruned")
            self.assertIn("Left alone, these are data rather than cache", p.stdout)
            self.assertNotIn("\x1b", p.stdout)  # no escapes when not a tty
            # source, outputs, runner homes, history and personal files survive
            self.assertEqual(before, self.protected())

    def best_effort_fixture(self):
        for name in (".cache/node-gyp/headers", ".cache/typescript/types", ".cache/jdtls-abc/index",
                     ".cargo/registry/cache/crate.crate", ".gradle/caches/jar", ".npm/_npx/pkg",
                     ".npm/_cacache/index", "node-compile-cache/blob", "hosttmp/node-compile-cache/blob",
                     ".bun/install/cache/pkg"):
            p = self.home / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text("cache " + name)

    def test_best_effort_clears_idle_caches(self):
        for shell in self.wrappers:
            self.best_effort_fixture()
            p = self.call(shell, "--deep")
            self.assertEqual(p.returncode, 0, p.stdout)
            self.assertIn("Cleanup complete", p.stdout)
            for gone in (".cache/pnpm/v11/metadata", ".cache/pnpm/v12/metadata-full", ".cache/node-gyp",
                         ".cache/typescript", ".cache/jdtls-abc", ".cargo/registry/cache",
                         ".gradle/caches", ".npm/_npx", "node-compile-cache", "hosttmp/node-compile-cache",
                         ".bun/install/cache"):
                self.assertFalse((self.home / gone).exists(), gone)
            trace = self.traced()
            for call in ("pnpm store prune", "npm cache clean --force", "go clean -modcache"):
                self.assertIn(call, trace)
            self.assertTrue((self.home / "go/bin/tool").exists())

    def test_best_effort_baseline_is_complete(self):
        for shell in self.wrappers:
            p = self.call(shell)
            self.assertEqual(p.returncode, 0, p.stdout)
            self.assertIn("Cleanup complete", p.stdout)
            self.assertNotIn("Left alone", p.stdout)
            # measured on /, so only its shape is stable
            self.assertRegex(p.stdout, r"Freed:      [\d.]+[BKMGT]\s")
            self.assertFalse((self.home / ".cache/pnpm/v11/metadata").exists())
            self.assertTrue((self.home / "go/pkg/mod/pkg/source").exists())  # deep only

    def test_best_effort_skips_busy_tool(self):
        self.best_effort_fixture()
        for shell in self.wrappers:
            p = self.call(shell, "--deep", MOCK_BUSY="pnpm")
            self.assertEqual(p.returncode, 3, p.stdout)
            self.assertRegex(p.stdout, r"pnpm store +[\d.]+K +skipped: pnpm is installing")
            self.assertIn("Cleanup finished with skipped steps", p.stdout)
            # the skipped list wraps inside the box instead of being cut
            self.assertIn("Skipped:    pnpm store, pnpm metadata (v11),", p.stdout)
            self.assertIn("            pnpm metadata-full (v12).", p.stdout)
            self.assertEqual({len(line) for line in self.box_lines(p.stdout)}, {51})
            self.assertTrue((self.home / ".cache/pnpm/v11/metadata/data").exists())
            self.assertNotIn("pnpm", self.traced())

    def test_best_effort_fails_closed_without_process_visibility(self):
        self.best_effort_fixture()
        for shell in self.wrappers:
            p = self.call(shell, "--deep", MOCK_PGREP_RC="3")
            self.assertEqual(p.returncode, 1, p.stdout)
            self.assertIn("refused: could not check for running processes", p.stdout)
            self.assertIn("Cleanup finished with failures", p.stdout)
            self.assertTrue((self.home / ".cache/node-gyp/headers").exists())
            self.assertTrue((self.home / ".cache/pnpm/v11/metadata/data").exists())

    def test_best_effort_never_follows_symlinked_cache(self):
        outside = self.home / "Downloads"
        (self.home / ".cache/node-gyp").symlink_to(outside, target_is_directory=True)
        for shell in self.wrappers:
            p = self.call(shell, "--deep")
            self.assertEqual(p.returncode, 1, p.stdout)
            self.assertRegex(p.stdout, r"node-gyp headers +refused: symlinked")
            self.assertTrue((outside / "personal").exists())

    def test_symlinked_cache_root_fails_closed(self):
        # a symlinked ~/.cache refuses uv even when its cache dir is missing, and every path under it
        real = self.home / "real-cache"
        (self.home / ".cache").rename(real)
        (self.home / ".cache").symlink_to(real, target_is_directory=True)
        for shell in self.wrappers:
            p = self.call(shell)
            self.assertEqual(p.returncode, 1, p.stdout)
            self.assertRegex(p.stdout, r"uv cache +refused: symlinked or noncanonical path")
            self.assertRegex(p.stdout, r"pnpm metadata \(v11\) +refused: symlinked")
            self.assertTrue((real / "pnpm/v11/metadata/data").exists())

    def test_best_effort_uses_cleaner_lock(self):
        lock = self.home / ".hermes/profiles/sean/maintenance/hourly-cache-clean/run.lock"
        lock.parent.mkdir(parents=True)
        lock.touch()
        with lock.open() as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            for shell in self.wrappers:
                p = self.call(shell)
                self.assertEqual(p.returncode, 75, p.stdout)
                self.assertRegex(p.stdout, r"pnpm store +skipped: another cleanup holds the lock")
                self.assertTrue((self.home / ".cache/pnpm/v11/metadata/data").exists())

    def test_lock_busy_beats_refusal(self):
        # a retry-later run stays 75 even when a cache would be refused on its own
        (self.home / ".cache/node-gyp").symlink_to(self.home / "Downloads", target_is_directory=True)
        lock = self.home / ".hermes/profiles/sean/maintenance/hourly-cache-clean/run.lock"
        lock.parent.mkdir(parents=True)
        lock.touch()
        with lock.open() as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            for shell in self.wrappers:
                p = self.call(shell, "--deep")
                self.assertEqual(p.returncode, 75, p.stdout)
                self.assertRegex(p.stdout, r"node-gyp headers +skipped: another cleanup holds the lock")

    def test_codex_keeps_current_and_previous(self):
        releases = self.home / ".codex/packages/app-server-daemon/releases"
        for i, name in enumerate(("0.1.0-x86_64-unknown-linux-musl", "0.2.0-x86_64-unknown-linux-musl",
                                  "0.3.0-x86_64-unknown-linux-musl", "0.4.0-x86_64-unknown-linux-musl")):
            (releases / name / "bin").mkdir(parents=True)
            os.utime(releases / name, (1000 + i, 1000 + i))
        (releases.parent / "current").symlink_to(releases / "0.3.0-x86_64-unknown-linux-musl", target_is_directory=True)
        p = self.call("bash", "--deep")
        self.assertEqual(p.returncode, 0, p.stdout)
        self.assertRegex(p.stdout, r"Codex release 0\.1\.0 +\S+ -> 0B +removed")
        self.assertRegex(p.stdout, r"Codex release 0\.2\.0 +\S+ -> 0B +removed")
        # 0.3.0 is current, 0.4.0 the newest other one; older releases retire
        self.assertEqual(sorted(x.name[:5] for x in releases.iterdir()), ["0.3.0", "0.4.0"])
        p = self.call("zsh", "--deep")
        self.assertEqual(p.returncode, 0, p.stdout)
        self.assertNotIn("Codex release", p.stdout)
        self.assertEqual(sorted(x.name[:5] for x in releases.iterdir()), ["0.3.0", "0.4.0"])

    def test_codex_broken_layout_refuses_codex_only(self):
        releases = self.home / ".codex/packages/app-server-daemon/releases"
        (releases / "0.1.0" / "bin").mkdir(parents=True)
        (releases.parent / "current").symlink_to(self.home / "elsewhere", target_is_directory=True)
        for shell in self.wrappers:
            self.best_effort_fixture()
            p = self.call(shell, "--deep")
            self.assertEqual(p.returncode, 1, p.stdout)
            self.assertRegex(p.stdout, r"Codex releases +refused: current does not point into releases")
            self.assertTrue((releases / "0.1.0/bin").exists())
            # unrelated caches are still cleaned, only the exit code carries the refusal
            self.assertFalse((self.home / ".cache/typescript").exists())

    def test_codex_running_release_is_kept(self):
        releases = self.home / ".codex/packages/app-server-daemon/releases"
        for i, name in enumerate(("0.1.0", "0.2.0", "0.3.0")):
            (releases / name / "bin").mkdir(parents=True)
            os.utime(releases / name, (1000 + i, 1000 + i))
        (releases.parent / "current").symlink_to(releases / "0.3.0", target_is_directory=True)
        out = io.StringIO()
        # /proc cannot be faked from outside, so this one runs main() in process
        with patch.dict(os.environ, self.env), patch.object(sys, "argv", ["cleanup", "--deep"]), \
                patch.object(front, "running_from", return_value=True), contextlib.redirect_stdout(out):
            rc = front.main()
        self.assertEqual(rc, 3, out.getvalue())
        self.assertRegex(out.getvalue(), r"Codex release 0\.1\.0 +skipped: Codex still runs from it")
        self.assertTrue((releases / "0.1.0/bin").exists())

    def uv_fixture(self):
        cache = self.home / ".cache/uv"
        cache.mkdir(parents=True)
        (cache / "CACHEDIR.TAG").write_text("Signature: 8a477f597d28d172789f06886806bc55")
        lock = self.home / ".hermes/profiles/sean/maintenance/hourly-cache-clean/run.lock"
        lock.parent.mkdir(parents=True)
        lock.touch()
        uv = self.home / ".local/bin/uv"
        uv.write_text(MOCK_UV)
        uv.chmod(0o700)
        return cache, lock

    def test_native_uv_preview_live_busy_error_and_identity(self):
        cache, lock = self.uv_fixture()
        for shell in self.wrappers:
            p = self.call(shell, "--deep", "--dry-run")
            self.assertEqual(p.returncode, 0, p.stdout)
            self.assertRegex(p.stdout, r"uv cache +[\d.]+K +would prune")
            self.assertNotIn("uv lock-timeout", self.traced())
            p = self.call(shell)
            self.assertEqual(p.returncode, 0, p.stdout)
            self.assertRegex(p.stdout, r"uv cache +[\d.]+K -> [\d.]+K +pruned")
            self.assertIn(f"uv lock-timeout=1 --no-config --offline --cache-dir {cache} cache prune", self.traced())
            p = self.call(shell, MOCK_UV_RC="2")
            self.assertEqual(p.returncode, 3)
            self.assertRegex(p.stdout, r"uv cache +[\d.]+K +skipped: uv is running")
            p = self.call(shell, MOCK_UV_RC="9")
            self.assertEqual(p.returncode, 1)
            self.assertRegex(p.stdout, r"uv cache +[\d.]+K -> [\d.]+K +failed \(exit 9\)")
        (cache / "CACHEDIR.TAG").write_text("NOT CACHE")
        for shell in self.wrappers:
            p = self.call(shell)
            self.assertEqual(p.returncode, 1)
            self.assertIn("refused: cache marker missing or invalid", p.stdout)
            self.assertNotIn("uv lock-timeout", self.traced())

    def test_native_uv_uses_existing_cleaner_lock(self):
        cache, lock = self.uv_fixture()
        with lock.open() as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            for shell in self.wrappers:
                p = self.call(shell)
                self.assertEqual(p.returncode, 75, p.stdout)
                self.assertRegex(p.stdout, r"uv cache +[\d.]+K +skipped: another cleanup holds the lock")
                self.assertNotIn("uv lock-timeout", self.traced())

    def test_failure_dominates_later_uv_contention(self):
        cache, lock = self.uv_fixture()
        other = self.home / ".hermes/cache/uv"
        other.mkdir(parents=True)
        (other / "CACHEDIR.TAG").write_text("Signature: 8a477f597d28d172789f06886806bc55")
        with lock.open() as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            for shell in self.wrappers:
                p = self.call(shell, MOCK_ENGINE_RC="8")
                self.assertEqual(p.returncode, 1, p.stdout)
                self.assertIn("engine finished with failures (exit 8)", p.stdout)
            (cache / "CACHEDIR.TAG").write_text("NOT CACHE")
            for shell in self.wrappers:
                p = self.call(shell, "--deep")
                self.assertEqual(p.returncode, 1, p.stdout)
                self.assertRegex(p.stdout, r"Hermes uv cache +[\d.]+K +skipped: another cleanup holds the lock")

    def test_uv_marker_symlink_and_fifo_fail_without_execution(self):
        cache, lock = self.uv_fixture()
        marker = cache / "CACHEDIR.TAG"
        target = self.home / "external-marker"
        marker.rename(target)
        marker.symlink_to(target)
        for shell in self.wrappers:
            p = self.call(shell)
            self.assertEqual(p.returncode, 1, p.stdout)
            self.assertRegex(p.stdout, r"uv cache +refused:")
            self.assertNotIn("uv lock-timeout", self.traced())
        marker.unlink()
        os.mkfifo(marker)
        for shell in self.wrappers:
            p = self.call(shell)
            self.assertEqual(p.returncode, 1, p.stdout)
            self.assertIn("refused: cache marker is not a regular file", p.stdout)
            self.assertNotIn("uv lock-timeout", self.traced())

    def test_native_environment_cannot_redirect_stores(self):
        for shell in self.wrappers:
            p = self.call(shell, "--dry-run", GOCACHE="/not-approved", GOENV="/not-approved",
                          GOFLAGS="-modcache", GOTOOLCHAIN="auto", DOCKER_CONFIG="/not-approved")
            self.assertEqual(p.returncode, 0)
            self.assertIn(f"GOCACHE={self.home}/.cache/go-build GOFLAGS= GOENV=off GOTOOLCHAIN=local "
                          f"DOCKER_CONFIG={self.home}/.docker", self.traced())

    def test_native_failure_is_not_incomplete_success(self):
        for shell in self.wrappers:
            p = self.call(shell, MOCK_ENGINE_RC="8")
            self.assertEqual(p.returncode, 1)
            self.assertIn("engine finished with failures (exit 8)", p.stdout)
            self.assertIn("Cleanup finished with failures", p.stdout)

    def test_engine_lock_busy_stops_everything(self):
        # 75 from the engine means nothing else is touched, live or dry
        with (self.home / "fixture.lock").open() as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            for shell in self.wrappers:
                for args in ((), ("--deep", "--dry-run")):
                    p = self.call(shell, *args)
                    self.assertEqual(p.returncode, 75, p.stdout)
                    self.assertIn("skipped: another cleanup holds the lock", p.stdout)
                    self.assertIn("Cleanup skipped, another run holds the lock", p.stdout)
                    self.assertNotIn("[2/", p.stdout)
                    self.assertTrue((self.home / ".cache/pnpm/v11/metadata/data").exists())
                    self.assertNotIn("pnpm", self.traced())

    def test_missing_engine_still_runs_portable_phases(self):
        # laptops have no Hermes engine, cleanup must still prune their caches
        self.engine.unlink()
        for shell in self.wrappers:
            p = self.call(shell)
            self.assertEqual(p.returncode, 0, p.stdout + p.stderr)
            self.assertIn("no cleanup engine on this host, skipping", p.stdout)
            self.assertFalse((self.home / ".cache/pnpm/v11/metadata").exists())

    def test_missing_frontend_no_fallback(self):
        (self.home / ".local/bin/cleanup-caches").unlink()
        for shell in self.wrappers:
            p = self.call(shell, "--deep")
            self.assertEqual(p.returncode, 1)
            self.assertIn("missing guarded frontend", p.stderr)

    def write(self, *names, text="x"):
        for name in names:
            p = self.home / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(text)

    def age(self, *paths):
        # everything under a project, git dir included, looks untouched for days
        old = time.time() - DAYS_AGO
        for top in paths:
            for p in [top, *top.rglob("*")]:
                os.utime(p, (old, old), follow_symlinks=False)

    def git_repo(self, name, files, ignore, tracked):
        root = self.home / name
        self.write(*(f"{name}/{f}" for f in files))
        (root / ".gitignore").write_text(ignore)
        run = lambda *a: subprocess.run(["git", "-C", str(root), "-c", "user.name=t", "-c", "user.email=t@t", *a],
                                        check=True, capture_output=True, env=self.env)
        run("init", "-q")
        run("add", "-f", ".gitignore", *tracked)
        run("commit", "-qm", "init")
        return root

    def project_fixture(self):
        app = self.git_repo("code/owned/app",
                            ["node_modules/x/index.js", "build/out.js", "dist/keep.js", "target/notes.md",
                             "coverage/badge.svg", "coverage/lcov.info", "src/main.ts"],
                            "node_modules/\nbuild/\ncoverage/\n", ["dist/keep.js", "coverage/badge.svg", "src/main.ts"])
        mobile = self.git_repo("code/owned/mobile", ["android/app/build/outputs/apk/app.apk", "android/app/build/tmp/x"],
                               "build/\n", [])
        fresh = self.git_repo("code/owned/fresh", ["node_modules/x/index.js"], "node_modules/\n", [])
        self.write(".t3/scratch/thread-old/package.json", ".t3/scratch/thread-old/node_modules/x/index.js",
                   ".t3/scratch/thread-old/fixtures/node_modules/active", ".t3/scratch/thread-old/build/report.html",
                   ".t3/scratch/thread-old/.venv/pyvenv.cfg", ".t3/scratch/thread-old/__pycache__/m.pyc",
                   ".t3/scratch/thread-busy/package.json", ".t3/scratch/thread-busy/node_modules/x/index.js")
        old, busy = self.home / ".t3/scratch/thread-old", self.home / ".t3/scratch/thread-busy"
        self.age(app, mobile, old, busy)
        return app, mobile, fresh, old, busy

    def test_project_outputs_follow_git_activity_and_use(self):
        app, mobile, fresh, old, busy = self.project_fixture()
        # a dev server sitting in thread-busy
        sleeper = subprocess.Popen(["sleep", "60"], cwd=busy)
        self.addCleanup(sleeper.wait)
        self.addCleanup(sleeper.kill)
        before = self.snapshot()
        p = self.call("zsh", "--deep", "--dry-run")
        self.assertEqual(p.returncode, 3, p.stdout)
        self.assertRegex(p.stdout, r"~/code +[\d.]+K +would remove, 1 project\n")
        self.assertIn("touched today: owned/fresh", p.stdout)
        self.assertRegex(p.stdout, r"~/\.t3/scratch +[\d.]+K +would remove, 1 project\n +in use: thread-busy")
        self.assertEqual(before, self.snapshot())

        p = self.call("bash", "--deep")
        self.assertEqual(p.returncode, 3, p.stdout)
        self.assertIn("1 project in use", p.stdout)
        # only what git ignores and tracks nothing in goes
        for gone in ("node_modules", "build"):
            self.assertFalse((app / gone).exists(), gone)
        for kept in ("dist/keep.js", "target/notes.md", "coverage/badge.svg", "coverage/lcov.info", "src/main.ts"):
            self.assertTrue((app / kept).exists(), kept)
        self.assertTrue((mobile / "android/app/build/outputs/apk/app.apk").exists())
        self.assertTrue((fresh / "node_modules/x/index.js").exists())
        # outside git only real caches go, a fixture named node_modules and a build/ stay
        for gone in ("node_modules", ".venv", "__pycache__"):
            self.assertFalse((old / gone).exists(), gone)
        for kept in ("fixtures/node_modules/active", "build/report.html", "package.json"):
            self.assertTrue((old / kept).exists(), kept)
        self.assertTrue((busy / "node_modules/x/index.js").exists())

    def test_output_we_cannot_empty_is_kept_whole(self):
        # stands in for root-owned output from a container build, rmtree would stop halfway
        root = self.git_repo("code/owned/java", ["out/ie/Main.class", "node_modules/x/index.js"],
                             "out/\nnode_modules/\n", [])
        locked = root / "out/ie"
        locked.chmod(0o555)
        self.addCleanup(locked.chmod, 0o755)
        self.age(root)
        p = self.call("bash", "--deep")
        self.assertEqual(p.returncode, 0, p.stdout)
        self.assertIn("kept, owned by another user: owned/java", p.stdout)
        self.assertTrue((root / "out/ie/Main.class").exists())
        self.assertFalse((root / "node_modules").exists())

    def test_uninitialised_submodule_is_kept_not_refused(self):
        root = self.git_repo("code/owned/course", ["sub/out/Main.class", "out/Main.class"], "out/\n", [])
        subprocess.run(["git", "-C", str(root), "update-index", "--add", "--cacheinfo", "160000," + "1" * 40 + ",sub"],
                       check=True, capture_output=True)
        dirs = [root / "out", root / "sub/out"]
        self.assertEqual(front.removable_outputs(root, True, dirs), [root / "out"])

    def runner_fixture(self):
        runner = self.home / "actions-runners/swim-1"
        self.write(*(f"actions-runners/swim-1/{f}" for f in (
            "bin/Runner.Listener", "externals/node/bin/node", "home/.pnpm-store/v10/pkg", "home/.cache/ms-playwright/x",
            "home/.npm/_cacache/index", "home/setup-pnpm/pnpm", "_work/swim/swim/package.json",
            "_work/_tool/node/24/bin/node", "_work/_actions/actions/checkout/x")))
        self.write("actions-runners/dist/actions-runner.tar.gz")
        return runner

    def test_runner_caches_go_only_while_no_job_runs(self):
        runner = self.runner_fixture()
        p = self.call("bash", "--deep", MOCK_BUSY="Runner")
        self.assertEqual(p.returncode, 3, p.stdout)
        self.assertRegex(p.stdout, r"swim-1 pnpm store +[\d.]+K +skipped: a CI job is running")
        self.assertTrue((runner / "home/.pnpm-store/v10/pkg").exists())
        p = self.call("zsh", "--deep")
        self.assertEqual(p.returncode, 0, p.stdout)
        for gone in ("home/.pnpm-store", "home/.cache", "home/.npm/_cacache", "_work/swim"):
            self.assertFalse((runner / gone).exists(), gone)
        # the runner's own install, tool cache and action cache stay
        for kept in ("bin/Runner.Listener", "externals/node/bin/node", "home/setup-pnpm/pnpm",
                     "_work/_tool/node/24/bin/node", "_work/_actions/actions/checkout/x"):
            self.assertTrue((runner / kept).exists(), kept)
        self.assertTrue((self.home / "actions-runners/dist/actions-runner.tar.gz").exists())

    def test_jenkins_exports_go_only_while_the_agent_is_idle(self):
        self.write("jenkins-cache/oghma-prod-app/index.json", "jenkins-cache/swim-dev-api/blobs/sha256/a")
        cache = self.home / "jenkins-cache"
        p = self.call("bash", "--deep", MOCK_JENKINS="1", MOCK_JENKINS_BUSY="1")
        self.assertEqual(p.returncode, 3, p.stdout)
        self.assertRegex(p.stdout, r"oghma-prod-app +[\d.]+K +skipped: a Jenkins build is running")
        p = self.call("bash", "--deep", "--dry-run", MOCK_JENKINS="1")
        self.assertRegex(p.stdout, r"swim-dev-api +[\d.]+K +would remove")
        self.assertEqual(sorted(x.name for x in cache.iterdir()), ["oghma-prod-app", "swim-dev-api"])
        p = self.call("zsh", "--deep", MOCK_JENKINS="1")
        self.assertEqual(p.returncode, 0, p.stdout)
        self.assertRegex(p.stdout, r"oghma-prod-app +[\d.]+K -> 0B +removed")
        self.assertEqual(list(cache.iterdir()), [])
        # without an agent the step is a plain skip
        p = self.call("bash", "--deep")
        self.assertIn("no Jenkins agent running on this host, skipping", p.stdout)

    def test_app_images_removed_by_id_after_a_recheck(self):
        ident = "sha256:" + "a" * 64
        policy = self.home / ".hermes/profiles/sean/scripts/hourly-tagged-image-policy.py"
        policy.write_text("import json\n"
                          "print(json.dumps({'category': 'tagged-app-images', 'status': 'inventory'}))\n"
                          f"print(json.dumps({{'status': 'skipped', 'image': '{ident}', "
                          "'tags': ['swim-api:abc1234'], 'logical_size_bytes': 123456789}))\n")
        p = self.call("bash", "--deep", "--dry-run")
        self.assertRegex(p.stdout, r"swim-api:abc1234 +117\.7M +would remove")
        self.assertNotIn("image rm", self.traced())
        p = self.call("bash", "--deep", MOCK_IMAGE_TAGS='["swim-api:latest"]')
        self.assertEqual(p.returncode, 3, p.stdout)
        self.assertIn("skipped: retagged since the check", p.stdout)
        self.assertNotIn("image rm", self.traced())
        p = self.call("bash", "--deep", MOCK_IMAGE_IN_USE="1")
        self.assertEqual(p.returncode, 3, p.stdout)
        self.assertIn("skipped: a container uses it", p.stdout)
        p = self.call("zsh", "--deep")
        self.assertEqual(p.returncode, 0, p.stdout)
        self.assertRegex(p.stdout, r"swim-api:abc1234 +117\.7M +removed")
        self.assertIn(f"docker image rm {ident}", self.traced())

    # unit checks on the frontend module itself

    def test_unreadable_inventory_is_unknown_not_zero(self):
        with patch.object(front.subprocess, "run", side_effect=PermissionError):
            self.assertIsNone(front.allocated(self.home))

    def test_symlink_not_followed(self):
        p = self.home / "link"
        p.symlink_to(self.home / "Downloads", target_is_directory=True)
        self.assertIsNone(front.allocated(p))

    def test_busy_patterns_tolerate_flags(self):
        # pgrep is mocked everywhere else, so the real patterns need their own check
        busy = ("pnpm install", "pnpm -r install", "pnpm --filter web add zod",
                "/usr/bin/node /x/.local/share/pnpm/pnpm -C app install", "node /x/pnpm.cjs --dir app i",
                "pnpx create-vite", "npm ci", "npm --prefix app install", "node /x/npm-cli.js -w pkg i")
        idle = ("pnpm dev", "pnpm --filter web dev", "pnpm run build", "npm start",
                "npm run dev -- --port 3000", "node server.js", "pnpm run update-deps")
        for cmd in busy:
            self.assertTrue(re.search(front.PNPM, cmd) or re.search(front.NPM, cmd), cmd)
        for cmd in idle:
            self.assertFalse(re.search(front.PNPM, cmd) or re.search(front.NPM, cmd), cmd)

    def test_human_sizes(self):
        self.assertEqual([front.human(n) for n in (None, 0, 512, 12288, 6723383296, -2048)],
                         ["?", "0B", "512B", "12.0K", "6.3G", "-2.0K"])
        # a shade under a boundary rounds into the next unit, never 1024.0M
        self.assertEqual(front.human(1048575 * 1024), "1.0G")
        self.assertEqual(front.human(1023 * 1024), "1023.0K")
        self.assertEqual(front.docker_bytes("659MB"), 659_000_000)
        self.assertEqual(front.docker_bytes("1.5GiB"), 1610612736)
        self.assertEqual(front.docker_bytes("0B"), 0)
        self.assertIsNone(front.docker_bytes("lots"))

    def test_box_is_fixed_width_and_truncates(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            front.box("1;92", "t" * 60, "short", "l" * 60)
        lines = [l for l in out.getvalue().splitlines() if l]
        self.assertEqual({len(l) for l in lines}, {51})
        self.assertEqual(lines[1], "│  " + "t" * 47 + "│")
        self.assertEqual(lines[2], "│  short" + " " * 42 + "│")

    def test_item_columns_are_fixed(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            front.item("Go build cache", "would prune", "12.0K")
            front.item("npm download cache", "skipped: npm is installing", "481.2M")
            front.item("Jenkins BuildKit cache", "would prune")
        lines = out.getvalue().splitlines()
        self.assertEqual(lines[0], "      Go build cache" + " " * 15 + "12.0K" + " " * 16 + "would prune")
        self.assertEqual(lines[1].index("skipped"), lines[0].index("would"))
        self.assertEqual(lines[2], "      Jenkins BuildKit cache" + " " * 28 + "would prune")

    def test_pack_never_splits_an_item(self):
        self.assertEqual(front.pack(["aa", "bb", "cc"], 7), ["aa, bb,", "cc."])
        self.assertEqual(front.pack(["one item longer than width"], 5), ["one item longer than width."])

    def test_engine_log_summary(self):
        log = (REPO / "tests/fixtures/engine-run.log").read_text()
        records = {r["category"]: r for r in front.parse_engine(log)}
        self.assertEqual(list(records), ["jenkins-buildkit", "default-buildkit", "dangling-images", "go-build"])
        self.assertEqual(records["jenkins-buildkit"]["reclaimed"], "0B")
        self.assertEqual(records["default-buildkit"]["reclaimed"], "659.4MB")
        self.assertEqual(records["dangling-images"]["EXIT_STATUS"], "1")
        self.assertEqual(records["dangling-images"]["lines"], ["Error response from daemon: prune already running"])
        self.assertEqual((records["go-build"]["BEFORE_BYTES"], records["go-build"]["AFTER_BYTES"]), (12288, 0))
        self.assertNotIn("Finished: 2026-10-22T19:19:40+01:00", str(records))


if __name__ == "__main__":
    unittest.main(verbosity=2)
