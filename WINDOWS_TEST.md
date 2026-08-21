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

本仓库仅适用于 Windows。
