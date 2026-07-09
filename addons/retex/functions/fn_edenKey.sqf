#include "..\ui\defines.hpp"
/*
 * Author: AV
 * KeyDown handler installed on the Eden editor display (display3DEN). Opens the Live
 * Retexture tool on Ctrl+Shift+R. Returns true only when it handles the key, so all
 * other editor shortcuts keep working.
 *
 * Installed via Extended_DisplayLoad_EventHandlers in config.cpp.
 *
 * Arguments (KeyDown EH):
 * 0: _display <DISPLAY>
 * 1: _dik     <NUMBER> - DIK key code
 * 2: _shift   <BOOL>
 * 3: _ctrl    <BOOL>
 * 4: _alt     <BOOL>
 *
 * Return Value:
 * <BOOL> - true if the key was handled (suppresses default), false otherwise
 */

params ["_display", "_dik", "_shift", "_ctrl", "_alt"];

// 0x13 = DIK_R. Ctrl+Shift+R -> open the tool.
if (_ctrl && _shift && {_dik == 0x13}) exitWith {
    call ReTex_fnc_retexOpen;
    true
};

false
