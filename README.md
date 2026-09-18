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

## 实机验证：能力边界与踩坑（2026-09-19 逐条实测）

场景：**打开记事本 → 输入 `dsh` → 另存到桌面**。全程只用本插件的工具，结果用**文件本体**核验
（`dsh.txt` 3 字节、原始字节 `64 73 68`、无 BOM、无尾随换行、sha256 `55512BF7…A809E`、标题由 `*dsh` 变为 `dsh.txt`）。

### 1. 带修饰键的快捷键不可靠，会被打散

- `computer_key("ctrl+s")` **只送达了 `s`**，Ctrl 未生效 → `s` 作为普通字符插入正文（文档由 `dsh` 变成 `sdsh`）。
- 三次按键调用都返回 `{"delivery":{"mode":"background"},"effect":"unverifiable","escalation":{"reason":"delivery_failed","target":"foreground"}}`：后台投递失败后驱动会自行升级到前台投递。
- **普通按键（`backspace`、`return`）最终生效**。
- 结论：**不要把组合键放在关键路径上**（保存、提交这类动作），优先用菜单/按钮的**元素点击**；遇到"快捷键像是被吞了"，先怀疑修饰键没送达，而不是怀疑目标应用。

### 2. `computer_type` 走 accessibility 的 SetValue，插入点由控件决定

- 返回 `{"effect":"confirmed","evidence":[{"kind":"value_readback"}],"route":"accessibility"}` —— 它是**设置控件值并回读**，不是逐字模拟按键。
- 因此插入位置不由上次点击决定：本次 UIA SetValue 之后插入点落在**开头**，随后那个误送达的 `s` 出现在**行首**（`sdsh`）而非行尾。
- 结论：改动文本后**先重新观察读回内容**；需要局部修改时用普通按键（`backspace` 等），不要假设光标在末尾。

### 3. 系统「另存为」对话框的底部一行**不在** AX 树里

- 驱动给出的树是 **35/35 全量**，但其中**既没有文件名输入框、也没有「保存」按钮**（只有列表视图、导航窗格、工具栏等）→ 用 `screen_observe` 的编号**点不到**它。
- 兜底通道（只读）：用 UI Automation 量出确切位置 —— 对话框 `#32770`，文件名框 `480,905,1031,19`，`保存(S)` 按钮 `1331,1007,88,26`（屏幕物理像素）。
- **按坐标点「保存」实测无效**：返回 `{"code":"background_unavailable","effect":"unverifiable","path":"ax","uia_status":"unavailable","verified":false}`，事后核验**文件并未生成** —— 别把 `点击 完成` 当成生效。
- **有效绕法**：点文件名框取得焦点 → `computer_key("return")` 触发默认按钮。本次即由此保存成功。
- 切换保存位置可用：导航窗格「桌面 (已固定)」元素点击（实测地址栏随后变为 `地址: 桌面`），或点地址栏输入路径后回车。

### 4. 快照 15 秒 TTL 会拒绝动作

- 超时后动作直接被拒：`✗ 观察快照已过期（超过 15 秒）：请重新调用 screen_observe`（坐标点击与元素点击都受此约束）。
- 多步流程因此是 `observe → act → observe → act`，**每个动作前都要重新观察**；需要更长窗口时调大 `ttlMs`（见「配置」）。

### 5. 盲操作有不可逆风险 —— 先量，再动

- 桌面列表中存在 `DSH.lnk`。若把文件名当普通文本"盲打字"，首字母可能触发列表的**首字母选择**，再按回车就可能把目标对准同名项 —— 方向上是**覆盖用户数据**。
- 实操口径：① 用**量出来的**控件位置，不用推测坐标；② 保存前先确认目标文件**不存在**（本次确认桌面无 `dsh.txt` 才动手）；③ 有同名项时改名或先问用户。

### 6. 一条顺手的便利

Win11 记事本会用**正文首行**作为建议文件名：空白文档输入 `dsh` 后再打开另存为，文件名框**已预填 `dsh.txt`**，只需切换位置、无需输入文件名。

### 可复现的最小流程（本次实际生效的顺序）

~~~text
app_launch(name="记事本", bring_to_front=true)
screen_observe(window=<pid>)           → 点文本编辑器元素取得焦点
computer_type("dsh", element=<编辑器>)   → 读回确认内容
screen_observe(...)                    → 点「文件」菜单项
screen_observe(...)                    → 点「另存为」菜单项
screen_observe(...)                    → 点导航窗格「桌面 (已固定)」
   （校验：地址栏变为「地址: 桌面」、文件名框仍为 dsh.txt、目标文件尚不存在）
screen_observe(...)                    → 点文件名框取得焦点
computer_key("return")                 → 触发默认按钮「保存」
   （核验：文件本体字节数/内容/标题星号消失，而不是只看点击返回值）
~~~

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
