#include "..\ui\defines.hpp"
/*
 * Author: AV
 * Tools-menu action (Eden). Opens the Live Retexture dialog, which then operates on
 * whatever objects are currently selected in the editor.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

if (!is3DEN) exitWith {
    systemChat "ReTex: open this from the Eden editor (Tools menu).";
};

createDialog "ReTex_Dialog";
