#include "..\ui\defines.hpp"
/*
 * Author: AV
 * "Live Link" toggle. Watches the file your image editor (Photoshop/GIMP) exports
 * to, via the `retexlink` callExtension, and re-applies it to the current target +
 * index every time you save - a live retexture loop with no retyping or repacking.
 *
 * The extension rotates the export file to a unique name on each change (tex_<N>.<ext>
 * in a `retex_live` subfolder) because Arma caches textures by path: re-applying the
 * SAME path shows the stale cached copy, but a never-before-seen path forces a fresh
 * disk read. This function just polls the extension for the newest name and applies it
 * with the same original-caching used by fn_retexApply, so Reset still restores.
 *
 * Arguments:
 * None (reads the dialog controls)
 *
 * Return Value:
 * None
 */

disableSerialization;
private _d = findDisplay IDD_RETEX;

// --- If a link is already running, this click stops it. -----------------------
// The polling loop is a scheduled `spawn` (uiSleep), NOT a CBA per-frame handler:
// CBA's frame driver does not tick inside the 3DEN editor, but the SQF scheduler
// does, so a spawn loop is what actually runs here.
if (!isNil "ReTex_linkActive" && {ReTex_linkActive}) exitWith {
    ReTex_linkActive = false;   // the loop checks this and exits within ~0.25s
    "retexlink" callExtension ["stop", []];
    if (!isNull _d) then { (_d displayCtrl IDC_RETEX_LINKBTN) ctrlSetText "Live Link: OFF"; };
    systemChat "ReTex: Live Link stopped.";
};

if (isNull _d) exitWith {};

// --- Capture the current previewable target + index (mirrors fn_retexApply). ---
if (isNil "ReTex_parts" || {ReTex_parts isEqualTo []}) exitWith {
    systemChat "ReTex: nothing selected. Pick objects in Eden, then reopen.";
};

private _sel = lbCurSel (_d displayCtrl IDC_RETEX_PART);
if (_sel < 0) then { _sel = 0 };
(ReTex_parts select _sel) params ["_label", "_objs", "_prev"];

if (!_prev || {_objs isEqualTo []}) exitWith {
    systemChat format ["ReTex: '%1' can't be live-linked - previewable parts only (Body/Backpack/objects).", _label];
};

private _idx = parseNumber (ctrlText (_d displayCtrl IDC_RETEX_INDEX));
if (_idx < 0) exitWith { systemChat "ReTex: selection index must be >= 0."; };

private _export = ctrlText (_d displayCtrl IDC_RETEX_LINK);
if (_export == "") exitWith {
    systemChat "ReTex: set the Live Link export file first (the .jpg your editor saves to).";
};

// setObjectTexture only loads .paa/.pac/.jpg/.jpeg - a .png rotates fine but the
// engine refuses it with "Cannot load texture", so reject it up front.
private _parts = _export splitString ".";
private _ext = toLower (_parts param [count _parts - 1, ""]);
if (count _parts < 2 || {!(_ext in ["jpg", "jpeg", "paa", "pac"])}) exitWith {
    systemChat format ["ReTex: '.%1' is not a texture format Arma can load. Use .jpg for Live Link.", _ext];
    systemChat "  (Supported: .jpg .jpeg .paa .pac - PNG is NOT supported by setObjectTexture.)";
};

if (isNil "ReTex_debug") then { ReTex_debug = false; };

// --- Is the extension DLL actually loaded? ------------------------------------
private _ping = "retexlink" callExtension ["ping", []];
private _pingStr = if (_ping isEqualType []) then { _ping param [0, ""] } else { _ping };
diag_log format ["[ReTex] ping raw=%1", _ping];
if (_pingStr == "") exitWith {
    systemChat "ReTex: retexlink extension NOT loaded. Enable the mod and RESTART Arma.";
    systemChat "  (Also check -filePatching is on and the DLL isn't blocked: right-click > Properties > Unblock.)";
};
if (ReTex_debug) then { systemChat format ["ReTex: extension loaded (%1).", _pingStr]; };

// --- Ask the extension to start watching the export file. ---------------------
private _res = "retexlink" callExtension ["watch", [_export]];
private _msg = if (_res isEqualType []) then { _res param [0, ""] } else { "" };
diag_log format ["[ReTex] watch(%1) raw=%2", _export, _res];
if (_msg != "ok") exitWith {
    private _why = if (_msg == "") then { "extension returned nothing" } else { _msg };
    systemChat format ["ReTex: Live Link failed to start - %1", _why];
};

// Show what the extension thinks it's watching - reveals path/typo mismatches.
if (ReTex_debug) then {
    private _diag = "retexlink" callExtension ["diag", []];
    systemChat format ["ReTex diag: %1", (if (_diag isEqualType []) then { _diag param [0, ""] } else { _diag })];
};

if (isNil "ReTex_touched") then { ReTex_touched = []; };
ReTex_linkActive = true;

// --- Poll the extension ~4x/sec in a scheduled loop; apply on a new path. ------
[_objs, _idx] spawn {
    params ["_objs", "_idx"];
    private _last = "";
    private _tick = 0;

    while {ReTex_linkActive} do {
        private _poll = "retexlink" callExtension ["poll", []];
        private _path = if (_poll isEqualType []) then { _poll param [0, ""] } else { "" };

        // Heartbeat every ~2s so you can watch the counter climb each time you save.
        // If 'counter' never increases when you save, the watcher isn't seeing the
        // file change - check the diag path matches your editor's export exactly.
        _tick = _tick + 1;
        if (ReTex_debug && {_tick % 8 == 0}) then {
            private _dg = "retexlink" callExtension ["diag", []];
            systemChat format ["ReTex Live [hb]: %1", (if (_dg isEqualType []) then { _dg param [0, ""] } else { _dg })];
        };

        if (_path != "" && {_path != _last}) then {
            _last = _path;
            {
                private _obj = _x;
                if (!isNull _obj) then {
                    private _orig = _obj getVariable ["ReTex_orig", createHashMap];
                    if (!(_idx in keys _orig)) then {
                        _orig set [_idx, (getObjectTextures _obj) param [_idx, ""]];
                        _obj setVariable ["ReTex_orig", _orig];
                    };
                    _obj setObjectTexture [_idx, _path];
                    ReTex_touched pushBackUnique _obj;
                };
            } forEach _objs;
            diag_log format ["[ReTex] applied idx %1 -> %2 on %3 obj", _idx, _path, count _objs];
            if (ReTex_debug) then { systemChat format ["ReTex Live: applied %1", _path]; };
        };

        uiSleep 0.25;
    };
    if (ReTex_debug) then { systemChat "ReTex: Live Link loop ended."; };
};

(_d displayCtrl IDC_RETEX_LINKBTN) ctrlSetText "Live Link: ON";
systemChat format ["ReTex: Live Link watching '%1' (%2 obj, index %3). Save from your editor to update.", _export, count _objs, _idx];
