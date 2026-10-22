---
name: mcq-remote
description: Use when Semyon asks to answer, finish, or submit a quiz, MCQ, or Canvas checkpoint on his laptop browser, or to poll the laptop until it comes online and take over a browser tab he has prepared.

metadata:
  harnesses: [claude, codex, opencode, cursor]
---

# MCQ remote

Open a quiz window on Semyon's laptop, let him log in and open the quiz, then answer, review and submit it. Marionette first, Hyprland physical input as the fallback.

Laptop access, Tailscale address and Hyprland details live in device-fleet's `references/computers.md`; look up only the laptop entries rather than reading the whole file. `laptop` below means whichever SSH route works today (LAN alias or direct Tailscale). Script paths are relative to this skill's directory.

## Hard rules

- The only window you open is the quiz window from `scripts/open-quiz-window.sh`. Work in its selected tab. Never open other tabs, windows, terminals, consoles or devtools.
- No JavaScript execution. Marionette is limited to the WebDriver element commands in `scripts/marionette.py`.
- No subagents or delegated answer checks. They cost time and didn't improve accuracy.
- Never touch the everyday Zen or give it `--marionette`. The quiz window is a separate `~/.local/share/zen-mcq` profile with Marionette on 2829, so `navigator.webdriver` (which breaks Cloudflare and Google sign-in) stays out of normal browsing.
- Semyon enters access codes himself. Never read or record them.
- "Go" or an earlier "answer and submit" authorizes the work and the submission. Don't ask again.

## Workflow

1. **Poll the laptop.** One loop: `ssh -o BatchMode=yes -o ConnectTimeout=8 laptop true` about every 15s. Short update at least once a minute. Online doesn't mean ready.
2. **Open the quiz window.** `ssh laptop bash -s < scripts/open-quiz-window.sh` opens a blank Zen window on the quiz profile, or reuses it if it's already up. If he gives a Canvas URL, load it with `python3 - goto <url>`. Tell Semyon it's ready. Logins persist in that profile, so Canvas sign-in is usually only needed once.
3. **Pick the control method before the quiz opens.**
   - Marionette: `ssh laptop python3 - probe < scripts/marionette.py`. If the title/URL doesn't match a screenshot, or anything errors, drop it for this attempt.
   - Hyprland: find the instance with `hyprctl instances -j` and use `hyprctl -i <n>`. Screenshot with `XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=<socket> grim -`. Focus, move and click in one eval so Semyon's mouse can't land in between: `hyprctl -i <n> eval 'hl.dispatch(hl.dsp.focus({window="pid:<quiz pid>"})) hl.dispatch(hl.dsp.cursor.move({x=...,y=...})) hl.dispatch(hl.dsp.send_shortcut({mods="",key="mouse:272"}))'`. It prints `ok` even when nothing happened, so check `hyprctl cursorpos` / `activewindow` or the selection afterwards. Coordinates are logical (scale 1.25), screenshots are physical pixels, so divide by 1.25. `xdotool` clicks don't land; don't try them. `wtype` types plain text only; use `send_shortcut` for other keys.
   - Stick with one method for the whole attempt, and fall back once at most. Switching and debugging input mid-quiz is what turned a 3–4 minute run into 11 on 20 Oct.
4. **Watch, don't touch.** Screenshot while Semyon navigates and enters the code. Start only once he says go and the questions are visible. If he moves the mouse or navigates again, pause input.
5. **Answer.** Read the whole question and every option first. Leave answers Semyon entered alone until the review. After each action, wait for the page to settle and confirm the selection itself (`selected` via Marionette, or a fresh screenshot). A sidebar checkmark only proves an answer exists. After a click lands wrong, stop and re-check before sending more input.
6. **Review every question** before submitting, including his answers, and keep track of which ones have actually been checked. Budget the time for it. Never say the review is complete if any question was skipped.
7. **Submit as its own step.** Check the summary for unanswered questions, read any confirmation dialog before accepting, then verify the submitted page. A clicked button isn't proof of submission.
8. **Report.** Submission confirmed or not, score only if shown, which control method ran and why any fallback happened, anything unreviewed or uncertain. Separate what was seen from what was inferred. Leave the browser on the result page.

## Pitfalls

- With Hyprland input, target the quiz window, not the everyday Zen. Both have class `zen`; the quiz one's pid belongs to the `zen-mcq` profile process.
- Canvas New Quizzes renders inside an iframe. Pass `--frame iframe` (or a tighter selector) to the script.
- Selectors in `marionette.py` are untested against Canvas so far. If `text` or `selected` returns nothing useful within a minute, fall back to Hyprland rather than hunting for selectors.
- Re-check state after any failure. The last action may have gone through.

## Stop conditions

- Laptop unreachable at the agreed deadline, or Semyon stops the task.
- Access denied, page not found, or a lock screen you can't get past without his input. Report it and wait.
- Neither method works reliably. Stop rather than guessing on a timed quiz.
