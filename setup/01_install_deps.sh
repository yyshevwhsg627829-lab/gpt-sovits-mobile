#!/bin/sh
# ============================================================
# GPT-SoVITS Mobile - 一键环境安装脚本
# 在 Alpine/PRoot 沙盒的 Debian glibc rootfs 里安装全部依赖
# 用法: sh setup/01_install_deps.sh
# ============================================================
set -e

echo "[1/6] 检查 Debian rootfs..."
R=${DEBIAN_ROOTFS:-/var/minis/workspace/debian/rootfs}
[ -d "$R" ] || { echo "错误: 找不到 Debian rootfs ($R)"; exit 1; }
SP=$R/usr/local/lib/python3.11/dist-packages
PY=/var/minis/workspace/debian/py.sh

echo "[2/6] 安装纯 Python / wheel 依赖..."
pip download --no-deps -d /tmp/gsvd \
  --only-binary :all: --python-version 311 --implementation cp \
  --abi cp311 --platform manylinux2014_aarch64 \
  -i https://mirrors.aliyun.com/pypi/simple/ \
  cffi soxr pydantic_core 2>/dev/null
pip download --no-deps -d /tmp/gsvd -i https://mirrors.aliyun.com/pypi/simple/ \
  uvicorn fastapi starlette pydantic typing_extensions \
  annotated_types click pypinyin g2pM tokenizers numpy pyyaml onnx \
  huggingface_hub 2>/dev/null
for w in /tmp/gsvd/*.whl; do unzip -q -o "$w" -d $SP; done

echo "[3/6] 安装 onnxruntime (manylinux aarch64)..."
pip download --no-deps -d /tmp/gsvd --only-binary :all: \
  --python-version 311 --implementation cp --abi cp311 \
  --platform manylinux_2_27_aarch64 -i https://mirrors.aliyun.com/pypi/simple/ \
  onnxruntime==1.22.1 2>/dev/null || \
pip download --no-deps -d /tmp/gsvd --only-binary :all: \
  --python-version 311 --implementation cp --abi cp311 \
  --platform manylinux2014_aarch64 -i https://mirrors.aliyun.com/pypi/simple/ \
  onnxruntime==1.22.1
for w in /tmp/gsvd/onnxruntime*.whl; do unzip -q -o "$w" -d $SP; done

echo "[4/6] 安装 jieba (替代 jieba_fast, 纯 Python)..."
pip download --no-deps -d /tmp/gsvd -i https://mirrors.aliyun.com/pypi/simple/ jieba
tar xzf /tmp/gsvd/jieba-*.tar.gz -C /tmp/
cp -r /tmp/jieba-*/jieba $SP/

echo "[5/6] 安装 libsndfile (从 Debian .deb 解包)..."
DEB=/tmp/gsvd/libsndfile1.deb
curl -sL "https://mirrors.aliyun.com/debian/pool/main/libs/libsndfile/libsndfile1_1.2.0-1+deb12u1_arm64.deb" -o $DEB
mkdir -p /tmp/gsvd/sfx && cd /tmp/gsvd/sfx && ar x $DEB && tar xf data.tar.* -C . 2>/dev/null
cp -a usr/lib/aarch64-linux-gnu/* $R/usr/lib/aarch64-linux-gnu/
ln -sf libsndfile.so.1 $R/usr/lib/aarch64-linux-gnu/libsndfile.so

echo "[6/6] 修补 genie_tts (绕过 Server / 替换 jieba_fast)..."
# genie_tts 会在下一步 setup/02_download_geniedata.sh 安装
# 这里只做通用修补占位；顺序请按 README 执行

echo
echo "✅ 依赖安装完成！下一步: sh setup/02_download_geniedata.sh"