#include "..\ui\defines.hpp"
/*
 * Author: AV
 * "Reset" button. Restores every object this tool has previewed (tracked in
 * ReTex_touched) back to the textures cached at first Apply, then clears the tracker.
 * Only affects the live preview - it does NOT remove anything written by Bake to init.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

disableSerialization;

if (isNil "ReTex_touched" || {ReTex_touched isEqualTo []}) exitWith {
    systemChat "ReTex: nothing to reset.";
};

{
    private _obj = _x;
    if (!isNull _obj) then {
        private _orig = _obj getVariable ["ReTex_orig", createHashMap];
        {
            _obj setObjectTexture [_x, _y];   // _x = index, _y = original path
        } forEach _orig;
        _obj setVariable ["ReTex_orig", nil];
    };
} forEach ReTex_touched;

ReTex_touched = [];
systemChat "ReTex: restored previewed textures.";
