#include "..\ui\defines.hpp"
/*
 * Author: AV
 * onLoad for the Live Retexture dialog. Captures the objects selected in Eden, then
 * builds the "Target part" list (ReTex_parts) for the first selected object and fills
 * the combo. Each part row is [label, targetObjects, previewable, classname, itemCfg]:
 *   - a UNIT yields Body/Uniform + Backpack (live-previewable) and its worn gear /
 *     weapons (config-only, not previewable - but a proxy can be spawned for them),
 *   - any other object yields a single previewable row for the selection itself.
 * Apply is enabled for previewable rows; Spawn proxy for config-only rows.
 *
 * Arguments:
 * 0: _display <DISPLAY>
 *
 * Return Value:
 * None
 */

params ["_display"];
disableSerialization;

// Spawned objects (fn_retexSpawnProxy) are real editor entities the user keeps and
// selects, so they are NOT auto-deleted; just track them for placement spacing.
if (isNil "ReTex_proxies") then { ReTex_proxies = []; };

ReTex_targets = (get3DENSelected "object") select { !isNull _x };

private _n = count ReTex_targets;
private _txt = if (_n == 0) then {
    "Selected: none - pick objects in Eden first";
} else {
    format ["Selected: %1 object(s)  [%2]", _n, typeOf (ReTex_targets select 0)];
};
(_display displayCtrl IDC_RETEX_TARGET) ctrlSetText _txt;

// --- Build the Target part list from the first selected object ---
// Each row: [label, targetObjects, previewable, classname, itemConfig]
ReTex_parts = [];
if (_n > 0) then {
    private _first = ReTex_targets select 0;
    if (_first isKindOf "CAManBase") then {
        // Live-previewable parts: the body, and the backpack (a real object).
        ReTex_parts pushBack ["Body / Uniform", [_first], true, typeOf _first, configNull];
        private _bp = unitBackpack _first;
        if (!isNull _bp) then {
            ReTex_parts pushBack [format ["Backpack: %1", typeOf _bp], [_bp], true, typeOf _bp, configNull];
        };
        // Config-only: worn gear + weapons. No live object handle - a proxy can be
        // spawned from each item's config (itemConfig) to preview it.
        {
            _x params ["_lbl", "_cls", "_root"];
            if (_cls != "") then {
                ReTex_parts pushBack [format ["%1: %2  (config-only)", _lbl, _cls], [], false, _cls, (_root >> _cls)];
            };
        } forEach [
            ["Headgear",  headgear _first,        configFile >> "CfgWeapons"],
            ["Vest",      vest _first,            configFile >> "CfgWeapons"],
            ["Goggles",   goggles _first,         configFile >> "CfgGlasses"],
            ["Primary",   primaryWeapon _first,   configFile >> "CfgWeapons"],
            ["Launcher",  secondaryWeapon _first, configFile >> "CfgWeapons"],
            ["Handgun",   handgunWeapon _first,   configFile >> "CfgWeapons"],
            ["Binocular", binocular _first,       configFile >> "CfgWeapons"]
        ];
    } else {
        // Non-unit: act on the whole selection as one previewable target.
        private _lbl = if (_n > 1) then { format ["Selected objects [%1]", _n] } else { typeOf _first };
        ReTex_parts pushBack [_lbl, ReTex_targets, true, typeOf _first, configNull];
    };
};

private _combo = _display displayCtrl IDC_RETEX_PART;
lbClear _combo;
{
    _x params ["_lbl", "", "_prev"];
    private _row = _combo lbAdd _lbl;
    if (!_prev) then { _combo lbSetColor [_row, [1, 0.55, 0.35, 1]]; };  // tint config-only rows
} forEach ReTex_parts;

if (ReTex_parts isEqualTo []) then {
    (_display displayCtrl IDC_RETEX_APPLY) ctrlEnable false;
    (_display displayCtrl IDC_RETEX_SPAWN) ctrlEnable false;
} else {
    _combo lbSetCurSel 0;
    [_display, 0] call ReTex_fnc_retexPartSel;
};

// Restore the last-used index + texture path so they survive closing/reopening the
// dialog. Saved in the dialog's onUnload (see fn_retexUnload).
(_display displayCtrl IDC_RETEX_INDEX) ctrlSetText (if (isNil "ReTex_lastIndex") then { "0" } else { ReTex_lastIndex });
(_display displayCtrl IDC_RETEX_PATH)  ctrlSetText (if (isNil "ReTex_lastPath")  then { "" }  else { ReTex_lastPath });
(_display displayCtrl IDC_RETEX_LINK)  ctrlSetText (if (isNil "ReTex_lastLink")  then { "" }  else { ReTex_lastLink });
// Reflect a Live Link that is still running from a previous open of the dialog.
if (!isNil "ReTex_linkActive" && {ReTex_linkActive}) then {
    (_display displayCtrl IDC_RETEX_LINKBTN) ctrlSetText "Live Link: ON";
};
// Debug chatter is off by default and persists across reopens once switched on.
if (isNil "ReTex_debug") then { ReTex_debug = false; };
(_display displayCtrl IDC_RETEX_DEBUG) ctrlSetText (["Debug: OFF", "Debug: ON"] select ReTex_debug);
