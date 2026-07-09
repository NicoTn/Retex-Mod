#include "..\ui\defines.hpp"
/*
 * Author: AV
 * "Copy config" button. Builds a snippet for the selected Target part's class/index/
 * path in both runtime (setObjectTextureGlobal) and config (hiddenSelectionsTextures)
 * forms and puts it on the clipboard. This is the intended path for worn gear and
 * weapons, which can't be previewed live but CAN be retextured via a config entry.
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
(ReTex_parts select _sel) params ["_label", "_objs", "_prev", "_cls"];

private _idx  = parseNumber (ctrlText (_d displayCtrl IDC_RETEX_INDEX));
private _path = ctrlText (_d displayCtrl IDC_RETEX_PATH);

// NOTE: SQF escapes a double-quote inside a double-quoted string by DOUBLING it
// ("") - a backslash does NOT escape here.
private _snippet = format [
    "// %1, hidden selection %2%4// init-field / script form:%4this setObjectTextureGlobal [%2, ""%3""];%4%4// config form (CfgVehicles):%4hiddenSelectionsTextures[] = { ""%3"" };",
    _cls, _idx, _path, endl
];

copyToClipboard _snippet;
systemChat format ["ReTex: config snippet for %1 copied to clipboard.", _cls];
