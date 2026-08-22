# dsh-computer-use-windows

[English](./README_EN.md) | [中文](./README.md)

适用于 **Windows** 的 DeepSeek Harness Computer Use 插件。项目基于 [988hj7tczd-oss/dsh-computer-use](https://github.com/988hj7tczd-oss/dsh-computer-use)，使用 [cua-driver](https://github.com/trycua/cua) 提供 UI Automation、独立 Agent 光标和窗口操作，并可选使用智谱 GLM 进行截图视觉识别。

## 环境要求

- Windows 11（当前实测系统：10.0.22000.2538，x86_64）
- DeepSeek Harness Web Profile
- Node.js 24.14.0（当前实测版本）
- cua-driver 0.21.0（当前实测版本）

本仓库仅适用于 Windows。

## 功能

| 工具 | 功能 |
|---|---|
| `screen_observe` | 读取 Windows UIA 控件树和坐标；可选截图视觉识别 |
| `computer_click` | 单击编号元素或窗口坐标 |
| `computer_double_click` | 双击 |
| `computer_right_click` | 右键 |
| `computer_type` | 向最近观察的窗口输入文本 |
| `computer_key` | 发送按键或快捷键 |
| `computer_scroll` | 滚动 |
| `computer_drag` | 拖拽 |
| `computer_wait` | 等待界面变化 |
| `app_list` | 列出运行中的应用 |
| `app_launch` | 启动应用 |

## 安装

### 1. 安装并启动 cua-driver

按照 [cua-driver 官方说明](https://github.com/trycua/cua) 安装。确认命令可用：

~~~powershell
cua-driver --version
cua-driver doctor --json
~~~

如果程序不在 PATH，可设置：

~~~powershell
$env:CUA_DRIVER_BIN = "C:\path\to\cua-driver.exe"
~~~

插件也会探测当前 Windows 安装器常用路径：

~~~text
%LOCALAPPDATA%\Programs\Cua\cua-driver\bin\cua-driver.exe
~~~

启动守护进程：

~~~powershell
cua-driver serve --socket "\.\pipe\cua-driver"
~~~

### 2. 加入 DSH Web Profile

仓库提供 Windows 原生安装脚本（推荐）：

~~~powershell
.\tools\install-windows.ps1
~~~

脚本会将插件链接到 Web Profile、写入 Profile 的 package.json，并验证 dsh-tools 只解析到 DSH 宿主的同一实例。完成后重启现有的 dsh web 宿主。

也可以手动接入。先将仓库克隆到本地：

~~~powershell
git clone https://github.com/qphotoai/dsh-computer-use-windows.git
cd dsh-computer-use-windows
~~~

把插件链接到 Web Profile，并在 Profile 的 `package.json` 中加入：

~~~json
{
  "dependencies": {
    "dsh-computer-use": "link:C:/你的路径/dsh-computer-use-windows"
  },
  "dsh": {
    "profile": {
      "bundles": ["dsh-computer-use"]
    }
  }
}
~~~

不要在 Profile 中单独安装 `@deepseek-ai/dsh-tools`。插件必须使用 DSH 宿主的同一模块实例，否则工具可能因调度器身份不同出现 `undefined.prepare`。

安装后验证：

~~~powershell
$env:DSH_PROFILE_ROOT = "$HOME/.dsh/profiles/web"
node tools/verify-host-modules.mjs
~~~

输出中的 `pluginPath` 和 `hostPath` 必须相同。然后重启现有的 `dsh web` 宿主。

卸载：

~~~powershell
.\tools\uninstall-windows.ps1
~~~

## 使用

先观察，再操作：

~~~text
screen_observe(window="计算器", mode="ax")
computer_click(element=26)
~~~

- `window` 可传窗口标题子串或 PID。
- 编号来自最近一次 `screen_observe`。
- 快照默认约 15 秒有效；过期后需要重新观察。
- 原生 Windows 应用优先使用 `mode="ax"`。
- Canvas、图片或 UIA 信息不足时使用 `mode="vision"`。

## 智谱视觉（可选）

申请智谱 API Key 后，通过环境变量配置：

~~~powershell
$env:ZHIPU_API_KEY = "你的 Key"
~~~

也可以把 Key 单独保存到：

~~~text
%USERPROFILE%\.zhipu-key
~~~

文件只放一行 Key，并限制为当前用户可读。不要将 Key 写入仓库。

调用：

~~~text
screen_observe(window="目标窗口", mode="vision")
~~~

当前视觉实现调用智谱 GLM，不会自动调用聊天模型自身的视觉能力。视觉结果可能存在文字或坐标误识别，操作后应重新观察确认。

## 配置

`cordis.patch.yml` 默认配置：

~~~yaml
- insert:
    - id: dsh-computer-use
      name: dsh-computer-use
      config:
        ttlMs: 15000
        maxElements: 500
~~~

可配置：

~~~yaml
config:
  ttlMs: 15000
  maxElements: 500
  allowedApps: []
  cursorTheme: com.dsh.computeruse.rainbow
~~~

- `allowedApps`：允许操作的应用白名单；空数组表示不限制。
- `cursorTheme`：cua-driver 中已安装的 Agent 光标主题 ID；主题不存在时使用驱动默认光标。

仓库包含上游的 `theme.lottie` 和 `tools/make_theme.py`。光标主题的编译与安装方式以 cua-driver 官方文档为准。

## 开发

~~~powershell
node --check index.js
Get-ChildItem lib -Filter *.js | ForEach-Object { node --check $_.FullName }
node --test test/*.test.js
$env:DSH_PROFILE_ROOT = "$HOME/.dsh/profiles/web"
node tools/verify-host-modules.mjs
~~~

## 来源与许可

- 上游项目：[988hj7tczd-oss/dsh-computer-use](https://github.com/988hj7tczd-oss/dsh-computer-use)
- Windows 版本：[qphotoai/dsh-computer-use-windows](https://github.com/qphotoai/dsh-computer-use-windows)
- License：MIT
