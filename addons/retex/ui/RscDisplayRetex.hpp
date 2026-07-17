// ReTex - "Live Retexture" dialog (Eden editor). Acts on the objects that are
// selected in Eden when the dialog opens: apply a texture to a hidden selection
// live, bake it into the object init, or copy a config snippet.

class ReTex_Dialog {
    idd = IDD_RETEX;
    movingEnable = 1;
    enableSimulation = 1;
    onLoad = "[_this select 0] call ReTex_fnc_onRetexLoad";
    // Save index/path (restored in onLoad) and delete any spawned preview proxies.
    onUnload = "(_this select 0) call ReTex_fnc_retexUnload";

    class controlsBackground {
        class Background: RscText {
            idc = -1;
            x = PX(0.35); y = PY(0.30);
            w = PW(0.30); h = PH(0.68);
            colorBackground[] = {0, 0, 0, 0.75};
        };
        class Title: RscText {
            idc = IDC_RETEX_TITLE;
            text = "Live Retexture";
            moving = 1;
            x = PX(0.35); y = PY(0.30);
            w = PW(0.30); h = PH(0.04);
            colorBackground[] = {0.10, 0.30, 0.45, 0.9};
            style = ST_CENTER;
        };
    };

    class controls {
        // What the dialog will act on (Eden selection captured at open).
        class TargetLbl: RscText {
            idc = IDC_RETEX_TARGET;
            text = "Selected: none";
            x = PX(0.36); y = PY(0.345);
            w = PW(0.28); h = PH(0.035);
            style = ST_LEFT;
        };

        // Target part: which previewable part of the selection to paint. Worn gear /
        // weapons are listed but config-only - selecting one disables Apply.
        class PartLbl: RscText {
            idc = IDC_RETEX_PART_LBL;
            text = "Target part (preview)";
            x = PX(0.36); y = PY(0.383);
            w = PW(0.28); h = PH(0.030);
            style = ST_LEFT;
        };
        class PartCombo: RscCombo {
            idc = IDC_RETEX_PART;
            x = PX(0.36); y = PY(0.413);
            w = PW(0.28); h = PH(0.035);
            // Enable Apply for previewable parts, Spawn proxy for config-only parts.
            onLBSelChanged = "[ctrlParent (_this select 0), _this select 1] call ReTex_fnc_retexPartSel";
        };

        // Hidden-selection index.
        class IndexLbl: RscText {
            idc = IDC_RETEX_INDEX_LBL;
            text = "Selection index";
            x = PX(0.36); y = PY(0.458);
            w = PW(0.18); h = PH(0.035);
            style = ST_LEFT;
        };
        class IndexEdit: RscEdit {
            idc = IDC_RETEX_INDEX;
            text = "0";
            x = PX(0.54); y = PY(0.458);
            w = PW(0.10); h = PH(0.035);
            colorBackground[] = {0, 0, 0, 0.6};
        };

        // Texture path.
        class PathLbl: RscText {
            idc = IDC_RETEX_PATH_LBL;
            text = "Texture path (.paa)";
            x = PX(0.36); y = PY(0.498);
            w = PW(0.28); h = PH(0.030);
            style = ST_LEFT;
        };
        class PathEdit: RscEdit {
            idc = IDC_RETEX_PATH;
            text = "";
            x = PX(0.36); y = PY(0.530);
            w = PW(0.28); h = PH(0.040);
            colorBackground[] = {0, 0, 0, 0.6};
        };

        // Workflow hint - structured text so it wraps to multiple lines.
        class Hint: RscStructuredText {
            idc = IDC_RETEX_HINT;
            text = "Apply = live preview (Body/Backpack/objects). For worn gear/weapons, click Spawn as object (it spawns the item's holder), then Apply. Iterate with -filePatching + a bumped filename.";
            x = PX(0.36); y = PY(0.570);
            w = PW(0.28); h = PH(0.085);
            class Attributes {
                align = "left";
                color = "#b3b3b3";
            };
        };

        // Apply / Reset (live preview only).
        class ApplyBtn: RscButton {
            idc = IDC_RETEX_APPLY;
            text = "Apply (preview)";
            x = PX(0.360); y = PY(0.665);
            w = PW(0.135); h = PH(0.040);
            onButtonClick = "call ReTex_fnc_retexApply";
        };
        class ResetBtn: RscButton {
            idc = IDC_RETEX_RESET;
            text = "Reset";
            x = PX(0.505); y = PY(0.665);
            w = PW(0.135); h = PH(0.040);
            onButtonClick = "call ReTex_fnc_retexReset";
        };

        // Bake into init (persists) / Copy snippet.
        class BakeBtn: RscButton {
            idc = IDC_RETEX_BAKE;
            text = "Bake to init";
            x = PX(0.360); y = PY(0.710);
            w = PW(0.135); h = PH(0.040);
            onButtonClick = "call ReTex_fnc_retexBake";
        };
        class CopyBtn: RscButton {
            idc = IDC_RETEX_COPY;
            text = "Copy config";
            x = PX(0.505); y = PY(0.710);
            w = PW(0.135); h = PH(0.040);
            onButtonClick = "call ReTex_fnc_retexCopy";
        };

        // List hidden selections (discovery) / Close.
        class ListBtn: RscButton {
            idc = IDC_RETEX_LIST;
            text = "List selections";
            x = PX(0.360); y = PY(0.755);
            w = PW(0.135); h = PH(0.040);
            onButtonClick = "call ReTex_fnc_retexList";
        };
        class CloseBtn: RscButton {
            idc = IDC_RETEX_CLOSE;
            text = "Close";
            x = PX(0.505); y = PY(0.755);
            w = PW(0.135); h = PH(0.040);
            onButtonClick = "closeDialog 0";
        };

        // Spawn a standalone proxy of a config-only part so it CAN be previewed.
        // Enabled only while a config-only part (worn gear / weapon) is selected.
        class SpawnBtn: RscButton {
            idc = IDC_RETEX_SPAWN;
            text = "Spawn as object";
            x = PX(0.360); y = PY(0.800);
            w = PW(0.280); h = PH(0.040);
            onButtonClick = "call ReTex_fnc_retexSpawnProxy";
        };

        // --- Live Link: Photoshop/GIMP --------------------------------------
        // Point this at the file your image editor exports/overwrites on save.
        // The retexlink extension rotates it to a unique name on every change so
        // Arma's path-keyed texture cache is forced to reload live.
        class LinkLbl: RscText {
            idc = IDC_RETEX_LINK_LBL;
            text = "Live Link - editor export file (.jpg)";
            x = PX(0.36); y = PY(0.850);
            w = PW(0.28); h = PH(0.030);
            style = ST_LEFT;
        };
        class LinkEdit: RscEdit {
            idc = IDC_RETEX_LINK;
            text = "";
            x = PX(0.36); y = PY(0.882);
            w = PW(0.28); h = PH(0.040);
            colorBackground[] = {0, 0, 0, 0.6};
        };
        class LinkBtn: RscButton {
            idc = IDC_RETEX_LINKBTN;
            text = "Live Link: OFF";
            x = PX(0.360); y = PY(0.928);
            w = PW(0.185); h = PH(0.040);
            onButtonClick = "call ReTex_fnc_retexLink";
        };
        // Verbose extension/heartbeat/apply chatter - off unless you're diagnosing.
        class DebugBtn: RscButton {
            idc = IDC_RETEX_DEBUG;
            text = "Debug: OFF";
            x = PX(0.550); y = PY(0.928);
            w = PW(0.090); h = PH(0.040);
            onButtonClick = "call ReTex_fnc_retexDebug";
        };
    };
};
