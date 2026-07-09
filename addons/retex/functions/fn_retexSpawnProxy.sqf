#include "..\ui\defines.hpp"
/*
 * Author: AV
 * "Spawn as object" button. Worn gear / weapons can't be retextured on the unit, so
 * this spawns a real, SELECTABLE Eden object you can preview on. It must be a
 * config-backed object (createSimpleObject from a bare model path has no config, so
 * setObjectTexture can't map a hidden selection onto it) - so we resolve a CfgVehicles
 * class and use create3DENEntity:
 *   - weapons -> the Weapon_<class> proxy,
 *   - any item that is itself a CfgVehicles class (e.g. a backpack) -> that class.
 * Headgear / vests / goggles are CfgWeapons/CfgGlasses items with NO placeable object;
 * those can only be retextured via config (Copy config).
 *
 * The spawned object is a normal editor entity: selectable, and added to the Target
 * part list so Apply works on it immediately. It persists (it's a real object) - delete
 * it in Eden when done.
 *
 * Status is written to the dialog's hint line (systemChat is unreliable in Eden).
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

private _say = {
    params ["_msg"];
    (findDisplay IDD_RETEX displayCtrl IDC_RETEX_HINT) ctrlSetStructuredText parseText _msg;
    diag_log text ("ReTex: " + _msg);
    systemChat ("ReTex: " + _msg);
};

if (isNil "ReTex_parts" || {ReTex_parts isEqualTo []}) exitWith {};

private _sel = lbCurSel (_d displayCtrl IDC_RETEX_PART);
if (_sel < 0) exitWith {};
(ReTex_parts select _sel) params ["_label", "_objs", "_prev", "_cls", "_cfg"];

if (_prev) exitWith { ["That part is already previewable - just use Apply."] call _say; };

// Resolve a placeable CfgVehicles class - only these spawn AND can be retextured.
// Worn items have an Item_<class> ground holder; weapons a Weapon_<class> proxy;
// backpacks (and other CfgVehicles) are placeable under their own class.
private _vehClass = "";
{
    if (isClass (configFile >> "CfgVehicles" >> _x)) exitWith { _vehClass = _x; };
} forEach [("Item_" + _cls), ("Weapon_" + _cls), _cls];

if (_vehClass isEqualTo "") exitWith {
    [format ["%1 has no placeable object - it can't be previewed live. Use Copy config to retexture it via a config entry.", _cls]] call _say;
};

private _anchor = ReTex_targets select 0;
if (isNil "ReTex_proxies") then { ReTex_proxies = []; };
private _k = count ReTex_proxies;
private _p = _anchor getRelPos [1.5 + _k * 0.7, (getDir _anchor) + 90];

private _obj = create3DENEntity ["Object", _vehClass, _p];
if (isNull _obj) exitWith { [format ["Failed to spawn %1.", _vehClass]] call _say; };
_obj setPosATL [_p select 0, _p select 1, 0];
ReTex_proxies pushBack _obj;

// Add as a previewable part and select it (it is also a normal selectable Eden object).
private _lbl   = format ["Spawned: %1", _vehClass];
ReTex_parts pushBack [_lbl, [_obj], true, _vehClass, configNull];
private _combo = _d displayCtrl IDC_RETEX_PART;
private _row   = _combo lbAdd _lbl;
_combo lbSetCurSel _row;
[_d, _row] call ReTex_fnc_retexPartSel;

[format ["Spawned selectable object: %1.<br/>Set index/path and Apply (or select it in Eden).", _vehClass]] call _say;
