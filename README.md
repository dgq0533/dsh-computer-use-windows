# dsh-computer-use-windows

DeepSeek Harness 的 Computer Use 插件，基于 [上游 dsh-computer-use](https://github.com/988hj7tczd-oss/dsh-computer-use) 修改，重点修复当前 DSH 在 Windows 上的宿主依赖单实例、UIA 识别、窗口定向输入和坐标问题。自动化引擎使用 [cua-driver](https://github.com/trycua/cua)。

> **适用平台：Windows。** 本仓库按 Windows 版本维护，不声明支持 macOS 或 Linux。当前实际验证环境为 Windows 11。

## 实际测试环境

- Windows 11，系统版本 10.0.22000.2538，x86_64
- Node.js 24.14.0
- DeepSeek Harness / @deepseek-ai/dsh-tools 0.1.0-rc.7
- cua-driver 0.21.0
- 单显示器 1920×1080；驱动报告缩放 1.0
- DSH Web GUI，Profile：web

Windows 内尚未测试：125%/150% DPI、多显示器、负坐标显示器、管理员权限窗口。

## 工具

| 工具 | 功能 |
|---|---|
| screen_observe | Windows UIA/AX 编号树；可选智谱截图视觉 |
| computer_click / computer_double_click / computer_right_click | 按观察编号或坐标操作 |
| computer_type | 向最近观察的精确窗口输入文本 |
| computer_key | 向最近观察的精确窗口发送按键 |
| computer_scroll | 滚动 |
| computer_drag | 拖拽 |
| computer_wait | 等待 |
| app_list / app_launch | 列出或启动应用 |

## 本仓库的修复

- 将 @deepseek-ai/dsh-tools 改为 peer dependency，避免 Profile 安装第二份模块后触发 undefined.prepare。
- 增加插件与宿主模块解析一致性检查。
- 探测本机实际 Windows cua-driver 安装路径。
- 移除 Windows 上错误的固定 Retina 2 倍坐标缩放。
- 排除 Cua.AgentCursorOverlay 覆盖层，避免默认观察到自身光标窗口。
- 增加 Windows UIA 控件角色和密码控件识别。
- 输入和按键要求未过期快照，并绑定最近观察的 pid 与 window_id。
- 指定窗口不存在时明确失败，不再静默操作其他窗口。
- 观察与动作使用同一个 cua-driver session。

## 已完成的真实操作验证

### Windows 记事本

启动记事本，UIA 找到“文本编辑器”，按元素编号点击，输入 DSH computer-use verified，再观察确认窗口标题与 UIA 文本均包含该内容。

### Windows 计算器

启动计算器，UIA 识别数字按钮，依次点击 1、5、6、9、8，再观察确认显示为 15,698。

### 智谱视觉

配置 Key 后，screen_observe(mode=vision) 已在计算器窗口真实返回截图视觉描述。视觉曾误识别部分按钮文字和坐标，因此应优先使用 UIA；视觉只用于 Canvas、图片或无障碍树不足的场景，并在操作后重新观察验证。

## 安全边界

- 快照默认 15 秒过期，过期后动作拒绝。
- 无快照时点击、输入和按键拒绝。
- allowedApps 可限制可操作应用。
- 元素标签命中删除、支付、转账、退出登录等危险词时请求 DSH 审批；审批不可用时失败关闭。
- 已识别的密码控件拒绝自动输入。
- 危险词和密码保护依赖 UIA 元素语义；坐标模式无法预知目标。
- computer_key 不分析快捷键自身的危险性。不要授予不可信模型不必要的权限。

## 当前验证过的安装形态

本机使用 Windows Profile 本地链接，并让插件 peer 解析到 DSH 宿主的唯一模块实例。安装后运行：

~~~powershell
$env:DSH_PROFILE_ROOT = "$HOME/.dsh/profiles/web"
node tools/verify-host-modules.mjs
~~~

预期 pluginPath 与 hostPath 完全相同，并且 Profile 中不存在独立安装的 @deepseek-ai/dsh-tools。

上游 install.sh 未用于本次 Windows 安装验证。本仓库仅维护 Windows 用法；该 Shell 脚本作为上游遗留文件保留，不作为推荐安装方式。

## 视觉配置（可选）

~~~powershell
$env:ZHIPU_API_KEY = "你的 Key"
# 或保存到 $HOME/.zhipu-key，只含一行 Key，并限制文件权限
~~~

Key 不得提交到仓库。当前实现调用智谱 GLM 视觉后端，不会自动使用当前聊天模型的原生视觉能力。

## 测试

~~~powershell
node --check index.js
Get-ChildItem lib -Filter *.js | ForEach-Object { node --check $_.FullName }
node --test test/*.test.js
$env:DSH_PROFILE_ROOT = "$HOME/.dsh/profiles/web"
node tools/verify-host-modules.mjs
~~~

当前自动化测试共 4 个，全部通过，覆盖快照缺失/过期、token 解析、Windows 1×坐标和危险标签检测。这不代表所有 Windows GUI、DPI 或显示器组合都已覆盖。

## 已知问题

- cua-driver health_report 在本机曾报告 UI Automation provider 超时和降级；具体窗口的 UIA 调用仍可成功。
- app_launch(name=Calculator) 在本机失败；app_launch(bundle_id=calc.exe) 成功。
- Windows 计算器由 ApplicationFrameHost.exe 承载，启动 PID 与实际观察窗口 PID 可能不同。
- 视觉输出可能误识别按钮文字或坐标。
- 本仓库仅适用于 Windows。

## 来源与许可

- 上游：[988hj7tczd-oss/dsh-computer-use](https://github.com/988hj7tczd-oss/dsh-computer-use)
- 本仓库：[chowhang/dsh-computer-use-windows](https://github.com/chowhang/dsh-computer-use-windows)
- License：MIT，保留上游许可证。
