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
