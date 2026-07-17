#include "..\ui\defines.hpp"
/*
 * Author: AV
 * "Debug" button. Toggles ReTex_debug, which gates the verbose Live Link chatter
 * (extension ping/diag, the poll heartbeat, per-apply messages). Off by default so
 * normal use stays quiet; turn it on when a link isn't behaving and you need to see
 * whether the watcher is picking up your saves.
 *
 * Errors and state changes are NOT gated by this - they always print.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

disableSerialization;

ReTex_debug = isNil "ReTex_debug" || {!ReTex_debug};

private _d = findDisplay IDD_RETEX;
if (!isNull _d) then {
    (_d displayCtrl IDC_RETEX_DEBUG) ctrlSetText (["Debug: OFF", "Debug: ON"] select ReTex_debug);
};

if (ReTex_debug) then {
    systemChat "ReTex: debug messages ON (extension diag + Live Link heartbeat).";
    // Dump extension state right away - the usual reason for switching this on.
    private _dg = "retexlink" callExtension ["diag", []];
    systemChat format ["ReTex diag: %1", (if (_dg isEqualType []) then { _dg param [0, ""] } else { _dg })];
} else {
    systemChat "ReTex: debug messages OFF.";
};
