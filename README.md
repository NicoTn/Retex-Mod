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

## Install / build
Copy `retexlink_x64.dll` into the folder containing **`arma3_x64.exe`** (same place
other extensions load from).

Launch Arma 3 with the `-filePatching` command line! 
