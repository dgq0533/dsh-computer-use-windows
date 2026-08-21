# 验证记录

本文件只记录本仓库维护者实际完成的验证，不继承上游未在本机复现的测试结论。

## 环境

- 日期：2026-08-21
- Windows 11 10.0.22000.2538，x86_64
- Node.js 24.14.0
- DSH / dsh-tools 0.1.0-rc.7
- cua-driver 0.21.0
- 单显示器 1920×1080，scale factor 1.0

## 已验证

- DSH web Profile 合成配置包含 dsh-computer-use。
- 插件与宿主解析到同一份 dsh-tools；Profile 无第二份实体副本。
- app_list、app_launch、screen_observe、computer_click、computer_type、computer_wait 可从真实 DSH 会话调用。
- 记事本：观察编辑器、点击、输入 DSH computer-use verified、重新观察确认成功。
- 计算器：点击 1、5、6、9、8，重新观察确认显示 15,698。
- 智谱视觉：计算器截图请求成功返回视觉描述，但存在文字和坐标误识别。
- 自动化测试：4/4 通过。

## 部分验证或未验证

- UI Automation provider 曾在 health_report 中超时；特定窗口 UIA 后续可用，但不能证明所有应用稳定。
- 密码角色和危险词有代码及单元逻辑覆盖，未对真实支付或密码页面执行危险操作。
- 管理员权限窗口未执行操作测试。
- 125%/150% DPI、多显示器、负坐标显示器未测试。
- 本仓库仅适用于 Windows；未进行其他操作系统兼容性验证。

## 已知运行事件

- 曾因 Profile 和 DSH 核心加载两份 dsh-tools 导致 undefined.prepare；现通过 peer 与解析一致性检查规避。
- 重启 DSH 时曾遇到 task-board 旧进程锁；该问题属于任务看板锁，不是 computer-use 功能验证结果。
- SQLite ExperimentalWarning 不影响本轮 computer-use 测试。
