#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <sddl.h>
#include <string>
#include <vector>
#include <thread>

#include "flutter_window.h"
#include "utils.h"

// Include reader-writer lock for PLUGIN_STARTUP_URL synchronization with plugin
#include "../flutter/ephemeral/.plugin_symlinks/auth0_flutter/windows/plugin_startup_url_lock.h"

const wchar_t* kSingleInstanceMutex = L"auth0flutter_single_instance_mutex";

// ---------------------------------------------------------------------------
// URI scheme self-registration
//
// Registers "auth0flutter://" in HKCU\Software\Classes so the OS knows to
// launch this executable when the browser redirects to auth0flutter://callback.
//
// Using HKCU (per-user) means no admin rights are required, and the entry
// automatically points to the current build output — essential for `flutter
// run` where the exe path changes on every build.
// ---------------------------------------------------------------------------
static void RegisterUriScheme() {
  wchar_t exePath[MAX_PATH] = {};
  if (GetModuleFileNameW(nullptr, exePath, MAX_PATH) == 0) {
    return;  // cannot determine own path — skip silently
  }

  // Build the open command: "C:\path\to\sample.exe" "%1"
  std::wstring command = L"\"";
  command += exePath;
  command += L"\" \"%1\"";

  // Check whether the registry already contains this exact command.
  // If so, skip writing to avoid unnecessary registry churn on every launch.
  {
    HKEY hCheck = nullptr;
    if (RegOpenKeyExW(HKEY_CURRENT_USER,
                      L"Software\\Classes\\auth0flutter\\shell\\open\\command",
                      0, KEY_READ, &hCheck) == ERROR_SUCCESS) {
      wchar_t existing[MAX_PATH * 2] = {};
      DWORD size = sizeof(existing);
      DWORD type = REG_SZ;
      RegQueryValueExW(hCheck, nullptr, nullptr, &type,
                       reinterpret_cast<LPBYTE>(existing), &size);
      RegCloseKey(hCheck);
      if (command == existing) {
        return;  // already registered with the correct path
      }
    }
  }

  // Write root key  HKCU\Software\Classes\auth0flutter
  HKEY hRoot = nullptr;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, L"Software\\Classes\\auth0flutter",
                      0, nullptr, REG_OPTION_NON_VOLATILE,
                      KEY_WRITE, nullptr, &hRoot, nullptr) != ERROR_SUCCESS) {
    return;
  }
  const wchar_t* kDisplayName = L"URL:auth0flutter Protocol";
  RegSetValueExW(hRoot, nullptr, 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(kDisplayName),
                 static_cast<DWORD>((wcslen(kDisplayName) + 1) * sizeof(wchar_t)));
  // "URL Protocol" empty value marks this key as a URI scheme handler
  RegSetValueExW(hRoot, L"URL Protocol", 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(L""),
                 static_cast<DWORD>(sizeof(wchar_t)));
  RegCloseKey(hRoot);

  // Write open command  HKCU\Software\Classes\auth0flutter\shell\open\command
  HKEY hCmd = nullptr;
  if (RegCreateKeyExW(HKEY_CURRENT_USER,
                      L"Software\\Classes\\auth0flutter\\shell\\open\\command",
                      0, nullptr, REG_OPTION_NON_VOLATILE,
                      KEY_WRITE, nullptr, &hCmd, nullptr) != ERROR_SUCCESS) {
    return;
  }
  RegSetValueExW(hCmd, nullptr, 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(command.c_str()),
                 static_cast<DWORD>((command.size() + 1) * sizeof(wchar_t)));
  RegCloseKey(hCmd);
}
const wchar_t* kRedirectPipeName    = L"\\\\.\\pipe\\auth0flutter_pipe";

// Only URLs beginning with this prefix are accepted from the pipe.
// Matches kDefaultRedirectUri in oauth_helpers.h.
const wchar_t* kCallbackPrefix = L"auth0flutter://callback";

// Builds a SECURITY_DESCRIPTOR that grants pipe read/write access only to the
// current user's SID, preventing other users or processes from connecting.
// Returns NULL on failure. Caller must LocalFree() the returned pointer.
static PSECURITY_DESCRIPTOR BuildCurrentUserSD() {
  HANDLE hToken = NULL;
  if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &hToken))
    return NULL;

  // Query required buffer size, then fetch the token user info.
  DWORD cbTokenUser = 0;
  GetTokenInformation(hToken, TokenUser, NULL, 0, &cbTokenUser);
  if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
    CloseHandle(hToken);
    return NULL;
  }

  std::vector<BYTE> buf(cbTokenUser);
  auto* pTokenUser = reinterpret_cast<PTOKEN_USER>(buf.data());
  if (!GetTokenInformation(hToken, TokenUser, pTokenUser, cbTokenUser, &cbTokenUser)) {
    CloseHandle(hToken);
    return NULL;
  }
  CloseHandle(hToken);

  // Convert the SID to a string so we can embed it in an SDDL expression.
  LPWSTR pszSid = NULL;
  if (!ConvertSidToStringSidW(pTokenUser->User.Sid, &pszSid))
    return NULL;

  // D:(A;;GRGW;;;S-1-5-…) — grant generic read+write to current user only.
  std::wstring sddl = L"D:(A;;GRGW;;;";
  sddl += pszSid;
  sddl += L")";
  LocalFree(pszSid);

  PSECURITY_DESCRIPTOR pSD = NULL;
  ConvertStringSecurityDescriptorToSecurityDescriptorW(
      sddl.c_str(), SDDL_REVISION_1, &pSD, NULL);
  return pSD;  // caller must LocalFree()
}

// Forward URI to first instance (pipe client).
// Waits up to 2 seconds for the pipe server to become available — the first
// instance's detached thread may not have called CreateNamedPipeW yet.
void ForwardToFirstInstance(const wchar_t* uri) {
  // Wait for the pipe to exist (handles the race between the first instance's
  // StartPipeServer thread and this second-instance launch).
  if (!WaitNamedPipeW(kRedirectPipeName, 2000)) {
    return;  // pipe never appeared — nothing we can do
  }

  HANDLE hPipe = CreateFileW(
      kRedirectPipeName, GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);

  // Retry once on PIPE_BUSY (another client just connected).
  if (hPipe == INVALID_HANDLE_VALUE && GetLastError() == ERROR_PIPE_BUSY) {
    if (WaitNamedPipeW(kRedirectPipeName, 2000)) {
      hPipe = CreateFileW(
          kRedirectPipeName, GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
    }
  }

  if (hPipe != INVALID_HANDLE_VALUE) {
    DWORD written = 0;
    DWORD len = static_cast<DWORD>((wcslen(uri) + 1) * sizeof(wchar_t));
    if (!WriteFile(hPipe, uri, len, &written, NULL) || written != len) {
      // Partial or failed write — the first instance won't get a valid URI.
      // Nothing actionable here; the login will time out.
    }
    CloseHandle(hPipe);
  }
}

// Bring first instance window to foreground
void BringExistingWindowToFront() {
  HWND hwnd = FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", NULL);
  if (hwnd) {
    ShowWindow(hwnd, SW_RESTORE);
    SetForegroundWindow(hwnd);
  }
}

// Pipe server (runs in first instance)
void StartPipeServer() {
  std::thread([] {
    while (true) {
      // Prefer a user-restricted DACL so only this user's processes can write
      // to the pipe. Fall back to NULL (process-default security) when the
      // descriptor cannot be built — the URL prefix validation below still
      // prevents injection of arbitrary strings even in that case.
      PSECURITY_DESCRIPTOR pSD = BuildCurrentUserSD();

      SECURITY_ATTRIBUTES sa = {};
      SECURITY_ATTRIBUTES* pSa = nullptr;
      if (pSD) {
        sa.nLength              = sizeof(sa);
        sa.lpSecurityDescriptor = pSD;
        sa.bInheritHandle       = FALSE;
        pSa = &sa;
      }

      HANDLE hPipe = CreateNamedPipeW(
          kRedirectPipeName,
          PIPE_ACCESS_INBOUND,
          PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT,
          1, 0, 0, 0, pSa);

      // Security descriptor is no longer needed once the pipe is created.
      if (pSD) LocalFree(pSD);

      if (hPipe == INVALID_HANDLE_VALUE) {
        return;
      }

      // ConnectNamedPipe returns FALSE with ERROR_PIPE_CONNECTED when a
      // client connected between CreateNamedPipeW and this call — that is
      // a valid connection, not an error.
      BOOL connected = ConnectNamedPipe(hPipe, NULL);
      if (connected || GetLastError() == ERROR_PIPE_CONNECTED) {
        wchar_t buffer[2048];
        DWORD read = 0;
        // Reserve one wchar_t for the null terminator so buffer[read/sizeof(wchar_t)]
        // is always within bounds (fixes the off-by-one overflow).
        BOOL readOk = ReadFile(hPipe, buffer, sizeof(buffer) - sizeof(wchar_t), &read, NULL);

        if (!readOk && GetLastError() == ERROR_MORE_DATA) {
          // Message exceeds buffer — reject it rather than processing a truncated URL.
          // Auth0 callback URLs are typically short; an oversized message is suspicious.
        } else if (readOk) {
          buffer[read / sizeof(wchar_t)] = L'\0';

          // Only accept URLs that begin with the expected auth0flutter:// prefix.
          // This is a defence-in-depth guard: even if an attacker managed to
          // connect to the pipe despite the restricted DACL, they cannot
          // overwrite PLUGIN_STARTUP_URL with an arbitrary string.
          size_t prefixLen = wcslen(kCallbackPrefix);
          if (wcslen(buffer) >= prefixLen &&
              wcsncmp(buffer, kCallbackPrefix, prefixLen) == 0) {
            // Synchronize with polling threads (oauth_helpers.cpp) to prevent TOCTOU race.
            // Acquire write lock (exclusive access) so polling threads are blocked while
            // we write to PLUGIN_STARTUP_URL. Polling threads acquire read locks, which
            // allows multiple readers to proceed simultaneously, but blocks when writer holds
            // the lock (true reader-writer lock semantics).
            auth0_flutter::WriteLockGuard writeLock(auth0_flutter::GetPluginUrlRwLock());
            if (writeLock.IsValid()) {
              SetEnvironmentVariableW(L"PLUGIN_STARTUP_URL", buffer);
            }
            // WriteLockGuard destructor releases the write lock automatically
            BringExistingWindowToFront();
          }
        }
      }
      DisconnectNamedPipe(hPipe);
      CloseHandle(hPipe);
    }
  }).detach();
}

int APIENTRY wWinMain(
    _In_ HINSTANCE instance,
    _In_opt_ HINSTANCE prev,
    _In_ wchar_t* /*command_line*/,
    _In_ int show_command) {

  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // -----------------------------
  // Parse command line properly
  // -----------------------------
  int argc = 0;
  LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc);

  std::wstring startupUri;
  if (argv && argc > 1) {
    // argv[1] is already de-quoted by Windows
    startupUri = argv[1];
  }

  if (argv) {
    LocalFree(argv);
  }

  // -----------------------------
  // Ensure single instance
  // -----------------------------
  bool hasUri = !startupUri.empty();

HANDLE hMutex = CreateMutexW(NULL, TRUE, kSingleInstanceMutex);
bool alreadyRunning = (hMutex && GetLastError() == ERROR_ALREADY_EXISTS);

if (alreadyRunning) {
  // Another instance is already running. Bring it to the foreground and exit,
  // regardless of whether this launch carried a protocol URI.
  BringExistingWindowToFront();
  if (hasUri) {
    ForwardToFirstInstance(startupUri.c_str());
  }
  CloseHandle(hMutex);
  return 0;
}

  // -----------------------------
  // Register URI scheme (first instance only)
  // -----------------------------
  // Writes HKCU\Software\Classes\auth0flutter\shell\open\command pointing at
  // the current executable so the OS can launch this app when the browser
  // redirects to auth0flutter://callback after authentication.
  // Using HKCU requires no admin rights. Re-registration is skipped when the
  // command already matches, so there is no overhead on subsequent launches.
  RegisterUriScheme();

  // -----------------------------
  // First instance: store startup URI
  // -----------------------------
  // Apply the same prefix guard as the pipe server: only accept URIs that
  // begin with the expected auth0flutter:// scheme.  This ensures that an
  // unrelated protocol activation (e.g. a deep-link from a different app)
  // cannot overwrite PLUGIN_STARTUP_URL with arbitrary data.
  if (!startupUri.empty()) {
    size_t prefixLen = wcslen(kCallbackPrefix);
    bool isOurCallback = (startupUri.size() >= prefixLen &&
                          startupUri.compare(0, prefixLen, kCallbackPrefix) == 0);
    if (isOurCallback) {
      SetEnvironmentVariableW(L"PLUGIN_STARTUP_URL", startupUri.c_str());
    } else {
      SetEnvironmentVariableW(L"PLUGIN_STARTUP_URL", L"");
    }
  } else {
    SetEnvironmentVariableW(L"PLUGIN_STARTUP_URL", L"");
  }

  StartPipeServer();

  // -----------------------------
  // Flutter bootstrap
  // -----------------------------
  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"sample", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
