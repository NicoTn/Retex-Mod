#include "ui\defines.hpp"

class CfgPatches {
    class ReTex_main {
        name = "ReTex - Live Retexture (Eden)";
        author = "AV";
        url = "";
        requiredVersion = 2.0;
        // Eden-editor tool: needs the 3DEN editor addon. CBA only for convenience.
        requiredAddons[] = {"3DEN", "cba_main"};
        units[] = {};
        weapons[] = {};
        version = "1.0.0";
    };
};

class CfgFunctions {
    class ReTex {
        tag = "ReTex";
        class retex {
            file = "\z\retex\addons\retex\functions";
            class retexOpen {};     // Tools-menu action: open the dialog (Eden)
            class onRetexLoad {};   // dialog onLoad: capture selection + label
            class retexApply {};    // local: setObjectTexture preview on selection
            class retexReset {};    // local: restore stored original textures
            class retexBake {};     // Eden: write setObjectTextureGlobal into init
            class retexCopy {};     // local: copy a config snippet to clipboard
            class retexList {};     // local: list the model's hidden selections
            class edenKey {};       // display3DEN KeyDown handler (hotkey)
            class retexPartSel {};  // enable/disable Apply+Spawn per selected part
            class retexSpawnProxy {};// spawn a standalone proxy for a config-only part
            class retexUnload {};   // dialog onUnload: save fields + delete proxies
            class retexLink {};     // toggle Live Link (watch editor export via retexlink ext)
            class retexBakePaa {};  // bake current source image -> .paa via ImageToPAA
        };
    };
};

// Install a KeyDown handler on the Eden editor display when it loads, so Ctrl+Shift+R
// opens the tool. Uses CBA's Extended Display EHs (cba_main is a required addon).
// CBA keybinds are NOT used: they fire on the mission display, not in 3DEN.
class Extended_DisplayLoad_EventHandlers {
    class display3DEN {
        ReTex_hotkey = "(_this select 0) displayAddEventHandler ['KeyDown', {_this call ReTex_fnc_edenKey}];";
    };
};

// --- Eden menu bar extension: add "Live Retexture" under the Tools menu ---
class ctrlMenuStrip;
class display3DEN {
    class Controls {
        class MenuStrip: ctrlMenuStrip {
            class Items {
                class Tools {
                    items[] += {"ReTex_MenuItem"};
                };
                class ReTex_MenuItem {
                    text = "Live Retexture (Ctrl+Shift+R)";
                    action = "call ReTex_fnc_retexOpen";
                };
            };
        };
    };
};

// Engine UI base classes - forward declarations for the dialog below.
// (Kept here, not in defines.hpp, because defines.hpp is also #included by SQF.)
class RscText;
class RscButton;
class RscEdit;
class RscStructuredText;
class RscCombo;

#include "ui\RscDisplayRetex.hpp"
