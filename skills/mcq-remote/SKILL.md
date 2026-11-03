---
name: mcq-remote
description: Use when Semyon asks to answer, finish, or submit a quiz, MCQ, or Canvas checkpoint on his laptop browser, or to poll the laptop until it comes online and take over a browser tab he has prepared.

metadata:
  harnesses: [claude, codex, opencode, cursor]
---

# MCQ remote

Use Semyon's existing Zen session on his laptop, preserving its cookies and logins, then answer, review and submit the quiz using Hyprland physical input.

Laptop access, Tailscale address and Hyprland details live in device-fleet's `references/computers.md`; look up only the laptop entries rather than reading the whole file. `laptop` below means whichever SSH route works today (LAN alias or direct Tailscale). Script paths are relative to this skill's directory.

## Hard rules

- Reuse the existing quiz tab when Semyon has prepared one. Otherwise open only a quiz window with `scripts/open-quiz-window.sh`, which uses the normal Zen session. Never create a separate profile, private session or fresh login session.
- Preserve cookies and logins. Never copy or inspect browser stores, restart Zen, or enable Marionette on the everyday browser. The old `zen-mcq` profile does not share the normal session and must not be used.
- Work only in the quiz tab/window. Never open terminals, consoles, devtools or unrelated tabs.
- No JavaScript execution. Use Hyprland physical input and screenshots.
- No subagents or delegated answer checks.
- Semyon enters access codes himself. Never read or record them.
- "Go" or an earlier "answer and submit" authorizes the work and the submission. Don't ask again.

## Workflow

1. **Poll the laptop.** One loop: `ssh -o BatchMode=yes -o ConnectTimeout=8 laptop true` about every 15s. Short update at least once a minute. Online doesn't mean ready.
2. **Reuse the session.** Inspect the current desktop. If Semyon has prepared a quiz tab, use it without opening anything. Otherwise run `ssh laptop bash -s < scripts/open-quiz-window.sh` to open a blank window in the normal Zen session. Tell Semyon it is ready. He opens the quiz and enters any access code himself.
3. **Set up Hyprland control before the quiz opens.** Find the instance with `hyprctl instances -j` and use `hyprctl -i <n>`. Screenshot with `XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=<socket> grim -`. Identify the exact quiz window address from `hyprctl -i <n> clients -j`, since normal Zen windows can share a PID. Focus, move and click in one eval so Semyon's mouse cannot land in between: `hyprctl -i <n> eval 'hl.dispatch(hl.dsp.focus({window="address:<quiz address>"})) hl.dispatch(hl.dsp.cursor.move({x=...,y=...})) hl.dispatch(hl.dsp.send_shortcut({mods="",key="mouse:272"}))'`. It prints `ok` even when nothing happened, so check `hyprctl cursorpos` / `activewindow` and a fresh screenshot. Coordinates are logical, so divide screenshot pixels by the monitor's actual scale. `xdotool` clicks do not land. `wtype` types plain text only. Use `send_shortcut` for other keys.
4. **Watch, don't touch.** Screenshot while Semyon navigates and enters the code. Start only once he says go and the questions are visible. If he moves the mouse or navigates again, pause input.
5. **Answer.** Read the whole question and every option first. Leave answers Semyon entered alone until the review. After each action, wait for the page to settle and confirm the selection itself (a fresh screenshot). A sidebar checkmark only proves an answer exists. After a click lands wrong, stop and re-check before sending more input.
6. **Review every question** before submitting, including his answers, and keep track of which ones have actually been checked. Budget the time for it. Never say the review is complete if any question was skipped.
7. **Submit as its own step.** Check the summary for unanswered questions, read any confirmation dialog before accepting, then verify the submitted page. A clicked button isn't proof of submission.
8. **Report.** Submission confirmed or not, score only if shown, which control method ran and why any fallback happened, anything unreviewed or uncertain. Separate what was seen from what was inferred. Leave the browser on the result page.

## Pitfalls

- Target the quiz window by its exact address, not by class or PID alone. Check the active window before typing or clicking.
- The launcher must use the normal session without `--profile`, `--private-window`, `--no-remote` or `--marionette`. A separate persistent profile still has different cookies and logins.
- Re-check state after any failure. The last action may have gone through.

## Stop conditions

- Laptop unreachable at the agreed deadline, or Semyon stops the task.
- Access denied, page not found, or a lock screen you can't get past without his input. Report it and wait.
- Hyprland input does not work reliably. Stop rather than guessing on a timed quiz.
