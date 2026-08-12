# T3 Code mobile Android UI/icon inspection

Use when Semyon asks what a T3 Code mobile control means, why an icon is missing on Android, or whether Android needs an external font/icon pack.

## Current source shape

Canonical mobile worktree for the Android preview watcher:

- `/home/semyon/t3code-mobile-work/t3code`
- branch usually `android-dev-pr-3514`
- mobile app under `apps/mobile/`

For thread list/sidebar row actions, inspect these files first:

- `apps/mobile/src/features/threads/thread-list-items.tsx`
  - `THREAD_ROW_MENU_ACTIONS` defines long-press/context-menu actions.
  - `ThreadListRow` builds the archive primary swipe action.
- `apps/mobile/src/features/home/thread-swipe-actions.tsx`
  - `ThreadSwipeable` and `ThreadSwipeActions` render the swipe-left action buttons.
  - Archive is the primary blue action; delete is the destructive red/pink action and full-swipe target.
- `apps/mobile/src/components/AppSymbol.tsx`
  - Android icon fallback map from SF Symbol names to Tabler React Native icons.
- `apps/mobile/src/components/AndroidAnchoredMenu.tsx`
  - Android long-press/dropdown menu rendering.
- `apps/mobile/src/components/ControlPill.tsx`
  - Android uses `AndroidAnchoredMenu`; iOS uses native `MenuView`/UIMenu.

## Thread sidebar/list actions verified from source

Each thread row currently has:

- `Archive`
  - action id: `archive`
  - icon name: `archivebox`
  - Android fallback: `IconArchive` from `@tabler/icons-react-native`
  - swipe UI: blue circular button, label `Archive`
- `Delete`
  - action id: `delete`
  - icon name: `trash`
  - Android fallback: `IconTrash` from `@tabler/icons-react-native`
  - swipe UI: `#ff2d55` red/pink circular button, label `Delete`
  - long full-swipe left triggers delete after the threshold

Access patterns:

- Swipe a thread row left to reveal Archive/Delete buttons.
- Long-press a thread row to open the row menu with Archive/Delete.
- These actions are not always-visible sidebar buttons.

## Android icon pitfall

Do **not** assume Nerd Font/System font requirements for T3 Code mobile action icons. The Android path does not render SF Symbols through a user-installed font. `AppSymbol.tsx` maps SF Symbol-style names like `archivebox` and `trash` to Tabler React Native SVG icons, with dependencies such as:

- `@tabler/icons-react-native`
- `react-native-svg`
- `expo-symbols` for non-Android/native symbol surfaces

If labels render but icons do not, investigate React Native SVG / Tabler component rendering, the `AppSymbol.tsx` mapping, missing icon names, or packaging/tree-shaking. If neither labels nor icons render, first check whether the user is trying to find hidden swipe/long-press actions rather than visible buttons.

## Fast inspection commands

From the worktree root:

```bash
git status --short --branch
rg -n "THREAD_ROW_MENU_ACTIONS|primaryAction|archivebox|trash|ThreadSwipeActions|IconArchive|IconTrash" apps/mobile/src
node -e "const p=require('./apps/mobile/package.json'); console.log({tabler:p.dependencies?.['@tabler/icons-react-native'], svg:p.dependencies?.['react-native-svg'], symbols:p.dependencies?.['expo-symbols']})"
```

Report concise source-backed findings: what the actions are, how to reveal them, and whether the icon path uses native/vector icons rather than external fonts.
