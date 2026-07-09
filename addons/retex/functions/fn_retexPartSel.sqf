#include "..\ui\defines.hpp"
/*
 * Author: AV
 * Combo selection handler. Enables Apply for a previewable part, or Spawn proxy for a
 * config-only part (worn gear / weapon), so the buttons reflect what the selected
 * Target part actually supports.
 *
 * Arguments:
 * 0: _display <DISPLAY>
 * 1: _sel     <NUMBER> - selected combo row
 *
 * Return Value:
 * None
 */

params ["_display", "_sel"];

if (_sel < 0 || {isNil "ReTex_parts"} || {_sel >= count ReTex_parts}) exitWith {};

private _prev = (ReTex_parts select _sel) select 2;
(_display displayCtrl IDC_RETEX_APPLY) ctrlEnable _prev;
(_display displayCtrl IDC_RETEX_SPAWN) ctrlEnable (!_prev);
