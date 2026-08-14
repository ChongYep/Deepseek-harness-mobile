#!/usr/bin/env bash
# 移动版 Harness —— 离线补丁安装器（在手机上 Termux 里跑）
#
# 作用：把本目录 12 个本地改动包（rc.7）装到全局——含"移动单栏外壳"（ui-layout）、
#       "Termux 原生依赖可选化"（sandbox-local/fs-local/jsonl/
#       directory-picker-native 的 koffi、attachment-local 的 sharp、
#       subprocess-local 的 node-pty），"插件 bundle 可缓存"（client-modules，
#       刷新不再重下全部插件），以及"工作区目录选择加固"（directory-picker-browse：
#       列举超时上限 + 弹窗重试按钮）。其余未改动包从公共 npm 拉 rc.6。
#       CLI 本体（@deepseek-ai/dsh）也从公共 npm 装 rc.6。
#
# 用法：把整个 install/ 文件夹拷到手机（共享存储 / 直接放 Termux 主目录），
#       cd 进该目录后执行：
#           bash install.sh
#
# 前置（未装过时）：
#           pkg update -y && pkg upgrade -y
#           pkg install -y nodejs-lts git bash

set -euo pipefail

# 切到脚本所在目录（tarball 和脚本在同一处）
cd "$(dirname "$(readlink -f "$0")")"

echo "== 前置检查 =="
command -v node >/dev/null 2>&1 || { echo "缺少 node：先跑 pkg install -y nodejs-lts"; exit 1; }
node -e "import('node:sqlite').then(()=>console.log('node:sqlite ok')).catch(()=>process.exit(1))" \
  || { echo "node:sqlite 不可用：先跑 pkg upgrade nodejs-lts（需 Node ^22.19 || >=24）"; exit 1; }

echo
echo "== 安装 CLI rc.6 + 12 个本地改动包 rc.7 =="
echo "   （koffi/sharp/node-pty 的原生编译警告是预期且无害的，安装会继续）"
npm install --global \
  "@deepseek-ai/dsh@0.1.0-rc.6" \
  ./deepseek-ai-dsh-client-ui-layout-0.1.0-rc.7.tgz \
  ./deepseek-ai-dsh-subprocess-local-0.1.0-rc.7.tgz \
  ./deepseek-ai-dsh-terminal-bash-0.1.0-rc.7.tgz \
  ./deepseek-ai-dsh-sandbox-0.1.0-rc.7.tgz \
  ./deepseek-ai-dsh-sandbox-local-0.1.0-rc.7.tgz \
  ./deepseek-ai-dsh-fs-local-0.1.0-rc.7.tgz \
  ./deepseek-ai-dsh-session-persistence-jsonl-0.1.0-rc.7.tgz \
  ./deepseek-ai-dsh-attachment-local-0.1.0-rc.7.tgz \
  ./deepseek-ai-dsh-host-directory-picker-native-0.1.0-rc.7.tgz \
  ./deepseek-ai-dsh-client-modules-0.1.0-rc.7.tgz \
  ./deepseek-ai-dsh-host-directory-picker-browse-0.1.0-rc.7.tgz \
  ./deepseek-ai-dsh-client-ui-directory-picker-browse-0.1.0-rc.7.tgz

echo
echo "== 校验覆盖生效 =="
GMP="${PREFIX:-/data/data/com.termux/files/usr}/lib/node_modules/@deepseek-ai"
node -e "
const gmp = process.argv[1];
const pkgs = ['dsh-client-ui-layout','dsh-subprocess-local','dsh-terminal-bash','dsh-sandbox','dsh-sandbox-local','dsh-fs-local','dsh-session-persistence-jsonl','dsh-attachment-local','dsh-host-directory-picker-native','dsh-client-modules','dsh-host-directory-picker-browse','dsh-client-ui-directory-picker-browse'];
let bad = 0;
for (const name of pkgs) {
  const p = require(gmp + '/' + name + '/package.json');
  const ok = p.version === '0.1.0-rc.7';
  if (!ok) bad++;
  console.log((ok ? 'OK ' : 'ERR') + ' ' + name + ' @ ' + p.version);
}
if (bad > 0) { console.error('错误：' + bad + ' 个本地包未覆盖到 rc.7'); process.exit(1); }
console.log('OK：12 个本地改动包已就位（移动外壳 + 原生依赖可选化 + 插件缓存 + 目录选择加固）');
" "$GMP"

echo
cat <<'EOF'
== 下一步：启动移动版 agent ==

  export DSH_HOME="$HOME/.dsh"
  export DSH_PERMISSION_MODE=danger-full-access
  export DSH_TELEMETRY_DISABLED=1
  node --expose-internals /data/data/com.termux/files/usr/lib/node_modules/@deepseek-ai/dsh/lib/bin.js web --port 3080

然后手机浏览器打开 http://127.0.0.1:3080 —— 视口 <=767px 自动渲染移动单栏外壳
（顶栏汉堡开侧栏抽屉、右侧详情抽屉、底部固定输入框）。

  - 保活：termux-wake-lock；建议在 tmux 里跑（Ctrl-b d 分离 / tmux attach 重连）
  - 安全：agent 无鉴权但只绑 127.0.0.1，不要加 --host 0.0.0.0
EOF
