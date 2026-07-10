// retexlink - Arma 3 callExtension DLL for ReTex "Live Link".
//
// Watches the image file your editor (Photoshop/GIMP) exports/overwrites on save.
// On every change it copies that file to a UNIQUE name (retex_live\tex_<N>.<ext>)
// so Arma's path-keyed texture cache is forced to reload: re-applying the same path
// shows a stale cached copy, but a never-before-seen path is a guaranteed cache miss
// -> fresh disk read. ReTex_fnc_retexLink polls for the newest name and applies it.
//
// callExtension protocol (v2 args form -> returns [output,retCode,errCode]):
//   "retexlink" callExtension ["watch", ["<exportFilePath>"]]  -> "ok" | "ERROR:..."
//   "retexlink" callExtension ["poll",  []]                     -> "<latest abs path>" | ""
//   "retexlink" callExtension ["stop",  []]                     -> "ok"
//   "retexlink" callExtension ["diag",  []]                     -> "<state dump>"
//
// Build: see build.ps1 (MSVC or MinGW, 64-bit -> retexlink_x64.dll).

#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0600   // CancelIoEx (Vista+)
#endif

#include <windows.h>
#include <shlwapi.h>
#include <string>
#include <mutex>
#include <thread>
#include <atomic>
#include <cctype>
#include <cstdio>

#pragma comment(lib, "Shlwapi.lib")

// ---- shared state -----------------------------------------------------------
static std::mutex             g_mx;          // guards g_latest / g_counter
static std::string            g_latest;      // newest rotated absolute path
static unsigned long          g_counter = 0;
static std::atomic<bool>      g_running{false};
static std::thread            g_thread;
static std::string            g_exportFile;  // watched file (full path)
static std::string            g_watchDir;    // its parent directory
static std::string            g_watchName;   // its file name, lowercased
static std::string            g_liveDir;     // <watchDir>\retex_live
static std::string            g_ext;         // export file extension incl. dot
// Last-seen modification stamp of the export file (poll-based watcher).
static FILETIME               g_lastWrite{};
static DWORD                  g_lastSizeLo = 0, g_lastSizeHi = 0;
static std::string            g_lastError;   // why the last save wasn't picked up (diag)

static std::string lower(std::string s) {
    for (char &c : s) c = (char)std::tolower((unsigned char)c);
    return s;
}

// Arma wraps string args in double-quotes; strip a single surrounding pair.
static std::string unquote(const char *raw) {
    if (!raw) return "";
    std::string s(raw);
    if (s.size() >= 2 && s.front() == '"' && s.back() == '"') s = s.substr(1, s.size() - 2);
    return s;
}

static void writeOut(char *output, int outputSize, const std::string &s) {
    if (!output || outputSize <= 0) return;
    int n = (int)s.size();
    if (n > outputSize - 1) n = outputSize - 1;
    if (n > 0) memcpy(output, s.data(), n);
    output[n] = '\0';
}

// Copy the watched file to retex_live\tex_<N>.<ext> and publish it as newest.
static void rotateNow() {
    unsigned long n;
    { std::lock_guard<std::mutex> lk(g_mx); n = ++g_counter; }

    char dst[MAX_PATH];
    snprintf(dst, sizeof(dst), "%s\\tex_%lu%s", g_liveDir.c_str(), n, g_ext.c_str());

    // The editor may still hold the file briefly after "save"; retry the copy.
    for (int i = 0; i < 20; ++i) {
        if (CopyFileA(g_exportFile.c_str(), dst, FALSE)) {
            std::lock_guard<std::mutex> lk(g_mx);
            g_latest = dst;
            if (n > 5) {   // best-effort: keep only the last few rotations
                char old[MAX_PATH];
                snprintf(old, sizeof(old), "%s\\tex_%lu%s", g_liveDir.c_str(), n - 5, g_ext.c_str());
                DeleteFileA(old);
            }
            return;
        }
        Sleep(50);
    }
}

// Read the export file's last-write time + size. false if the file isn't there.
static bool getStamp(FILETIME &wt, DWORD &lo, DWORD &hi) {
    WIN32_FILE_ATTRIBUTE_DATA fad;
    if (!GetFileAttributesExA(g_exportFile.c_str(), GetFileExInfoStandard, &fad)) return false;
    wt = fad.ftLastWriteTime;
    lo = fad.nFileSizeLow;
    hi = fad.nFileSizeHigh;
    return true;
}

// Poll the export file's modification stamp every 250 ms. This is deliberately
// simple and robust: it catches editors that save atomically (temp file + rename),
// which the directory-change notification API can miss entirely.
static void watchLoop() {
    while (g_running) {
        Sleep(250);
        if (!g_running) break;

        FILETIME wt; DWORD lo, hi;
        if (!getStamp(wt, lo, hi)) {
            g_lastError = "export file not found (yet)";
            continue;
        }
        g_lastError.clear();

        if (CompareFileTime(&wt, &g_lastWrite) != 0 || lo != g_lastSizeLo || hi != g_lastSizeHi) {
            g_lastWrite = wt; g_lastSizeLo = lo; g_lastSizeHi = hi;
            Sleep(150);          // let the editor finish writing before we copy
            rotateNow();
        }
    }
}

static std::string startWatch(const std::string &exportFile) {
    // Tear down any previous watch first.
    if (g_running) {
        g_running = false;
        if (g_thread.joinable()) g_thread.join();
    }

    if (exportFile.empty()) return "ERROR:empty export path";

    g_exportFile = exportFile;

    char dir[MAX_PATH];
    lstrcpynA(dir, exportFile.c_str(), MAX_PATH);
    PathRemoveFileSpecA(dir);
    g_watchDir  = dir;
    g_watchName = lower(PathFindFileNameA(exportFile.c_str()));

    const char *e = PathFindExtensionA(exportFile.c_str());
    g_ext = (e && *e) ? e : ".jpg";

    g_liveDir = g_watchDir + "\\retex_live";
    CreateDirectoryA(g_liveDir.c_str(), NULL);

    { std::lock_guard<std::mutex> lk(g_mx); g_latest.clear(); g_counter = 0; }
    g_lastError.clear();
    g_lastWrite = FILETIME{}; g_lastSizeLo = 0; g_lastSizeHi = 0;

    // Seed one rotation if the export file already exists, so Apply has something
    // to show the instant Live Link is switched on; baseline the stamp off it so we
    // only rotate again on the NEXT save.
    if (GetFileAttributesA(exportFile.c_str()) != INVALID_FILE_ATTRIBUTES) {
        getStamp(g_lastWrite, g_lastSizeLo, g_lastSizeHi);
        rotateNow();
    }

    g_running = true;
    g_thread  = std::thread(watchLoop);
    return "ok";
}

static std::string stopWatch() {
    if (g_running) {
        g_running = false;           // watchLoop exits within ~250 ms
        if (g_thread.joinable()) g_thread.join();
    }
    std::lock_guard<std::mutex> lk(g_mx);
    g_latest.clear();
    return "ok";
}

// Human-readable state dump for troubleshooting from SQF.
static std::string diag() {
    std::lock_guard<std::mutex> lk(g_mx);
    bool exists = !g_exportFile.empty() &&
                  GetFileAttributesA(g_exportFile.c_str()) != INVALID_FILE_ATTRIBUTES;
    char b[1200];
    snprintf(b, sizeof(b),
        "running=%d watching=%s exists=%d counter=%lu latest=%s liveDir=%s err=%s",
        g_running ? 1 : 0,
        g_exportFile.empty() ? "(none)" : g_exportFile.c_str(),
        exists ? 1 : 0,
        g_counter,
        g_latest.empty() ? "(none)" : g_latest.c_str(),
        g_liveDir.empty() ? "(none)" : g_liveDir.c_str(),
        g_lastError.empty() ? "(none)" : g_lastError.c_str());
    return b;
}

// ---- callExtension entry points --------------------------------------------
extern "C" {

__declspec(dllexport) void __stdcall RVExtensionVersion(char *output, int outputSize) {
    writeOut(output, outputSize, "retexlink 0.2");
}

// Legacy string form: only "poll" is meaningful here.
__declspec(dllexport) void __stdcall RVExtension(char *output, int outputSize, const char *function) {
    std::string f = function ? function : "";
    if (f == "poll") {
        std::lock_guard<std::mutex> lk(g_mx);
        writeOut(output, outputSize, g_latest);
    } else {
        writeOut(output, outputSize, "ERROR:use the args form");
    }
}

__declspec(dllexport) int __stdcall RVExtensionArgs(
        char *output, int outputSize, const char *function,
        const char **argv, int argc) {
    std::string f = function ? function : "";
    std::string res;
    if (f == "watch") {
        res = startWatch(argc > 0 ? unquote(argv[0]) : std::string());
    } else if (f == "poll") {
        std::lock_guard<std::mutex> lk(g_mx);
        res = g_latest;
    } else if (f == "stop") {
        res = stopWatch();
    } else if (f == "ping") {
        res = "retexlink 0.2";
    } else if (f == "diag") {
        res = diag();
    } else {
        res = "ERROR:unknown function";
    }
    writeOut(output, outputSize, res);
    return 0;
}

} // extern "C"
