# dsh-computer-use-windows

[English](./README_EN.md) | [中文](./README.md)

A **Windows-only** Computer Use plugin for DeepSeek Harness. It is based on [988hj7tczd-oss/dsh-computer-use](https://github.com/988hj7tczd-oss/dsh-computer-use) and uses [cua-driver](https://github.com/trycua/cua) for Windows UI Automation, an isolated agent cursor, and window-scoped actions. Optional screenshot understanding is provided by Zhipu GLM.

## Requirements

- Windows 11 (currently tested on 10.0.22000.2538, x86_64)
- DeepSeek Harness Web profile
- Node.js 24.14.0 (tested version)
- cua-driver 0.21.0 (tested version)

This repository is intended for Windows only.

## Tools

| Tool | Purpose |
|---|---|
| `screen_observe` | Read the Windows UIA control tree and coordinates; optionally analyze a screenshot |
| `computer_click` | Click an observed element or window-local coordinates |
| `computer_double_click` | Double-click |
| `computer_right_click` | Right-click |
| `computer_type` | Type into the most recently observed window |
| `computer_key` | Send a key or shortcut |
| `computer_scroll` | Scroll |
| `computer_drag` | Drag |
| `computer_wait` | Wait for UI changes |
| `app_list` | List running applications |
| `app_launch` | Launch an application |

## Installation

### 1. Install and start cua-driver

Follow the [official cua-driver instructions](https://github.com/trycua/cua), then verify the installation:

~~~powershell
cua-driver --version
cua-driver doctor --json
~~~

If the executable is not in PATH, set:

~~~powershell
$env:CUA_DRIVER_BIN = "C:\path\to\cua-driver.exe"
~~~

The plugin also probes this common Windows installer location:

~~~text
%LOCALAPPDATA%\Programs\Cua\cua-driver\bin\cua-driver.exe
~~~

Start the daemon:

~~~powershell
cua-driver serve --socket "\.\pipe\cua-driver"
~~~

### 2. Add the plugin to the DSH Web profile

Use the included native Windows installer (recommended):

~~~powershell
.\tools\install-windows.ps1
~~~

It links the plugin into the Web profile, updates the profile package.json, and verifies that dsh-tools resolves to one host-owned instance. Restart the existing dsh web host afterward.

Manual setup is also available. Clone the repository:

~~~powershell
git clone https://github.com/qphotoai/dsh-computer-use-windows.git
cd dsh-computer-use-windows
~~~

Link the checkout from the Web profile and add it to that profile's `package.json`:

~~~json
{
  "dependencies": {
    "dsh-computer-use": "link:C:/path/to/dsh-computer-use-windows"
  },
  "dsh": {
    "profile": {
      "bundles": ["dsh-computer-use"]
    }
  }
}
~~~

Do not install another profile-local copy of `@deepseek-ai/dsh-tools`. The plugin must resolve the exact host-owned module instance; otherwise scheduler identity mismatches can cause `undefined.prepare`.

Verify the module identity:

~~~powershell
$env:DSH_PROFILE_ROOT = "$HOME/.dsh/profiles/web"
node tools/verify-host-modules.mjs
~~~

`pluginPath` and `hostPath` must be identical. Restart the existing `dsh web` host afterward.

Uninstall:

~~~powershell
.\tools\uninstall-windows.ps1
~~~

## Usage

Observe before acting:

~~~text
screen_observe(window="Calculator", mode="ax")
computer_click(element=26)
~~~

- `window` accepts a title substring or PID.
- Element numbers belong to the latest observation.
- A snapshot is valid for about 15 seconds by default; observe again after expiry.
- Prefer `mode="ax"` for native Windows applications.
- Use `mode="vision"` for Canvas, images, or incomplete UIA data.

## Field notes: capability limits (measured 2026-09-19)

Scenario: **open Notepad → type `dsh` → save to the Desktop**, using only this plugin's tools. The outcome was
verified against the **file itself**, not the UI: `dsh.txt`, 3 bytes, raw bytes `64 73 68`, no BOM, no trailing
newline, sha256 `55512BF7…A809E`, window title went from `*dsh` to `dsh.txt`.

### 1. Modifier hotkeys are unreliable and can be split apart

- `computer_key("ctrl+s")` delivered **only the `s`** — Ctrl never arrived, so the `s` was inserted as literal
  text (the document went from `dsh` to `sdsh`).
- All three key calls returned `{"delivery":{"mode":"background"},"effect":"unverifiable","escalation":{"reason":"delivery_failed","target":"foreground"}}`:
  after background delivery fails, the driver escalates to foreground delivery on its own.
- **Plain keys (`backspace`, `return`) do work.**
- Takeaway: **keep modifier combinations off the critical path** (saving, submitting) and prefer **element clicks**
  on menus/buttons. When a shortcut looks "swallowed", suspect the modifier first — not the target application.

### 2. `computer_type` uses the accessibility SetValue path, so the insertion point is up to the control

- It returns `{"effect":"confirmed","evidence":[{"kind":"value_readback"}],"route":"accessibility"}` — it **sets the
  control value and reads it back**, rather than simulating keystrokes one by one.
- The insertion point therefore does not follow your last click: after this UIA SetValue the caret sat at the
  **start**, so the stray `s` landed at the **beginning** (`sdsh`) instead of the end.
- Takeaway: after modifying text, **re-observe and read the value back**; use plain keys (`backspace`, …) for local
  edits, and never assume the caret is at the end.

### 3. The bottom row of the system **Save As** dialog is **not** in the AX tree

- The driver's tree was **35/35 complete**, yet it contained **neither the file-name box nor the Save button**
  (only the list view, navigation pane, toolbars, …) → you cannot reach them by `screen_observe` element numbers.
- Read-only fallback: measure the controls with UI Automation — dialog class `#32770`, file-name box
  `480,905,1031,19`, `保存(S)` button `1331,1007,88,26` (physical screen pixels).
- **Clicking Save by coordinates did nothing in practice**: it returned
  `{"code":"background_unavailable","effect":"unverifiable","path":"ax","uia_status":"unavailable","verified":false}`,
  and the file was **not** created afterwards. Do not read `点击 完成` as success.
- **What worked**: click the file-name box to focus it → `computer_key("return")` to fire the default button.
  That is how this save actually succeeded.
- To change the target folder: click the navigation pane node `桌面 (已固定)` (the address bar then reads
  `地址: 桌面`), or click the address bar, type a path and press Enter.

### 4. The 15-second snapshot TTL rejects actions

- Past the TTL an action is refused outright: `✗ 观察快照已过期（超过 15 秒）：请重新调用 screen_observe`
  (this applies to coordinate clicks and element clicks alike).
- Multi-step work is therefore `observe → act → observe → act` — **re-observe before every action**. Raise `ttlMs`
  (see Configuration) when you need a longer window.

### 5. Blind actions carry irreversible risk — measure first

- The Desktop listing contains `DSH.lnk`. Typing a file name "blind" can trigger **type-ahead selection** in the
  list, and a following Enter may aim the save at that same-named item — the direction of **overwriting user data**.
- Rules of thumb: (1) click **measured** control positions, never guessed coordinates; (2) confirm the target file
  **does not exist** before saving (verified here: no `dsh.txt` on the Desktop); (3) rename or ask the user when a
  name collision exists.

### 6. One convenient side effect

Windows 11 Notepad suggests the **first line of the document** as the file name: after typing `dsh` into an empty
document, Save As already had `dsh.txt` pre-filled — only the folder needed changing.

### Minimal reproducible sequence (the order that actually worked)

~~~text
app_launch(name="Notepad", bring_to_front=true)
screen_observe(window=<pid>)          -> click the text editor element to focus it
computer_type("dsh", element=<editor>) -> read the value back to confirm
screen_observe(...)                   -> click the "File" menu item
screen_observe(...)                   -> click the "Save as" menu item
screen_observe(...)                   -> click the navigation pane node "Desktop (pinned)"
   (check: address bar shows "地址: 桌面", file-name box still dsh.txt, target file absent)
screen_observe(...)                   -> click the file-name box to focus it
computer_key("return")                -> fire the default button (Save)
   (verify: file size/bytes and the window title losing its asterisk - not the click return value)
~~~

## Optional Zhipu Vision

Set a Zhipu API key through the environment:

~~~powershell
$env:ZHIPU_API_KEY = "your key"
~~~

Alternatively, store a single-line key in:

~~~text
%USERPROFILE%\.zhipu-key
~~~

Restrict the file to the current Windows user and never commit it.

Call vision mode with:

~~~text
screen_observe(window="target window", mode="vision")
~~~

The current implementation calls Zhipu GLM; it does not automatically use the chat model's native vision capability. Vision may misread labels or coordinates, so observe again after an action.

## Configuration

The default `cordis.patch.yml` registers:

~~~yaml
- insert:
    - id: dsh-computer-use
      name: dsh-computer-use
      config:
        ttlMs: 15000
        maxElements: 500
~~~

Optional settings:

~~~yaml
config:
  ttlMs: 15000
  maxElements: 500
  allowedApps: []
  cursorTheme: com.dsh.computeruse.rainbow
~~~

- `allowedApps`: application allowlist; an empty array disables the restriction.
- `cursorTheme`: ID of a cursor theme already installed in cua-driver; the driver default is used when unavailable.

The upstream `theme.lottie` and `tools/make_theme.py` are retained. Follow cua-driver documentation to compile and install cursor themes.

## Development

~~~powershell
node --check index.js
Get-ChildItem lib -Filter *.js | ForEach-Object { node --check $_.FullName }
node --test test/*.test.js
$env:DSH_PROFILE_ROOT = "$HOME/.dsh/profiles/web"
node tools/verify-host-modules.mjs
~~~

## Attribution and License

- Upstream: [988hj7tczd-oss/dsh-computer-use](https://github.com/988hj7tczd-oss/dsh-computer-use)
- Windows fork: [qphotoai/dsh-computer-use-windows](https://github.com/qphotoai/dsh-computer-use-windows)
- License: MIT
