#include "..\ui\defines.hpp"
/*
 * Author: AV
 * "Bake to init" button (Eden). Appends a setObjectTextureGlobal call to the selected
 * Target part's init via set3DENAttribute, so the retexture persists with the
 * scenario. Only editor-placed entities have an init, so this is valid for the
 * Body/Uniform row and non-unit objects; a backpack or config-only gear cannot be
 * baked (warns instead).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

disableSerialization;
private _d = findDisplay IDD_RETEX;
if (isNull _d) exitWith {};

if (isNil "ReTex_parts" || {ReTex_parts isEqualTo []}) exitWith {
    systemChat "ReTex: nothing selected.";
};

private _sel = lbCurSel (_d displayCtrl IDC_RETEX_PART);
if (_sel < 0) then { _sel = 0 };
(ReTex_parts select _sel) params ["_label", "_objs", "_prev"];

// Bake writes an editor object's init - only valid for editor-placed entities.
private _bakeable = (_objs isNotEqualTo []) && {(_objs select { !(_x in ReTex_targets) }) isEqualTo []};
if (!_bakeable) exitWith {
    systemChat format ["ReTex: can't bake '%1' - bake only writes an editor object's init.", _label];
    systemChat "  Worn gear / backpack / weapons need a config hiddenSelectionsTextures entry instead.";
};

private _idx  = parseNumber (ctrlText (_d displayCtrl IDC_RETEX_INDEX));
private _path = ctrlText (_d displayCtrl IDC_RETEX_PATH);

if (_idx < 0) exitWith { systemChat "ReTex: selection index must be >= 0."; };

// Guardrail: an absolute disk path (contains a drive colon, e.g. Z:\...) or a bare
// loose path only resolves on THIS machine. Baking it ships a texture every other
// player is missing in MP. Warn but still bake - sometimes that's fine for testing.
if (_path find ":" >= 0) then {
    systemChat "ReTex: WARNING - absolute disk path. It will be MISSING for other players in MP.";
    systemChat "  Pack the .paa into the mission or a mod and bake a virtual path (\... or mission-relative).";
};

private _add = format ["this setObjectTextureGlobal [%1, '%2'];", _idx, _path];

{
    private _obj = _x;
    if (!isNull _obj) then {
        private _init = (_obj get3DENAttribute "init") param [0, ""];
        private _new  = if (_init isEqualTo "") then { _add } else { _init + " " + _add };
        _obj set3DENAttribute ["init", _new];
    };
} forEach _objs;

systemChat format ["ReTex: baked selection %1 into init on %2 object(s).", _idx, count _objs];
