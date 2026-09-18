# Windows 验证指南与实测状态

## 本仓库已实测环境

- Windows 11 10.0.22000.2538，x86_64
- Node.js 24.14.0
- DSH / dsh-tools 0.1.0-rc.7
- cua-driver 0.21.0
- 1920×1080，scale factor 1.0

## 本机实测结果

- [x] Profile 加载 dsh-computer-use
- [x] dsh-tools 宿主单实例一致
- [x] 记事本打开、观察、点击、输入、回读闭环
- [x] 计算器按钮点击与显示回读闭环
- [x] 智谱视觉请求成功
- [x] 快照缺失和过期自动化测试
- [x] 记事本「输入 → 另存为到桌面」全流程（2026-09-19；保存以**文件本体**核验，不是看点击返回值）
- [x] 「另存为」对话框底部行不在 AX 树内（2026-09-19；按坐标点「保存」无效，改用「点文件名框 → `return`」成功）
- [x] 快照 TTL 到期拒绝动作（2026-09-19；坐标点击被拒：`观察快照已过期`）
- [ ] 修饰键组合键（`ctrl+s`）可靠性回归 —— 2026-09-19 实测**修饰键丢失**，尚无自动化回归
- [ ] 管理员权限窗口结构化拒绝实测
- [ ] 125%/150% DPI
- [ ] 多显示器与负坐标原点
- [ ] Windows 10

## 建议复测步骤

1. 运行 cua-driver status 和 cua-driver call health_report。
2. 运行 dsh --profile web --dump-config，确认包含 dsh-computer-use。
3. 运行 tools/verify-host-modules.mjs，确认 pluginPath 等于 hostPath。
4. 在记事本完成观察、点击、输入和回读。
5. 在计算器完成数字按钮输入和显示回读。
6. 配置测试 Key 后执行 screen_observe(mode=vision)，检查视觉结果并避免盲点。
7. 用菜单「文件 → 另存为」把文档存到桌面，并按**文件本体**核验（不要用 `ctrl+s`，见下）。

## 复测环境与记录（2026-09-19，本机）

用 `node -v`、`cua-driver --version`、`Win32_VideoController` 现测（**环境数字都会过期，别当常量抄**）：

- OS：Windows 11 Pro build **26200**
- Node.js：**v24.18.1**
- cua-driver：**0.28.2**
- 显示：**2560×1440**，scale 100%（`HKCU:\Control Panel\Desktop\LogPixels` 未设置 ⇒ 96）

与上方「本仓库已实测环境」那组数字**不一致**（OS 22000 / Node 24.14.0 / cua-driver 0.21.0 / 1920×1080）。
不确定上方是否为同一台机器，故**保留原记录、不覆盖**，只在此登记本机现测值。

用例结果：**记事本 → 输入 `dsh` → 另存到桌面**成功。文件本体证据：`dsh.txt` 3 字节、
原始字节 `64 73 68`、无 BOM、无尾随换行、sha256 `55512BF7…A809E`；窗口标题由 `*dsh - Notepad`
变为 `dsh.txt - Notepad`。

过程中确认的三个能力边界（完整叙述与可复现流程见 `README.md` 的
「实机验证：能力边界与踩坑」一节，`README_EN.md` 为镜像）：

1. **带修饰键的快捷键不可靠**：`ctrl+s` 只送达 `s`，Ctrl 未生效（文档被写成 `sdsh`）；三次按键均报
   `escalation: {reason: "delivery_failed", target: "foreground"}`；普通按键（`backspace`/`return`）可用。
2. **系统「另存为」对话框底部一行不在 AX 树里**（树 35/35，却没有文件名框与保存按钮）；按坐标点「保存」
   返回 `background_unavailable / uia_status: unavailable / verified: false` 且**文件并未生成**；
   有效绕法 = 点文件名框取得焦点 → `computer_key("return")`。
3. **快照 15 秒 TTL 会拒绝动作**，多步流程必须 `observe → act → observe`。

本仓库仅适用于 Windows。
