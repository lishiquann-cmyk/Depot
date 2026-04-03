<div align="center">
  <img src="assets/icon.png" width="160" alt="Depot" />

  # Depot

  **专为 pnpm / npm Monorepo 打造的原生 macOS 进程管理器。**

  在单一面板中运行、监控并控制所有工作区脚本，无需打开终端。

  ![macOS](https://img.shields.io/badge/macOS-26%2B-black?logo=apple)
  ![Swift](https://img.shields.io/badge/Swift-5-orange?logo=swift)
  ![License](https://img.shields.io/github/license/lishiquann-cmyk/depot)

</div>

---

## 功能特性

- **多项目管理** — 添加多个 `package.json` 项目，随时一键切换
- **自动识别** — 读取 `packageManager` 字段，自动选用 `pnpm`、`npm` 或 `yarn` 执行脚本
- **两种脚本模式** — 开发脚本使用开关切换并显示实时 URL；构建/部署脚本使用播放按钮并显示输出路径
- **实时日志** — 每个脚本拥有独立日志面板，流式展示 stdout/stderr
- **自定义分类** — 通过键名前缀（如 `mobile:`、`api:`）自定义分类，支持 SF Symbol 图标和自定义颜色
- **自定义提取规则** — 通过可配置的行前缀从日志中提取 URL 或文件夹路径
- **会话持久化** — 启动时恢复上次会话状态；标记开发脚本为运行中前会检测端口存活
- **立即停止** — 终止脚本时立即发送 `SIGINT + SIGTERM`，不留僵尸进程
- **安全退出** — 有活跃脚本运行时退出前会发出警告，并清理所有进程

## 截图

<div align="center">
  <img src="assets/screenshot.png" width="720" alt="Depot 截图" />
</div>

## 环境要求

- macOS 26 或更高版本
- 包含 `package.json` 的 pnpm / npm / yarn 工作区

## 构建

```bash
git clone https://github.com/lishiquann-cmyk/depot.git
cd depot
open Depot.xcodeproj
```

在 Xcode 中按 ⌘R 构建并运行。

> App Sandbox 已禁用以允许启动 Shell 子进程，详见 `Depot.entitlements`。

## 使用方法

1. 启动 Depot，点击 **添加项目** 选择一个 `package.json`
2. 脚本将自动按键名前缀分组归类
3. 切换开关启动开发脚本，服务就绪后 URL 将自动显示
4. 右键点击分类列表可添加自定义分类
5. 右键点击规则区域可添加日志提取规则

## 许可证

MIT
