#include "..\ui\defines.hpp"
/*
 * Author: AV
 * "List selections" button. For the first selected object, dumps the hidden
 * selections you can retexture.
 *
 * For a UNIT it walks the whole loadout - body/uniform, headgear, vest, backpack,
 * goggles and weapons - and lists each item's hidden selections, because every worn
 * item is a SEPARATE model with its own selections (reading the unit alone only sees
 * the body). For any other object it lists that object's own selections + current
 * textures.
 *
 * Reachability note: setObjectTexture on the unit only retextures the UNIFORM/BODY.
 * Worn gear and weapons are config-only (need hiddenSelectionsTextures on a new item
 * class); a backpack can also be scripted via its own object (unitBackpack).
 *
 * Output goes to systemChat AND the clipboard (chat is not reliably visible in Eden).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

if (isNil "ReTex_targets" || {ReTex_targets isEqualTo []}) exitWith {
    systemChat "ReTex: nothing selected.";
};

private _obj    = ReTex_targets select 0;
private _report = [];

if (_obj isKindOf "CAManBase") then {
    _report pushBack format ["Equipment hidden selections for %1:", typeOf _obj];

    // UNIFORM/BODY first, with its current textures (this is what Apply/Bake reach).
    private _bodyNames = getArray (configOf _obj >> "hiddenSelections");
    private _curr      = getObjectTextures _obj;
    if (_bodyNames isEqualTo []) then {
        _report pushBack "UNIFORM/BODY: no hidden selections";
    } else {
        _report pushBack "UNIFORM/BODY  <- Apply/Bake target:";
        {
            private _tex = _curr param [_forEachIndex, ""];
            if (_tex isEqualTo "") then { _tex = "<default>" };
            _report pushBack format ["    [%1] %2  =  %3", _forEachIndex, _x, _tex];
        } forEach _bodyNames;
    };

    // Worn gear + weapons: [label, classname, config root]. Each is config-only.
    private _slots = [
        ["HEADGEAR",  headgear _obj,        configFile >> "CfgWeapons"],
        ["VEST",      vest _obj,            configFile >> "CfgWeapons"],
        ["BACKPACK",  backpack _obj,        configFile >> "CfgVehicles"],
        ["GOGGLES",   goggles _obj,         configFile >> "CfgGlasses"],
        ["PRIMARY",   primaryWeapon _obj,   configFile >> "CfgWeapons"],
        ["LAUNCHER",  secondaryWeapon _obj, configFile >> "CfgWeapons"],
        ["HANDGUN",   handgunWeapon _obj,   configFile >> "CfgWeapons"],
        ["BINOCULAR", binocular _obj,       configFile >> "CfgWeapons"]
    ];

    {
        _x params ["_label", "_cls", "_root"];
        if (_cls isEqualTo "") then { continue };   // nothing in that slot

        private _names = getArray (_root >> _cls >> "hiddenSelections");
        if (_names isEqualTo []) then {
            _report pushBack format ["%1: %2  -  no hidden selections", _label, _cls];
        } else {
            _report pushBack format ["%1: %2  (config-only):", _label, _cls];
            { _report pushBack format ["    [%1] %2", _forEachIndex, _x]; } forEach _names;
        };
    } forEach _slots;

    _report pushBack "Note: Apply/Bake retexture the UNIFORM/BODY only. Worn gear/weapons";
    _report pushBack "need hiddenSelectionsTextures on a new item class (backpacks can also be";
    _report pushBack "scripted via their own object).";
} else {
    // Non-unit object (vehicle, crate, prop): list its own selections + current textures.
    private _names = getArray (configOf _obj >> "hiddenSelections");
    if (_names isEqualTo []) then {
        _report pushBack format ["%1: no hidden selections - its pieces cannot be retextured by index.", typeOf _obj];
    } else {
        private _curr = getObjectTextures _obj;
        _report pushBack format ["%1  -  %2 hidden selection(s):", typeOf _obj, count _names];
        {
            private _tex = _curr param [_forEachIndex, ""];
            if (_tex isEqualTo "") then { _tex = "<default>" };
            _report pushBack format ["    [%1] %2  =  %3", _forEachIndex, _x, _tex];
        } forEach _names;
    };
};

{ systemChat _x } forEach _report;
copyToClipboard (_report joinString endl);
systemChat "ReTex: selection list copied to clipboard.";
