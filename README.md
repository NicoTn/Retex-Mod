# ReTex — Live Retexture (Eden Editor)

A lightweight **Arma 3 Eden editor tool** for retexturing on the fly. Select objects
in Eden, open **Tools → Live Retexture** (or press **Ctrl+Shift+R**), and apply a
`.paa` to one of an object's hidden selections — the change previews live in the
viewport. Bake it into the object's init to keep it, or copy a ready-made config
snippet.

Built for iterating on retextures (uniforms, vehicles, helmets, crates, props)
**without packing a PBO or restarting the game**.

**Requires [CBA_A3](https://steamcommunity.com/workshop/filedetails/?id=450814997).**

## Features

- **Apply (preview)** — live `setObjectTexture` on every selected object.
- **Reset** — revert the preview to the originals.
- **Bake to init** — write `setObjectTextureGlobal` into the object init so it
  persists with the scenario and for JIP. Warns on absolute/loose disk paths that
  won't exist for other players in multiplayer.
- **Copy config** — clipboard a `setObjectTextureGlobal` line and a
  `hiddenSelectionsTextures[]` snippet for pasting into a mission or addon.
- **List selections** — dump a model's hidden selections as `index → name` so you
  know which index and pbo drives which piece.
- **Live Link (Photoshop/GIMP)** — save in your image editor and the object
  retextures in Eden automatically, no retyping or repacking. A companion
  extension (`retexlink_x64.dll`) watches your export file and rotates it to a
  unique name each save to defeat the engine's texture cache. JPG/PNG load
  directly (no PAA step while iterating).


## Current limitations
- Can only have a single unit/object in eden currently.

## Install / Usage
- Install the workshop mod: https://steamcommunity.com/sharedfiles/filedetails/?id=3755594142
- Copy `retexlink_x64.dll` into the folder containing **`arma3_x64.exe`**
- Launch Arma 3 with the `-filePatching` command line!

## Using Live Link

Save in Photoshop/GIMP and watch the object update in Eden — no retyping paths or
repacking. One-time setup, then a zero-click iteration loop.

**One-time setup**
1. Make sure `retexlink_x64.dll` is next to `arma3_x64.exe` (see Install above).
2. Point your editor at a single export file it overwrites on every save:
   - **Photoshop:** *File → Generate → Image Assets*, then name a layer e.g.
     `skin.jpg` — it re-exports on every save. (Or record a one-key export action.)
   - **GIMP:** *File → Export As…* once to `skin.jpg`, then use *File → Overwrite
     skin.jpg* on each save afterward.

**Each session**
1. Select the object in Eden and open ReTex (**Ctrl+Shift+R**).
2. Pick the **Target part** and **Selection index** as usual.
3. Paste the full path of your editor's export file into the **Live Link — editor
   export file** field (e.g. `D:\art\skin.jpg`).
4. Click **Live Link: OFF** → it flips to **ON** and starts watching.
5. Tab to your editor, paint, and **save** — the object retextures within a
   fraction of a second. Repeat as much as you like.
6. Click **Live Link: ON** again to stop. **Reset** still restores the originals,
   and the link keeps running even if you close the dialog so you can keep iterating.

JPG/PNG load directly, so there's **no PAA step** while iterating — only convert to
`.paa` for the final shipped asset. Behind the scenes each save is copied to a unique
`retex_live\tex_<N>.<ext>` name to beat the engine's path-keyed texture cache.
