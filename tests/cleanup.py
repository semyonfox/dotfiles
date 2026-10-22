#!/usr/bin/env python3
"""Isolated integration regressions for BOTH real shell wrappers; never old deep."""
import hashlib
import importlib.machinery
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[1]
FRONT = REPO / "home/.local/bin/cleanup-caches"
loader = importlib.machinery.SourceFileLoader("cleanup_front", str(FRONT))
spec = importlib.util.spec_from_loader(loader.name, loader)
front = importlib.util.module_from_spec(spec)
loader.exec_module(front)


class CleanupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="cleanup-test-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        (self.home / ".local/bin").mkdir(parents=True)
        shutil.copyfile(FRONT, self.home / ".local/bin/cleanup-caches")
        self.engine = self.home / ".hermes/profiles/sean/scripts/hourly-build-cache-clean.sh"
        self.engine.parent.mkdir(parents=True)
        self.engine.write_text('''set -eu
printf 'ARGS'; printf ' <%s>' "$@"; printf '\\n'
printf 'NATIVE_ENV GOCACHE=%s GOFLAGS=%s GOENV=%s GOTOOLCHAIN=%s DOCKER_CONFIG=%s\\n' "$GOCACHE" "$GOFLAGS" "$GOENV" "$GOTOOLCHAIN" "$DOCKER_CONFIG"
[[ "$1 $2" == '--native-only --stdout' ]] || exit 99
[[ ${MOCK_ENGINE_RC:-0} == 0 ]] || exit "$MOCK_ENGINE_RC"
exec 9<"$HOME/fixture.lock"
flock -n 9 || exit 75
if [[ ${3:-} == --dry-run ]]; then
  printf 'DRY_RUN native command NOT executed\\n'
else
  printf 'CATEGORY=default-buildkit EXIT_STATUS=0\\nNATIVE_RECLAIM Total reclaimed space: 0B\\n'
fi
''')
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
        (self.mockbin / "pgrep").write_text(
            '#!/bin/bash\n'
            'pattern=${@: -1}\n'
            '[[ -n ${MOCK_PGREP_RC:-} ]] && exit "$MOCK_PGREP_RC"\n'
            '[[ -n ${MOCK_BUSY:-} && $pattern == *"$MOCK_BUSY"* ]] && exit 0\n'
            'exit 1\n')
        for tool in self.mockbin.iterdir():
            tool.chmod(0o700)
        self.env = dict(os.environ, HOME=str(self.home), TMPDIR=str(self.home),
                        XDG_CACHE_HOME=str(self.home / ".cache"), TRACE=str(self.trace),
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
        return subprocess.run([shell, "-c", self.wrappers[shell] + '\ncleanup "$@"', "cleanup-test", *args],
                              env=dict(self.env, **env), capture_output=True, text=True, timeout=30)

    def snapshot(self):
        return {str(p.relative_to(self.home)): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in self.home.rglob("*") if p.is_file()}

    def test_flag_combinations_preview_and_retention(self):
        for shell in self.wrappers:
            for args in (("--deep", "--dry-run"), ("--dry-run", "--deep"), ("--dry-run",)):
                with self.subTest(shell=shell, args=args):
                    before = self.snapshot()
                    p = self.call(shell, *args)
                    deep = "--deep" in args
                    self.assertEqual(p.returncode, 3 if deep else 0, p.stderr + p.stdout)
                    self.assertIn("ARGS <--native-only> <--stdout> <--dry-run>", p.stdout)
                    self.assertIn("PREVIEW ONLY", p.stdout)
                    self.assertEqual("INCOMPLETE:" in p.stdout, deep)
                    self.assertNotIn("Cleanup complete", p.stdout)
                    self.assertEqual(before, self.snapshot())
                    self.assertIn("CATEGORY=pnpm-v12-metadata-full DRY_RUN=1", p.stdout)
                    self.assertEqual("CATEGORY=go-modules DRY_RUN=1" in p.stdout, deep)
                    if deep:
                        for item in ("generated-t3-android", "runner-home-runner", "tagged-images"):
                            self.assertIn("category=" + item, p.stdout)

    def test_invalid_and_duplicate_flags_do_not_call_engine(self):
        for shell in self.wrappers:
            for args in (("--bogus",), ("--dee",), ("--dry-ru",), ("--deep", "--deep"), ("--dry-run", "--dry-run"), ("--deep=true",), ("file",)):
                with self.subTest(shell=shell, args=args):
                    p = self.call(shell, *args)
                    self.assertEqual(p.returncode, 2)
                    self.assertNotIn("ARGS", p.stdout)

    def test_help_has_no_engine_side_effect(self):
        for shell in self.wrappers:
            p = self.call(shell, "--help")
            self.assertEqual(p.returncode, 0)
            self.assertNotIn("ARGS", p.stdout)
            self.assertIn("NOT source/output", p.stdout)

    def protected(self):
        return {k: v for k, v in self.snapshot().items()
                if not k.startswith((".cache/", "trace", "mockbin/"))}

    def test_live_native_and_blocked_protection(self):
        for shell in self.wrappers:
            before = self.protected()
            p = self.call(shell, "--deep")
            self.assertEqual(p.returncode, 3, p.stdout + p.stderr)
            self.assertIn("CATEGORY=default-buildkit EXIT_STATUS=0", p.stdout)
            self.assertIn("Native engine exit_status=0", p.stdout)
            self.assertIn("NOT attributed cleanup recovery", p.stdout)
            self.assertIn("late starts", p.stdout)
            # source, outputs, runner homes, history and personal files survive
            self.assertEqual(before, self.protected())

    def best_effort_fixture(self):
        for name in (".cache/node-gyp/headers", ".cache/typescript/types", ".cache/jdtls-abc/index",
                     ".cargo/registry/cache/crate.crate", ".gradle/caches/jar", ".npm/_npx/pkg",
                     ".npm/_cacache/index", "node-compile-cache/blob", ".bun/install/cache/pkg"):
            p = self.home / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text("cache " + name)

    def test_best_effort_clears_idle_caches(self):
        for shell in self.wrappers:
            self.best_effort_fixture()
            self.trace.write_text("")
            p = self.call(shell, "--deep")
            self.assertEqual(p.returncode, 3, p.stdout)  # deep blockers remain
            self.assertIn("Best-effort phase exit_status=0", p.stdout)
            for gone in (".cache/pnpm/v11/metadata", ".cache/pnpm/v12/metadata-full", ".cache/node-gyp",
                         ".cache/typescript", ".cache/jdtls-abc", ".cargo/registry/cache",
                         ".gradle/caches", ".npm/_npx", "node-compile-cache", ".bun/install/cache"):
                self.assertFalse((self.home / gone).exists(), gone)
            trace = self.trace.read_text()
            for call in ("pnpm store prune", "npm cache clean --force", "go clean -modcache"):
                self.assertIn(call, trace)
            self.assertTrue((self.home / "go/bin/tool").exists())

    def test_best_effort_baseline_is_complete(self):
        for shell in self.wrappers:
            p = self.call(shell)
            self.assertEqual(p.returncode, 0, p.stdout)
            self.assertNotIn("INCOMPLETE", p.stdout)
            self.assertFalse((self.home / ".cache/pnpm/v11/metadata").exists())
            self.assertTrue((self.home / "go/pkg/mod/pkg/source").exists())  # deep only

    def test_best_effort_skips_busy_tool(self):
        self.best_effort_fixture()
        for shell in self.wrappers:
            self.trace.write_text("")
            p = self.call(shell, "--deep", MOCK_BUSY="pnpm")
            self.assertEqual(p.returncode, 3, p.stdout)
            self.assertIn("CATEGORY=pnpm-store STATUS=skipped-busy", p.stdout)
            self.assertTrue((self.home / ".cache/pnpm/v11/metadata/data").exists())
            self.assertNotIn("pnpm", self.trace.read_text())

    def test_best_effort_fails_closed_without_process_visibility(self):
        self.best_effort_fixture()
        for shell in self.wrappers:
            p = self.call(shell, "--deep", MOCK_PGREP_RC="3")
            self.assertEqual(p.returncode, 1, p.stdout)
            self.assertIn("process-check-unavailable", p.stdout)
            self.assertTrue((self.home / ".cache/node-gyp/headers").exists())
            self.assertTrue((self.home / ".cache/pnpm/v11/metadata/data").exists())

    def test_best_effort_never_follows_symlinked_cache(self):
        outside = self.home / "Downloads"
        (self.home / ".cache/node-gyp").symlink_to(outside, target_is_directory=True)
        for shell in self.wrappers:
            p = self.call(shell, "--deep")
            self.assertEqual(p.returncode, 1, p.stdout)
            self.assertIn("CATEGORY=node-gyp STATUS=failed-closed", p.stdout)
            self.assertTrue((outside / "personal").exists())

    def test_best_effort_uses_cleaner_lock(self):
        import fcntl
        lock = self.home / ".hermes/profiles/sean/maintenance/hourly-cache-clean/run.lock"
        lock.parent.mkdir(parents=True)
        lock.touch()
        with lock.open() as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            for shell in self.wrappers:
                p = self.call(shell)
                self.assertEqual(p.returncode, 75, p.stdout)
                self.assertTrue((self.home / ".cache/pnpm/v11/metadata/data").exists())

    def test_codex_keeps_current_and_previous(self):
        releases = self.home / ".codex/packages/app-server-daemon/releases"
        for i, name in enumerate(("0.1.0", "0.2.0", "0.3.0", "0.4.0")):
            (releases / name / "bin").mkdir(parents=True)
            os.utime(releases / name, (1000 + i, 1000 + i))
        (releases.parent / "current").symlink_to(releases / "0.3.0", target_is_directory=True)
        for shell in self.wrappers:
            p = self.call(shell, "--deep")
            self.assertIn("Best-effort phase exit_status=0", p.stdout)
        # 0.3.0 is current, 0.4.0 the newest other one; older releases retire
        self.assertEqual(sorted(x.name for x in releases.iterdir()), ["0.3.0", "0.4.0"])

    def uv_fixture(self):
        cache = self.home / ".cache/uv"
        cache.mkdir(parents=True)
        (cache / "CACHEDIR.TAG").write_text("Signature: 8a477f597d28d172789f06886806bc55")
        lock = self.home / ".hermes/profiles/sean/maintenance/hourly-cache-clean/run.lock"
        lock.parent.mkdir(parents=True)
        lock.touch()
        uv = self.home / ".local/bin/uv"
        uv.write_text('#!/bin/bash\nprintf "MOCK_UV native-lock-timeout=%s force-never %s\\n" "$UV_LOCK_TIMEOUT" "$*"\nif [[ ${MOCK_UV_RC:-0} == 2 ]]; then printf "Timeout (1s) when waiting for lock on native-cache\\n" >&2; fi\nexit "${MOCK_UV_RC:-0}"\n')
        uv.chmod(0o700)
        return cache, lock

    def test_native_uv_preview_live_busy_error_and_identity(self):
        cache, lock = self.uv_fixture()
        for shell in self.wrappers:
            p = self.call(shell, "--deep", "--dry-run")
            self.assertEqual(p.returncode, 3, p.stdout)
            self.assertIn("NATIVE_PLAN category=uv", p.stdout)
            self.assertNotIn("MOCK_UV", p.stdout)
            p = self.call(shell)
            self.assertEqual(p.returncode, 0, p.stdout)
            self.assertIn("CATEGORY=uv EXIT_STATUS=0 STATUS=ok", p.stdout)
            self.assertIn("MOCK_UV native-lock-timeout=1", p.stdout)
            p = self.call(shell, MOCK_UV_RC="2")
            self.assertEqual(p.returncode, 3)
            self.assertIn("STATUS=skipped-native-lock", p.stdout)
            p = self.call(shell, MOCK_UV_RC="9")
            self.assertEqual(p.returncode, 1)
            self.assertIn("CATEGORY=uv EXIT_STATUS=9 STATUS=failed", p.stdout)
        (cache / "CACHEDIR.TAG").write_text("NOT CACHE")
        for shell in self.wrappers:
            p = self.call(shell)
            self.assertEqual(p.returncode, 1)
            self.assertNotIn("MOCK_UV", p.stdout)
            self.assertIn("marker missing/invalid", p.stdout)

    def test_native_uv_uses_existing_cleaner_lock(self):
        import fcntl
        cache, lock = self.uv_fixture()
        with lock.open() as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            for shell in self.wrappers:
                p = self.call(shell)
                self.assertEqual(p.returncode, 75, p.stdout)
                self.assertNotIn("MOCK_UV", p.stdout)

    def test_failure_dominates_later_uv_contention(self):
        import fcntl
        cache, lock = self.uv_fixture()
        other = self.home / ".hermes/cache/uv"
        other.mkdir(parents=True)
        (other / "CACHEDIR.TAG").write_text("Signature: 8a477f597d28d172789f06886806bc55")
        with lock.open() as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            for shell in self.wrappers:
                p = self.call(shell, MOCK_ENGINE_RC="8")
                self.assertEqual(p.returncode, 1, p.stdout)
                self.assertIn("Native engine exit_status=8", p.stdout)
            (cache / "CACHEDIR.TAG").write_text("NOT CACHE")
            for shell in self.wrappers:
                p = self.call(shell, "--deep")
                self.assertEqual(p.returncode, 1, p.stdout)
                self.assertIn("CATEGORY=hermes-uv STATUS=skipped", p.stdout)

    def test_uv_marker_symlink_and_fifo_fail_without_execution(self):
        cache, lock = self.uv_fixture()
        marker = cache / "CACHEDIR.TAG"
        target = self.home / "external-marker"
        marker.rename(target)
        marker.symlink_to(target)
        for shell in self.wrappers:
            p = self.call(shell)
            self.assertEqual(p.returncode, 1, p.stdout)
            self.assertNotIn("MOCK_UV", p.stdout)
        marker.unlink()
        os.mkfifo(marker)
        for shell in self.wrappers:
            p = self.call(shell)
            self.assertEqual(p.returncode, 1, p.stdout)
            self.assertNotIn("MOCK_UV", p.stdout)
            self.assertIn("not a regular file", p.stdout)

    def test_native_environment_cannot_redirect_stores(self):
        for shell in self.wrappers:
            p = self.call(shell, "--dry-run", GOCACHE="/not-approved", GOENV="/not-approved",
                          GOFLAGS="-modcache", GOTOOLCHAIN="auto", DOCKER_CONFIG="/not-approved")
            self.assertEqual(p.returncode, 0)
            self.assertIn(f"GOCACHE={self.home}/.cache/go-build GOFLAGS= GOENV=off GOTOOLCHAIN=local DOCKER_CONFIG={self.home}/.docker", p.stdout)

    def test_native_failure_is_not_incomplete_success(self):
        for shell in self.wrappers:
            p = self.call(shell, MOCK_ENGINE_RC="8")
            self.assertEqual(p.returncode, 1)
            self.assertIn("Native engine exit_status=8", p.stdout)

    def test_real_shared_lock_contention(self):
        import fcntl
        with (self.home / "fixture.lock").open() as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            for shell in self.wrappers:
                p = self.call(shell, "--deep", "--dry-run")
                self.assertEqual(p.returncode, 75, p.stdout)
                self.assertIn("Native engine exit_status=75", p.stdout)

    def test_missing_engine_still_runs_portable_phases(self):
        # laptops have no Hermes engine, cleanup must still prune their caches
        self.engine.unlink()
        for shell in self.wrappers:
            p = self.call(shell)
            self.assertEqual(p.returncode, 0, p.stdout + p.stderr)
            self.assertIn("SKIPPED native engine not installed", p.stdout)
            self.assertFalse((self.home / ".cache/pnpm/v11/metadata").exists())

    def test_missing_frontend_no_fallback(self):
        (self.home / ".local/bin/cleanup-caches").unlink()
        for shell in self.wrappers:
            p = self.call(shell, "--deep")
            self.assertEqual(p.returncode, 1)
            self.assertIn("missing guarded frontend", p.stderr)

    def test_unreadable_inventory_unknown_not_zero(self):
        with patch.object(front.subprocess, "run", side_effect=PermissionError):
            self.assertIn("unknown", front.allocated(self.home))

    def test_symlink_not_followed(self):
        p = self.home / "link"
        p.symlink_to(self.home / "Downloads", target_is_directory=True)
        self.assertIn("symlink", front.allocated(p))

    def test_unreadable_proc_and_late_consumer_never_admit_shared_delete(self):
        # There is NO observation-based admission path at all. A late new file,
        # open FD, arbitrary process name or unavailable /proc cannot enable it.
        active = self.home / "code/repo/node_modules/active"
        with active.open() as f:
            for shell in self.wrappers:
                late = active.parent / "late-start"
                late.write_text("new consumer requires this")
                p = self.call(shell, "--deep")
                self.assertEqual(p.returncode, 3)
                self.assertIn("process/cwd snapshots", p.stdout)
                self.assertEqual(f.read(), "retain code/repo/node_modules/active")
                f.seek(0)
                self.assertTrue(late.exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
