// ReTex - shared UI defines (control types, IDC/IDD, positioning macros).
// Included by BOTH config.cpp AND the .sqf functions, so it must contain ONLY
// preprocessor macros - no `class` declarations. Engine UI base classes are
// forward-declared in config.cpp instead.
//
// IDC/IDD live in a mod-unique range to avoid clashing with other dialogs.

// --- Control type constants ---
#define CT_STATIC   0
#define CT_BUTTON   1
#define CT_EDIT     2
#define CT_COMBO    4

#define ST_LEFT     0
#define ST_CENTER   2

// --- Display / control IDs ---
#define IDD_RETEX             91300
#define IDC_RETEX_TITLE       91301
#define IDC_RETEX_TARGET      91302
#define IDC_RETEX_INDEX_LBL   91303
#define IDC_RETEX_INDEX       91304
#define IDC_RETEX_PATH_LBL    91305
#define IDC_RETEX_PATH        91306
#define IDC_RETEX_HINT        91307
#define IDC_RETEX_APPLY       91308
#define IDC_RETEX_RESET       91309
#define IDC_RETEX_BAKE        91310
#define IDC_RETEX_COPY        91311
#define IDC_RETEX_CLOSE       91312
#define IDC_RETEX_LIST        91313
#define IDC_RETEX_PART_LBL    91314
#define IDC_RETEX_PART        91315
#define IDC_RETEX_SPAWN       91316
// --- Live Link (Photoshop/GIMP) ---
#define IDC_RETEX_LINK_LBL    91317
#define IDC_RETEX_LINK        91318   // export file the image editor saves to
#define IDC_RETEX_LINKBTN     91319   // Live Link toggle
#define IDC_RETEX_DEBUG       91320   // debug-message toggle (off by default)

// --- Positioning helpers: arguments are fractions (0..1) of the safe zone ---
#define PX(N) (safezoneX + safezoneW * (N))
#define PY(N) (safezoneY + safezoneH * (N))
#define PW(N) (safezoneW * (N))
#define PH(N) (safezoneH * (N))
