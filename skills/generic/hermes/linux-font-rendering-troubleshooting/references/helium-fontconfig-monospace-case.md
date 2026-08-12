# Helium Linux monospace UI case (research evidence)

**Observed:** Helium vertical-tab/native browser UI rendered in an unwanted monospace/typewriter face while webpage/browser preference settings were being changed.

**Authoritative upstream evidence:** [Helium issue #2051](https://github.com/imputnet/helium/issues/2051), opened 2026-07-04, is titled *“UI and Certain page fonts replaced with system monospace ones.”* The reporter describes Linux Helium forcing mono faces in UI, bookmarks, and selected sites after changing the minimum font size. It remained open when checked on 2026-08-03.

A comment on that issue links Chromium issue `519984267` and reports that the commenter experienced the problem with Fontconfig 2.18.2 and saw it disappear after downgrading to 2.17.1. This is **third-party reproduction evidence only**, not proof that the workaround succeeds on another machine.

**Target-machine correlation at the time:** CachyOS package query returned `fontconfig 2:2.18.2-1.1`; Helium package query returned `helium-browser-bin 0.14.9.1-1`.

**Use:** Once a live screenshot confirms a native-UI mono symptom and exact versions match, present the issue as the likely upstream cause. Do not claim the package downgrade fixes the target until it is explicitly approved, completed through the system package manager, and validated with a before/after screenshot.
