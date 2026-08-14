# 移动版 DeepSeek Harness

把 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 这个 agent **跑在你的安卓手机上** —— 一个酒馆（SillyTavern）式的移动聊天界面，底下是真正在本机读文件、跑命令、改代码的 agent。全程不经过云端：agent、你的文件、模型 API key 都留在手机本地。

[English](README.md) | 中文

> **提醒 —— 这不是一个原生 App。** 它以**网页**形式在手机浏览器里启动，agent 本体跑在手机上的 [Termux](https://termux.dev/) 里。没有独立的 APK —— Termux 必须保持运行，agent 才能访问。

## 这是什么

DeepSeek Harness 是一个本地 AI 编程 agent。这个项目是它的 **安卓发行版**：agent 内核跑在手机上的 [Termux](https://termux.dev/) 里，你用手机浏览器打开 `http://127.0.0.1:3080` 和它对话。

手机视口（≤ 767 px）下，网页自动切成单栏移动外壳 —— 侧栏和会话详情以抽屉滑入 —— 而不是桌面的三栏布局。会话内容占满屏幕，输入框固定在底部。

## 截图

| 移动聊天界面 | 侧栏抽屉 | 详情抽屉 |
| --- | --- | --- |
| ![移动聊天](01-base.png) | ![侧栏](02-sidebar.png) | ![详情](03-details.png) |

## 为什么跑在本地

- **隐私** —— 你的文件和模型 API key 不出手机。
- **无云端服务器** —— agent 完全本地，没有订阅，也没有需要信任的常驻服务器。
- **只绑回环** —— Web RPC 本身无鉴权，但它只监听 `127.0.0.1`，手机浏览器与它共享同一设备回环，不会暴露到局域网。

## 环境要求

- 一台 **arm64-v8a** 的安卓手机，**8 GB+ 内存**（旗舰 SoC 跑起来很轻松——内核是纯 JavaScript 加内置 `node:sqlite`）。
- 从 **F-Droid** 安装 [Termux](https://termux.dev/)（Play 商店版过时）。

## 安装

1. 装基础包和 CLI：

   ```sh
   pkg update -y && pkg upgrade -y
   pkg install -y nodejs-lts git bash
   npm install --global @deepseek-ai/dsh
   ```

   `node-pty`（一个可选原生插件）在 Termux 上可能打印一条原生编译警告 —— 这是**预期的、无害的**，安装会继续。

2. 把本仓库的 `install/` 文件夹拷到手机，然后跑补丁安装器：

   ```sh
   cd install
   bash install.sh
   ```

   安装器会把移动外壳和安卓运行时补丁（原生依赖可选化、文件系统回退、目录选择超时 + 重试）以本地 `0.1.0-rc.7` 包的形式覆盖到已发布的 CLI 之上。

## 启动

```sh
export DSH_HOME="$HOME/.dsh"
export DSH_PERMISSION_MODE=danger-full-access
export DSH_TELEMETRY_DISABLED=1
node --expose-internals \
  /data/data/com.termux/files/usr/lib/node_modules/@deepseek-ai/dsh/lib/bin.js \
  web --port 3080
```

手机浏览器打开 `http://127.0.0.1:3080`，在 Models 页填上模型 API key，新建会话，发一条命令试试 —— 比如 *「用 bash 打印设备型号」*。

## 安全

- **只绑回环。** Web RPC 本质是远程执行界面，且**无鉴权**。它只监听 `127.0.0.1`，与手机浏览器共享设备回环，不监听局域网。**不要**加 `--host 0.0.0.0`。
- **`DSH_PERMISSION_MODE=danger-full-access`。** 安卓没有 `bwrap`/Landlock/Seatbelt/ACL 沙箱后端，沙箱默认 fail-closed。启动器显式选择非受限运行 —— 把 agent 当 shell 访问对待。
- **`DSH_TELEMETRY_DISABLED=1`** 默认关闭会话遥测。

## 本项目相对上游补了什么

这个发行版在 `deepseek-ai/deepseek-harness` 之上打了一小组自包含的补丁，让它能在安卓上装得上、跑得起来：

- **移动单栏外壳**（`client/ui-layout`）—— 一个视口条件分支，复用现有的布局 store，不引入移动端专属状态。
- **原生依赖可选化** —— `koffi`、`sharp` 移入 `optionalDependencies` 并懒加载，`node-pty` 在安卓上报干净的 `TerminalUnavailableError`，让没有预编译二进制的平台上 `npm install -g` 也能成功。
- **安卓文件系统回退** —— 安卓的 FUSE/SELinux 拒绝 `link(2)` 硬链接，会话日志、write 工具、附件存储回退到 `rename()` / `copyFile(COPYFILE_EXCL)`。
- **目录选择超时 + 重试** —— 目录列举有界超时，失败返回可重试错误并给一键重试按钮，存储卡顿不会挂死请求。
- **插件 bundle 缓存** —— 客户端插件以 `immutable` 缓存（URL 带内容哈希 rev），刷新不再重下整个插件图。
- **HMR 需要 `--expose-internals`** —— 启动器传入该标志，让 HMR 服务在安卓上正常挂载。
- **`$PREFIX/bin/bash`** —— 终端 shell 路径在安卓上自动替换。

## 保活

- `termux-wake-lock`（来自 `termux-api`）保持 CPU 唤醒。
- 在 `tmux` 里跑，避免误滑走 Termux 导致 agent 退出：`tmux` → `dsh-web` → `Ctrl-b d` 分离，`tmux attach` 回来。

## 致谢

基于 [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) 的 fork，沿用上游相同的许可证。
