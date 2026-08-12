# Remote artifact gallery filtering and opening

Use when Semyon asks to view a batch of generated images/SVGs/PNGs on his laptop/PC, especially after files were copied or sent over Discord and he wants a browsable local page rather than a bundle.

## Workflow

1. **Clarify the artifact surface from context before editing any repo/app.** If the current thread just created a local `gallery.html` or opened a browser on a remote device, phrases like “remove screenshots from the webpage” usually mean that generated gallery page, not the production website.
2. Keep the source assets in place; generate or overwrite a local HTML index next to the copied artifacts, e.g. `~/Downloads/OghmaNotes-png-YYYYMMDD-HHMMSS/gallery.html`.
3. Filter by filename/path class rather than manually deleting files:
   - architecture/flow diagrams: `diagrams/rendered/*.png`, `screenshots/demo-architecture*.png`, `screenshots/diagram-*.png`
   - app screenshots to exclude: landing pages, chat, settings, GitHub, i18n, quiz-result sequences, login/register, Canvas import/settings screens, generic UI screenshots
4. For database/ERD material, do not blindly trust an old screenshot. Compare visible entities against migrations/current schema sources and add a note if the screenshot is stale. In the OghmaNotes case, the old schema screenshot was close but stale: it still showed Postgres `app.embeddings` even after vectors moved to Qdrant, and it missed `app.user_course_settings`.
5. When a native image viewer is requested, try native apps first, but if they fail to display reliably, create a local HTML gallery and open it in the requested browser.

## Remote Hyprland/Helium launch pattern

On Semyon’s laptop, launch GUI apps into the existing user session with explicit environment and the real binary path; user `PATH` may not resolve wrappers under `systemd-run`:

```bash
export XDG_RUNTIME_DIR=/run/user/1000
export WAYLAND_DISPLAY=wayland-1
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
export DISPLAY=:0
systemd-run --user --collect \
  --setenv=XDG_RUNTIME_DIR=/run/user/1000 \
  --setenv=WAYLAND_DISPLAY=wayland-1 \
  --setenv=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
  --setenv=DISPLAY=:0 \
  /opt/helium-browser-bin/helium "file://$GALLERY"
```

Verify with grep/HTML checks rather than relying on “browser opened” alone: count `<figure>` entries, check included/excluded filename patterns, and confirm any generated ERD/table cards contain the expected current tables.
