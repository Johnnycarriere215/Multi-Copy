// MIT License
//
// Copyright (c) 2024 Jacque-Copy Contributors
//
// Win32 interop bridge for clipboard operations and global hotkeys.
// This C API is called from Swift via module import on Windows.

#ifndef WIN32_BRIDGE_H
#define WIN32_BRIDGE_H

#ifdef _WIN32

#include <windows.h>
#include <stdbool.h>

// MARK: - Clipboard Operations

/// Opens the clipboard and returns a handle. Returns NULL on failure.
void* win32_clipboard_open(void);

/// Closes the clipboard.
void win32_clipboard_close(void);

/// Gets the number of available clipboard formats.
int win32_clipboard_format_count(void);

/// Gets the nth clipboard format name. Caller must free the result.
char* win32_clipboard_format_at(int index);

/// Gets clipboard data for a given format. Returns a buffer with size.
/// Caller must free the result buffer.
unsigned char* win32_clipboard_get_data(const char* format_name, int* out_size);

/// Sets clipboard data. First clears the clipboard, then sets all formats.
/// `format_names` and `data_buffers` are parallel arrays of length `count`.
/// `data_sizes` contains the size of each buffer.
bool win32_clipboard_set_data(
    const char** format_names,
    const unsigned char** data_buffers,
    const int* data_sizes,
    int count
);

/// Checks if the clipboard content has changed since the last check.
/// `change_counter` is an in/out parameter tracking the last known counter.
bool win32_clipboard_has_changed(unsigned int* change_counter);

/// Gets the current clipboard sequence number for change detection.
unsigned int win32_clipboard_get_sequence(void);

// MARK: - Hotkey Operations

/// Callback type for hotkey events.
/// `key_code` is the virtual key code.
/// `modifiers` is a bitmask: 1=Alt, 2=Ctrl, 4=Shift, 8=Win.
/// `is_key_down` is true for key press, false for key release.
/// Returns true to consume the event (prevent system from seeing it),
/// false to let it pass through.
typedef bool (*win32_hotkey_callback_t)(
    unsigned int key_code,
    unsigned int modifiers,
    bool is_key_down
);

/// Installs a low-level keyboard hook and starts listening.
/// Returns a hook handle, or NULL on failure.
void* win32_hotkey_start(win32_hotkey_callback_t callback);

/// Stops the keyboard hook and cleans up.
void win32_hotkey_stop(void* hook_handle);

/// Simulates a key press (key down + key up) with optional modifiers.
/// `key_code`: virtual key code (e.g., 'C' = 0x43, 'V' = 0x56)
/// `modifiers`: bitmask (1=Alt, 2=Ctrl, 4=Shift, 8=Win)
void win32_simulate_key_press(unsigned int key_code, unsigned int modifiers);

/// Posts a synthetic Ctrl+C (for secondary copy on Windows).
void win32_simulate_copy(void);

/// Posts a synthetic Ctrl+V (for secondary paste on Windows).
void win32_simulate_paste(void);

// MARK: - System Tray

/// Creates a system tray icon with the given tooltip.
/// Returns true on success.
bool win32_tray_create(const char* tooltip);

/// Removes the system tray icon.
void win32_tray_destroy(void);

/// Sets the callback for when the tray icon is left-clicked.
typedef void (*win32_tray_callback_t)(void);
void win32_tray_set_click_callback(win32_tray_callback_t callback);

/// Shows a system tray notification balloon.
void win32_tray_show_notification(const char* title, const char* message);

// MARK: - Memory Management

/// Frees memory allocated by the bridge functions.
void win32_free(void* ptr);

// MARK: - Application Helpers

/// Gets the executable path of the current process.
/// Caller must free with win32_free.
char* win32_get_module_path(void);

/// Gets the frontmost window's process name.
/// Caller must free with win32_free.
char* win32_get_foreground_process(void);

/// Gets the user's application data directory path.
/// Caller must free with win32_free.
char* win32_get_appdata_path(void);

/// Runs the Windows message loop. Blocks until WM_QUIT is received.
void win32_run_message_loop(void);

/// Posts a quit message to exit the message loop.
void win32_post_quit(void);

// MARK: - Window Management (Tray Minimize)

/// Initializes window management for the SwiftUI app window.
/// Finds the window by title and subclasses its WndProc to intercept close.
/// Must be called after the SwiftUI window has been created.
/// `window_title`: the title of the app window to find.
/// `on_window_hidden`: callback when the window is hidden (user clicked X).
void win32_window_init(const char* window_title, void (*on_window_hidden)(void));

/// Shows the app window (restores from tray). If not yet found, searches for it.
void win32_show_app_window(void);

/// Hides the app window to the system tray.
void win32_hide_app_window(void);

/// Safely posts a minimized-to-tray notification on the tray's thread.
void win32_tray_notify_hidden(void);

/// Restores the original WndProc and cleans up window management.
void win32_window_cleanup(void);

#endif // _WIN32

#endif // WIN32_BRIDGE_H
