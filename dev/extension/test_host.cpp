// Standalone test host for retexlink_x64.dll - exercises the callExtension entry
// points the way Arma would, so we can validate watch/poll/rotate without the game.
#include <windows.h>
#include <cstdio>
#include <string>

typedef void (__stdcall *VerFn)(char*, int);
typedef int  (__stdcall *ArgsFn)(char*, int, const char*, const char**, int);

int main(int argc, char** argv) {
    if (argc < 2) { printf("usage: test_host <exportFile>\n"); return 2; }
    const char* exportFile = argv[1];

    HMODULE h = LoadLibraryA("retexlink_x64.dll");
    if (!h) { printf("FAIL: LoadLibrary (err %lu)\n", GetLastError()); return 1; }

    auto ver  = (VerFn)  GetProcAddress(h, "RVExtensionVersion");
    auto args = (ArgsFn) GetProcAddress(h, "RVExtensionArgs");
    if (!ver || !args) { printf("FAIL: missing exports\n"); return 1; }

    char out[4096];
    ver(out, sizeof(out));
    printf("version: %s\n", out);

    // watch <exportFile>  (Arma passes string args quoted; mimic that)
    std::string qa = std::string("\"") + exportFile + "\"";
    const char* wv[] = { qa.c_str() };
    args(out, sizeof(out), "watch", wv, 1);
    printf("watch -> %s\n", out);
    if (std::string(out) != "ok") { printf("FAIL: watch did not return ok\n"); return 1; }

    // Seeded rotation (export file already exists) should be pollable immediately.
    args(out, sizeof(out), "poll", nullptr, 0);
    printf("poll(seed) -> %s\n", out);
    std::string first = out;

    // Simulate an editor "save": touch the export file's last-write time + content.
    Sleep(300);
    { FILE* f = fopen(exportFile, "ab"); if (f) { fputc(0, f); fclose(f); } }

    // Give the watcher thread time to notice + debounce + copy.
    std::string second;
    for (int i = 0; i < 40; ++i) {
        Sleep(100);
        args(out, sizeof(out), "poll", nullptr, 0);
        second = out;
        if (!second.empty() && second != first) break;
    }
    printf("poll(after save) -> %s\n", second.c_str());

    bool rotated = (!second.empty() && second != first);
    bool exists  = rotated && (GetFileAttributesA(second.c_str()) != INVALID_FILE_ATTRIBUTES);
    printf("rotated=%d newFileExists=%d\n", rotated, exists);

    args(out, sizeof(out), "stop", nullptr, 0);
    printf("stop -> %s\n", out);

    FreeLibrary(h);
    printf(rotated && exists ? "\nRESULT: PASS\n" : "\nRESULT: FAIL\n");
    return (rotated && exists) ? 0 : 1;
}
