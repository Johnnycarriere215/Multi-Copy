// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors
//
// Win32 implementation for clipboard operations, global hotkeys,
// system tray, and application helpers.

#ifdef _WIN32

#include "win32_bridge.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <shellapi.h>
#include <shlobj.h>

// ============================================================================
// MARK: - Clipboard Operations
// ============================================================================

static unsigned int g_clipboard_sequence = 0;

void* win32_clipboard_open(void) {
    if (!OpenClipboard(NULL)) return NULL;
    return (void*)1; // non-NULL sentinel
}

void win32_clipboard_close(void) {
    CloseClipboard();
}

int win32_clipboard_format_count(void) {
    if (!OpenClipboard(NULL)) return 0;
    int count = CountClipboardFormats();
    CloseClipboard();
    return count > 0 ? count : 0;
}

char* win32_clipboard_format_at(int index) {
    if (!OpenClipboard(NULL)) return NULL;

    UINT format = 0;
    int i = 0;
    do {
        format = EnumClipboardFormats(format);
        if (format == 0) break;
        if (i == index) break;
        i++;
    } while (format != 0);

    if (format == 0) {
        CloseClipboard();
        return NULL;
    }

    char name[256] = {0};
    if (GetClipboardFormatNameA(format, name, sizeof(name)) == 0) {
        // Predefined format
        switch (format) {
            case CF_TEXT:         strcpy_s(name, sizeof(name), "CF_TEXT"); break;
            case CF_BITMAP:       strcpy_s(name, sizeof(name), "CF_BITMAP"); break;
            case CF_METAFILEPICT: strcpy_s(name, sizeof(name), "CF_METAFILEPICT"); break;
            case CF_SYLK:         strcpy_s(name, sizeof(name), "CF_SYLK"); break;
            case CF_DIF:          strcpy_s(name, sizeof(name), "CF_DIF"); break;
            case CF_TIFF:         strcpy_s(name, sizeof(name), "CF_TIFF"); break;
            case CF_OEMTEXT:      strcpy_s(name, sizeof(name), "CF_OEMTEXT"); break;
            case CF_DIB:          strcpy_s(name, sizeof(name), "CF_DIB"); break;
            case CF_PALETTE:      strcpy_s(name, sizeof(name), "CF_PALETTE"); break;
            case CF_PENDATA:      strcpy_s(name, sizeof(name), "CF_PENDATA"); break;
            case CF_RIFF:         strcpy_s(name, sizeof(name), "CF_RIFF"); break;
            case CF_WAVE:         strcpy_s(name, sizeof(name), "CF_WAVE"); break;
            case CF_UNICODETEXT:  strcpy_s(name, sizeof(name), "CF_UNICODETEXT"); break;
            case CF_ENHMETAFILE:  strcpy_s(name, sizeof(name), "CF_ENHMETAFILE"); break;
            case CF_HDROP:        strcpy_s(name, sizeof(name), "CF_HDROP"); break;
            case CF_LOCALE:       strcpy_s(name, sizeof(name), "CF_LOCALE"); break;
            case CF_DIBV5:        strcpy_s(name, sizeof(name), "CF_DIBV5"); break;
            default:              snprintf(name, sizeof(name), "CF_%u", format); break;
        }
    }

    CloseClipboard();

    size_t len = strlen(name) + 1;
    char* result = (char*)malloc(len);
    if (result) memcpy(result, name, len);
    return result;
}

unsigned char* win32_clipboard_get_data(const char* format_name, int* out_size) {
    *out_size = 0;
    if (!OpenClipboard(NULL)) return NULL;

    UINT format = 0;
    // Try to get the format ID from name
    format = RegisterClipboardFormatA(format_name);

    // Also check standard formats
    if (format == 0) {
        if (strcmp(format_name, "CF_TEXT") == 0) format = CF_TEXT;
        else if (strcmp(format_name, "CF_UNICODETEXT") == 0) format = CF_UNICODETEXT;
        else if (strcmp(format_name, "CF_BITMAP") == 0) format = CF_BITMAP;
        else if (strcmp(format_name, "CF_TIFF") == 0) format = CF_TIFF;
        else if (strcmp(format_name, "CF_DIB") == 0) format = CF_DIB;
        else if (strcmp(format_name, "CF_HDROP") == 0) format = CF_HDROP;
        else if (strcmp(format_name, "CF_OEMTEXT") == 0) format = CF_OEMTEXT;
        else if (strcmp(format_name, "CF_RIFF") == 0) format = CF_RIFF;
        else if (strcmp(format_name, "CF_WAVE") == 0) format = CF_WAVE;
    }

    if (format == 0) {
        CloseClipboard();
        return NULL;
    }

    HANDLE hData = GetClipboardData(format);
    if (hData == NULL) {
        CloseClipboard();
        return NULL;
    }

    SIZE_T size = GlobalSize(hData);
    if (size == 0) {
        CloseClipboard();
        return NULL;
    }

    unsigned char* buffer = (unsigned char*)malloc(size);
    if (!buffer) {
        CloseClipboard();
        return NULL;
    }

    void* src = GlobalLock(hData);
    if (src) {
        memcpy(buffer, src, size);
        GlobalUnlock(hData);
    }

    CloseClipboard();
    *out_size = (int)size;
    return buffer;
}

bool win32_clipboard_set_data(
    const char** format_names,
    const unsigned char** data_buffers,
    const int* data_sizes,
    int count
) {
    if (!OpenClipboard(NULL)) return false;
    if (!EmptyClipboard()) {
        CloseClipboard();
        return false;
    }

    for (int i = 0; i < count; i++) {
        UINT format = RegisterClipboardFormatA(format_names[i]);
        if (format == 0) {
            // Try standard formats
            if (strcmp(format_names[i], "CF_TEXT") == 0) format = CF_TEXT;
            else if (strcmp(format_names[i], "CF_UNICODETEXT") == 0) format = CF_UNICODETEXT;
            else continue; // Skip unknown formats
        }

        // Only null-terminate text formats; binary formats keep exact size
        bool is_text = (format == CF_TEXT || format == CF_UNICODETEXT || format == CF_OEMTEXT);
        int allocSize = is_text ? data_sizes[i] + 1 : data_sizes[i];

        HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, allocSize);
        if (hMem) {
            void* dst = GlobalLock(hMem);
            if (dst) {
                memcpy(dst, data_buffers[i], data_sizes[i]);
                if (is_text) {
                    ((unsigned char*)dst)[data_sizes[i]] = 0; // null terminate
                }
                GlobalUnlock(hMem);
            }
            SetClipboardData(format, hMem);
        }
    }

    CloseClipboard();
    return true;
}

bool win32_clipboard_has_changed(unsigned int* change_counter) {
    unsigned int current = GetClipboardSequenceNumber();
    if (current != *change_counter) {
        *change_counter = current;
        return true;
    }
    return false;
}

unsigned int win32_clipboard_get_sequence(void) {
    return GetClipboardSequenceNumber();
}

// ============================================================================
// MARK: - Hotkey Operations
// ============================================================================

static HHOOK g_keyboard_hook = NULL;
static win32_hotkey_callback_t g_hotkey_callback = NULL;

LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode == HC_ACTION && g_hotkey_callback) {
        KBDLLHOOKSTRUCT* kb = (KBDLLHOOKSTRUCT*)lParam;

        unsigned int modifiers = 0;
        if (GetAsyncKeyState(VK_MENU)    & 0x8000) modifiers |= 1; // Alt
        if (GetAsyncKeyState(VK_CONTROL) & 0x8000) modifiers |= 2; // Ctrl
        if (GetAsyncKeyState(VK_SHIFT)   & 0x8000) modifiers |= 4; // Shift
        if (GetAsyncKeyState(VK_LWIN)    & 0x8000) modifiers |= 8; // Win
        if (GetAsyncKeyState(VK_RWIN)    & 0x8000) modifiers |= 8; // Win

        bool is_key_down = (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN);
        bool consumed = g_hotkey_callback(kb->vkCode, modifiers, is_key_down);
        if (consumed) return 1; // Prevent system from seeing this event
    }

    return CallNextHookEx(NULL, nCode, wParam, lParam);
}

void* win32_hotkey_start(win32_hotkey_callback_t callback) {
    g_hotkey_callback = callback;
    g_keyboard_hook = SetWindowsHookEx(WH_KEYBOARD_LL, LowLevelKeyboardProc,
                                        GetModuleHandle(NULL), 0);
    if (!g_keyboard_hook) {
        g_hotkey_callback = NULL;
        return NULL;
    }
    return (void*)g_keyboard_hook;
}

void win32_hotkey_stop(void* hook_handle) {
    if (g_keyboard_hook) {
        UnhookWindowsHookEx(g_keyboard_hook);
        g_keyboard_hook = NULL;
    }
    g_hotkey_callback = NULL;
}

void win32_simulate_key_press(unsigned int key_code, unsigned int modifiers) {
    INPUT inputs[4] = {0};
    int count = 0;

    // Press modifiers
    if (modifiers & 1) { inputs[count].type = INPUT_KEYBOARD; inputs[count].ki.wVk = VK_MENU; count++; }
    if (modifiers & 2) { inputs[count].type = INPUT_KEYBOARD; inputs[count].ki.wVk = VK_CONTROL; count++; }
    if (modifiers & 4) { inputs[count].type = INPUT_KEYBOARD; inputs[count].ki.wVk = VK_SHIFT; count++; }
    if (modifiers & 8) { inputs[count].type = INPUT_KEYBOARD; inputs[count].ki.wVk = VK_LWIN; count++; }

    // Press key
    inputs[count].type = INPUT_KEYBOARD;
    inputs[count].ki.wVk = (WORD)key_code;
    count++;

    // Release key
    inputs[count].type = INPUT_KEYBOARD;
    inputs[count].ki.wVk = (WORD)key_code;
    inputs[count].ki.dwFlags = KEYEVENTF_KEYUP;
    count++;

    // Release modifiers (reverse order)
    if (modifiers & 8) { inputs[count].type = INPUT_KEYBOARD; inputs[count].ki.wVk = VK_LWIN; inputs[count].ki.dwFlags = KEYEVENTF_KEYUP; count++; }
    if (modifiers & 4) { inputs[count].type = INPUT_KEYBOARD; inputs[count].ki.wVk = VK_SHIFT; inputs[count].ki.dwFlags = KEYEVENTF_KEYUP; count++; }
    if (modifiers & 2) { inputs[count].type = INPUT_KEYBOARD; inputs[count].ki.wVk = VK_CONTROL; inputs[count].ki.dwFlags = KEYEVENTF_KEYUP; count++; }
    if (modifiers & 1) { inputs[count].type = INPUT_KEYBOARD; inputs[count].ki.wVk = VK_MENU; inputs[count].ki.dwFlags = KEYEVENTF_KEYUP; count++; }

    SendInput(count, inputs, sizeof(INPUT));
}

void win32_simulate_copy(void) {
    win32_simulate_key_press('C', 2); // Ctrl+C
}

void win32_simulate_paste(void) {
    win32_simulate_key_press('V', 2); // Ctrl+V
}

// ============================================================================
// MARK: - System Tray
// ============================================================================

#define WM_TRAYICON  (WM_APP + 1)
#define ID_TRAYICON  1

static NOTIFYICONDATAA g_nid = {0};
static HWND g_tray_hwnd = NULL;
static win32_tray_callback_t g_tray_click_callback = NULL;
static HMENU g_tray_menu = NULL;

LRESULT CALLBACK TrayWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_TRAYICON:
            if (lParam == WM_LBUTTONUP || lParam == WM_RBUTTONUP) {
                if (g_tray_click_callback) {
                    g_tray_click_callback();
                }

                // Show right-click context menu
                if (lParam == WM_RBUTTONUP && g_tray_menu) {
                    POINT pt;
                    GetCursorPos(&pt);
                    SetForegroundWindow(hwnd);
                    TrackPopupMenu(g_tray_menu, TPM_LEFTALIGN | TPM_BOTTOMALIGN,
                                   pt.x, pt.y, 0, hwnd, NULL);
                }
            }
            break;
        case WM_TRAYICON + 1:
            // Notification from main thread: show minimized-to-tray message
            win32_tray_show_notification(
                "Jacque-Copy",
                "Window minimized to tray. Click the tray icon to restore."
            );
            break;
        case WM_COMMAND:
            if (LOWORD(wParam) == 1001) { // Quit
                win32_window_cleanup();
                win32_tray_destroy();
                PostQuitMessage(0);
            } else if (LOWORD(wParam) == 1002) { // Show settings/about
                if (g_tray_click_callback) {
                    g_tray_click_callback();
                }
            }
            break;
        case WM_DESTROY:
            PostQuitMessage(0);
            break;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

bool win32_tray_create(const char* tooltip) {
    // Create a hidden window for tray messages
    HINSTANCE hInst = GetModuleHandle(NULL);
    WNDCLASSA wc = {0};
    wc.lpfnWndProc = TrayWndProc;
    wc.hInstance = hInst;
    wc.lpszClassName = "JacqueCopyTrayClass";
    RegisterClassA(&wc);

    g_tray_hwnd = CreateWindowA("JacqueCopyTrayClass", "JacqueCopy",
                                 WS_OVERLAPPEDWINDOW, 0, 0, 1, 1,
                                 NULL, NULL, hInst, NULL);

    if (!g_tray_hwnd) return false;

    // Create tray context menu
    g_tray_menu = CreatePopupMenu();
    AppendMenuA(g_tray_menu, MF_STRING, 1002, "Show Jacque-Copy");
    AppendMenuA(g_tray_menu, MF_SEPARATOR, 0, NULL);
    AppendMenuA(g_tray_menu, MF_STRING, 1001, "Quit");

    // Create tray icon
    memset(&g_nid, 0, sizeof(g_nid));
    g_nid.cbSize = sizeof(NOTIFYICONDATAA);
    g_nid.hWnd = g_tray_hwnd;
    g_nid.uID = ID_TRAYICON;
    g_nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
    g_nid.uCallbackMessage = WM_TRAYICON;
    g_nid.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    strncpy_s(g_nid.szTip, sizeof(g_nid.szTip), tooltip, _TRUNCATE);

    return Shell_NotifyIconA(NIM_ADD, &g_nid);
}

void win32_tray_destroy(void) {
    if (g_nid.cbSize > 0) {
        Shell_NotifyIconA(NIM_DELETE, &g_nid);
        memset(&g_nid, 0, sizeof(g_nid));
    }
    if (g_tray_menu) {
        DestroyMenu(g_tray_menu);
        g_tray_menu = NULL;
    }
    if (g_tray_hwnd) {
        DestroyWindow(g_tray_hwnd);
        g_tray_hwnd = NULL;
    }
}

void win32_tray_set_click_callback(win32_tray_callback_t callback) {
    g_tray_click_callback = callback;
}

void win32_tray_show_notification(const char* title, const char* message) {
    if (g_nid.cbSize == 0) return;

    NOTIFYICONDATAA nid = g_nid;
    nid.uFlags = NIF_INFO;
    nid.dwInfoFlags = NIIF_INFO;
    strncpy_s(nid.szInfoTitle, sizeof(nid.szInfoTitle), title, _TRUNCATE);
    strncpy_s(nid.szInfo, sizeof(nid.szInfo), message, _TRUNCATE);

    Shell_NotifyIconA(NIM_MODIFY, &nid);
}

// ============================================================================
// MARK: - Memory Management
// ============================================================================

void win32_free(void* ptr) {
    if (ptr) free(ptr);
}

// ============================================================================
// MARK: - Application Helpers
// ============================================================================

char* win32_get_module_path(void) {
    char path[MAX_PATH] = {0};
    GetModuleFileNameA(NULL, path, MAX_PATH);
    size_t len = strlen(path) + 1;
    char* result = (char*)malloc(len);
    if (result) memcpy(result, path, len);
    return result;
}

char* win32_get_foreground_process(void) {
    HWND hwnd = GetForegroundWindow();
    if (!hwnd) return strdup("Unknown");

    DWORD pid;
    GetWindowThreadProcessId(hwnd, &pid);

    HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (!hProcess) return strdup("Unknown");

    char path[MAX_PATH] = {0};
    DWORD size = MAX_PATH;
    if (QueryFullProcessImageNameA(hProcess, 0, path, &size)) {
        CloseHandle(hProcess);
        // Extract just the filename
        char* filename = strrchr(path, '\\');
        if (filename) filename++; else filename = path;

        // Remove extension
        char* dot = strrchr(filename, '.');
        if (dot) *dot = '\0';

        size_t len = strlen(filename) + 1;
        char* result = (char*)malloc(len);
        if (result) memcpy(result, filename, len);
        return result;
    }

    CloseHandle(hProcess);
    return strdup("Unknown");
}

char* win32_get_appdata_path(void) {
    char path[MAX_PATH] = {0};
    if (SHGetFolderPathA(NULL, CSIDL_APPDATA, NULL, 0, path) == S_OK) {
        strcat_s(path, sizeof(path), "\\JacqueCopy");

        // Create directory if it doesn't exist
        SHCreateDirectoryExA(NULL, path, NULL);

        size_t len = strlen(path) + 1;
        char* result = (char*)malloc(len);
        if (result) memcpy(result, path, len);
        return result;
    }
    return strdup(".");
}

void win32_run_message_loop(void) {
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
}

void win32_post_quit(void) {
    PostQuitMessage(0);
}

// ============================================================================
// MARK: - Window Management (Tray Minimize)
// ============================================================================

static HWND g_app_hwnd = NULL;
static WNDPROC g_original_wndproc = NULL;
static char g_window_title[256] = {0};
static void (*g_on_window_hidden)(void) = NULL;

/// EnumWindows callback to find our app window by title.
static BOOL CALLBACK FindAppWindowProc(HWND hwnd, LPARAM lParam) {
    DWORD pid;
    GetWindowThreadProcessId(hwnd, &pid);
    // Only consider windows from our process
    DWORD ourPid = GetCurrentProcessId();
    if (pid != ourPid) return TRUE;

    char title[256];
    GetWindowTextA(hwnd, title, sizeof(title));
    if (strlen(title) > 0 && strstr(title, g_window_title)) {
        g_app_hwnd = hwnd;
        return FALSE; // Stop enumerating
    }
    return TRUE;
}

/// Subclassed window procedure that intercepts WM_CLOSE to hide to tray.
static LRESULT CALLBACK SubclassedWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    if (msg == WM_CLOSE) {
        // Hide to tray instead of closing
        ShowWindow(hwnd, SW_HIDE);
        // Always post notification to tray thread (not guarded by callback)
        if (g_tray_hwnd) {
            PostMessage(g_tray_hwnd, WM_TRAYICON + 1, 0, 0);
        }
        return 0;
    }
    return CallWindowProc(g_original_wndproc, hwnd, msg, wParam, lParam);
}

void win32_window_init(const char* window_title, void (*on_window_hidden)(void)) {
    strncpy_s(g_window_title, sizeof(g_window_title), window_title, _TRUNCATE);
    // Store callback for future use (currently unused, notification handled in C)
    g_on_window_hidden = on_window_hidden;

    // Try a few quick attempts to find the window without sleeping
    // (EnumWindows is fast; avoid blocking the main thread)
    for (int attempt = 0; attempt < 5; attempt++) {
        g_app_hwnd = NULL;
        EnumWindows(FindAppWindowProc, 0);

        if (g_app_hwnd) {
            g_original_wndproc = (WNDPROC)SetWindowLongPtrA(
                g_app_hwnd, GWLP_WNDPROC, (LONG_PTR)SubclassedWndProc
            );
            return;
        }
    }
    // If not found, the subclass will be applied on first tray click via show_app_window
}

void win32_show_app_window(void) {
    // Try to find the window if we don't have it yet
    if (!g_app_hwnd || !IsWindow(g_app_hwnd)) {
        g_app_hwnd = NULL;
        EnumWindows(FindAppWindowProc, 0);

        // Subclass if newly found
        if (g_app_hwnd && !g_original_wndproc) {
            g_original_wndproc = (WNDPROC)SetWindowLongPtrA(
                g_app_hwnd, GWLP_WNDPROC, (LONG_PTR)SubclassedWndProc
            );
        }
    }

    if (g_app_hwnd && IsWindow(g_app_hwnd)) {
        ShowWindow(g_app_hwnd, SW_SHOW);
        SetForegroundWindow(g_app_hwnd);
    }
}

void win32_hide_app_window(void) {
    if (g_app_hwnd && IsWindow(g_app_hwnd)) {
        ShowWindow(g_app_hwnd, SW_HIDE);
    }
}

void win32_tray_notify_hidden(void) {
    // Safely post a notification to the tray's thread
    if (g_tray_hwnd) {
        PostMessage(g_tray_hwnd, WM_TRAYICON + 1, 0, 0);
    }
}

void win32_window_cleanup(void) {
    // Restore original WndProc before destroying
    if (g_app_hwnd && g_original_wndproc && IsWindow(g_app_hwnd)) {
        SetWindowLongPtrA(g_app_hwnd, GWLP_WNDPROC, (LONG_PTR)g_original_wndproc);
    }
    g_app_hwnd = NULL;
    g_original_wndproc = NULL;
    g_on_window_hidden = NULL;
}

#endif // _WIN32
