#include "..\ui\defines.hpp"
/*
 * Author: AV
 * onUnload for the Live Retexture dialog. Remembers the index + texture path (restored
 * in onLoad). Objects spawned via "Spawn as object" are real editor entities and are
 * left in place for the user to keep/select.
 *
 * Arguments:
 * 0: _display <DISPLAY>
 *
 * Return Value:
 * None
 */

params ["_display"];
disableSerialization;

ReTex_lastIndex = ctrlText (_display displayCtrl IDC_RETEX_INDEX);
ReTex_lastPath  = ctrlText (_display displayCtrl IDC_RETEX_PATH);
ReTex_lastLink  = ctrlText (_display displayCtrl IDC_RETEX_LINK);
// NOTE: a running Live Link (ReTex_linkPFH) is intentionally left running when the
// dialog closes, so you can tab out to your image editor and keep iterating. Toggle
// it off with the Live Link button (or it stops on mission end).
// Spawned objects (fn_retexSpawnProxy) are real editor entities - left in place so
// the user can select/keep them; delete them in Eden when finished.
