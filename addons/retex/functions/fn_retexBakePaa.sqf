#include "..\ui\defines.hpp"
/*
 * Author: AV
 * "Bake to .paa" button. Converts the current source image (the Live Link export file
 * if set, else the Texture path field) to an engine-native .paa via BI's ImageToPAA,
 * driven by the `retexlink` extension. Use JPG/PNG for fast live iteration, then bake
 * the final asset to .paa (alpha + engine-native quality). Output path is copied to the
 * clipboard so you can drop it into a hiddenSelectionsTextures[] / Bake to init.
 *
 * Requires Arma 3 Tools installed (ImageToPAA.exe). Source must be power-of-2 sized.
 *
 * Arguments:
 * None (reads the dialog controls)
 *
 * Return Value:
 * None
 */

disableSerialization;
private _d = findDisplay IDD_RETEX;
if (isNull _d) exitWith {};

// Prefer the Live Link export file; fall back to the manual Texture path field.
private _src = ctrlText (_d displayCtrl IDC_RETEX_LINK);
if (_src == "") then { _src = ctrlText (_d displayCtrl IDC_RETEX_PATH); };
if (_src == "") exitWith {
    systemChat "ReTex: nothing to bake - set the Live Link export file or the Texture path.";
};

systemChat format ["ReTex: baking '%1' to .paa ...", _src];

private _res = "retexlink" callExtension ["bake", [_src]];
private _out = if (_res isEqualType []) then { _res param [0, ""] } else { "" };

if (_out == "" || {_out select [0, 6] == "ERROR:"}) exitWith {
    private _why = if (_out == "") then { "retexlink extension not found (retexlink_x64.dll missing?)" } else { _out };
    systemChat format ["ReTex: bake failed - %1", _why];
};

copyToClipboard _out;
systemChat format ["ReTex: baked -> %1  (path copied to clipboard)", _out];
