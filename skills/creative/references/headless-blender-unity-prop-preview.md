# Headless Blender prop generation, Unity handoff, and preview rendering

Use when a Unity prototype needs original low-poly Blender props and Semyon asks for proof/preview before the Unity game is built.

## Deliverables

Produce all four, then verify them:

1. A `.blend` source file.
2. Individual FBX exports for Unity.
3. A standalone lit PNG preview (at least 1600px wide).
4. A small source archive containing the blend files, FBXs, and generation/render scripts.

Do not claim that Blender models were made or rendered merely because a Python generation script exists. Run Blender headlessly, inspect the generated files, render a preview, then visually inspect the PNG before sending it.

## Portable headless Blender

A GUI install is unnecessary. Download the official Linux tarball to a user-local directory, then run:

```bash
/path/to/blender -b --python build_props.py --python render_preview.py -noaudio
```

Use EEVEE for quick preview rendering. Preserve the source scripts so the assets are reproducible.

## Unity/Blender axis pitfall

Unity commonly authors dimensions as `X / Y-up / Z`; Blender uses `X / Y / Z-up`. If a generator was drafted with Unity-style coordinates, convert them at the primitive helpers:

```python
# Unity (x, y, z) -> Blender (x, z, y)
location = (loc[0], loc[2], loc[1])
# Unity (x, y-height, z) -> Blender (x, y-depth, z-height)
scale = (size[0], size[2], size[1])
```

For cylinders, Blender depth is already along its native Z axis, so convert only the location. Correct the preview floor, wall, camera, lights, and prop-layout positions to Blender coordinates too. An uncorrected project can export successfully while producing sideways furniture and a misleading render.

## Preview composition baseline

Arrange props as a small studio/room product shot rather than leaving export assemblies overlapping at the origin. Use a dark neutral floor/back wall, a warm key light, cool fill, warm rim, and an elevated camera aimed at the scene centre. The preview should make every major asset recognisable: bed, desk, wardrobe, basket, books, mug, lamp, and plant.

## Verify before delivery

```bash
file renders/preview.png
identify renders/preview.png  # if available
sha256sum renders/preview.png source-package.tar.gz
tar -tzf source-package.tar.gz
```

Send the PNG for immediate review and the source archive for editing/import. State honestly whether there are texture maps and animations; simple Principled colours and static meshes are materials, not texture work or animation.
