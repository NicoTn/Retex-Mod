#include "..\ui\defines.hpp"
/*
 * Author: AV
 * "Apply (preview)" button. Previews the index + texture path on the currently
 * selected Target part (Body, Backpack, or a non-unit object). Worn gear / weapons
 * are config-only and cannot be previewed live - those rows disable Apply, and this
 * also refuses them defensively. The original texture per index is cached so Reset
 * can restore it; touched objects are tracked in ReTex_touched.
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
    systemChat "ReTex: nothing selected. Pick objects in Eden, then reopen.";
};

private _sel = lbCurSel (_d displayCtrl IDC_RETEX_PART);
if (_sel < 0) then { _sel = 0 };
(ReTex_parts select _sel) params ["_label", "_objs", "_prev"];

if (!_prev || {_objs isEqualTo []}) exitWith {
    systemChat format ["ReTex: '%1' can't be previewed live - worn gear & weapons are config-only.", _label];
    systemChat "  Use List selections + a hiddenSelectionsTextures config entry for those.";
};

private _idx  = parseNumber (ctrlText (_d displayCtrl IDC_RETEX_INDEX));
private _path = ctrlText (_d displayCtrl IDC_RETEX_PATH);

if (_idx < 0) exitWith { systemChat "ReTex: selection index must be >= 0."; };

if (isNil "ReTex_touched") then { ReTex_touched = []; };

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

systemChat format ["ReTex: previewed %1 selection %2 on %3 object(s).", _label, _idx, count _objs];
