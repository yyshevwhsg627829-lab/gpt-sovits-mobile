#!/bin/sh
# ============================================================
# GPT-SoVITS Mobile - 安装并修补 genie_tts
# 用法: sh setup/03_patch_genie_tts.sh
# ============================================================
set -e
R=${DEBIAN_ROOTFS:-/var/minis/workspace/debian/rootfs}
SP=$R/usr/local/lib/python3.11/dist-packages

echo "[1/3] 安装 genie_tts (检查是否已装)..."
if [ ! -d "$SP/genie_tts" ]; then
  pip download --no-deps -d /tmp/gsvd -i https://mirrors.aliyun.com/pypi/simple/ genie-tts
  for w in /tmp/gsvd/genie_tts*.whl; do unzip -q -o "$w" -d $SP; done
fi

echo "[2/3] 绕过 Server 模块 (推理不需要 fastapi/uvicorn)..."
cd "$SP/genie_tts"
[ -f __init__.py.bak ] || cp __init__.py __init__.py.bak
sed -i 's/^from \.Server import start_server/# from .Server import start_server/' __init__.py

echo "[3/3] 替换 jieba_fast -> jieba (纯 Python, aarch64 可用)..."
grep -rln "jieba_fast" "$SP/genie_tts/" | while read f; do
  sed -i 's/jieba_fast/jieba/g' "$f"
  echo "  已改: $f"
done

echo
echo "✅ genie_tts 就绪！"
echo "验证: sh setup/04_verify.sh"