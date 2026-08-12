# React Native Android Markdown table update-loop mitigation

## Trigger

An Android React Native red screen reports `Maximum update depth exceeded` with `TableRenderer` and `NodeRenderer` near the top of the JavaScript stack while rendering GFM Markdown.

## Diagnosis

1. Treat `TableRenderer` as the likely content-specific renderer, not a T3 connection/backend/pairing failure.
2. Inspect the exact mobile rendering branch. In T3 Code, iOS uses the custom native selectable renderer, but Android falls back to `react-native-nitro-markdown`'s `Markdown` component. The platform divergence matters.
3. Confirm every Android Markdown surface: assistant/user thread messages, segmented review messages, and file Markdown previews.
4. Inspect the resolved package version and its table implementation before doing a broad dependency upgrade. A package upgrade may retain the same measurement/state architecture and introduce native compatibility churn.

## Safe mitigation

Keep GFM enabled, but transform pipe-table blocks *only on Android* before they reach the renderer. Lower each table into readable standard Markdown, such as a bold joined header plus bullet rows. This avoids constructing `table` AST nodes and therefore avoids `TableRenderer`, while preserving the table's information.

Use a small pure helper with focused fixtures for:

- normal pipe tables (including alignment separators),
- multiple rows,
- ordinary Markdown or prose containing `|`, which must remain unchanged.

Apply the helper to every fallback `<Markdown>` input, not the iOS native path. Document the intentional trade-off: compact list presentation is preferable to a crash until the underlying renderer is proven stable on the target Android runtime.

## Verification

1. Run the focused helper test.
2. Run the repo's formatting/check, mobile typecheck, and mobile native-static check.
3. Build a real Android release APK from the patched working tree. Verify the APK signature and inspect the bundled JavaScript for the mitigation helper, so a successful Gradle build is not mistaken for proof that the changed source was bundled.
4. If no Android device/ADB is available, explicitly distinguish artifact verification from physical-device smoke testing.
5. Do not overwrite a public APK mirror, commit, or push without explicit authorization.
