# GPT-SoVITS Mobile 🐟

**在 Android 手机沙盒（Alpine PRoot）里，完全离线跑通 GPT-SoVITS 语音合成。**

无需电脑、无需云服务器、无需 GPU —— 一部 Android 手机 + Termux/Minis 类沙盒环境即可。
本项目以「洛天依」语音模型为例，换任意 GPT-SoVITS 模型只需改路径。

> 🎧 成果示例：`samples/lty_first_local.wav`（2.88 秒，32000Hz，完全在手机端合成）

---

## ✨ 特性

- **全离线推理**：模型下载好后合成不依赖网络
- **手机级资源占用**：ONNX 推理（非 PyTorch），峰值内存约 2~3GB
- **免编译依赖**：全部依赖用 manylinux aarch64 预编译 wheel，不用装 gcc
- **绕坑脚本化**：踩过的坑全部写进一键脚本，按顺序执行即可

## 📦 项目结构

```
gpt-sovits-mobile/
├── README.md                    ← 你在这里
├── gsv_mobile.py                ← 主脚本（模型转换 + TTS 合成）
├── setup/
│   ├── 01_install_deps.sh       ← 安装全部 Python 依赖
│   ├── 02_download_geniedata.sh ← 下载 GenieData 预训练资源（约 990MB）
│   ├── 03_patch_genie_tts.sh    ← 安装并修补 genie_tts
│   └── 04_verify.sh             ← 环境自检
├── py.sh                        ← Debian rootfs Python 启动器（示例）
└── samples/
    └── lty_first_local.wav      ← 手机端合成效果示例
```

## 🧩 原理

```
┌─────────────────────────────────────────────────────┐
│  Android 手机                                        │
│  ┌───────────────────────────────────────────────┐  │
│  │  PRoot 沙盒 (Alpine musl)                      │  │
│  │  ┌─────────────────────────────────────────┐  │  │
│  │  │  Debian glibc rootfs (Python 3.11)      │  │  │
│  │  │  genie_tts (GPT-SoVITS 推理封装)         │  │  │
│  │  │   ├─ RoBERTa.onnx        (BERT 韵律)     │  │  │
│  │  │   ├─ CN_HuBERT.onnx      (音频特征)      │  │  │
│  │  │   ├─ speaker_encoder.onnx (音色校验)     │  │  │
│  │  │   └─ 角色模型 (lty_onnx/, 9 个 ONNX)     │  │  │
│  │  │  onnxruntime 1.22 (CPU, aarch64)        │  │  │
│  │  └─────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

关键设计：**musl 沙盒里套一层 Debian glibc rootfs**，Python 及所有带 C 扩展的包
（onnxruntime / cffi / soxr）都跑在 glibc 环境，用 `ld-linux-aarch64.so.1
--library-path` 直接启动，不需要 chroot 权限。

## 🚀 快速开始

### 0. 前置条件

- 一个可用的 Debian glibc rootfs（Python 3.11），且有对应的 `py.sh` 启动器
- 磁盘空间 ≥ 2GB（GenieData 990MB + 角色模型 330MB + 依赖）
- 能访问 `hf-mirror.com`（HuggingFace 国内镜像）

### 1. 安装依赖 + 下载资源

```bash
sh setup/01_install_deps.sh        # Python 依赖
sh setup/02_download_geniedata.sh  # GenieData 预训练资源 (~990MB)
sh setup/03_patch_genie_tts.sh     # genie_tts 安装修补
sh setup/04_verify.sh              # 自检，全部 ✅ 才继续
```

### 2. 准备角色模型

下载任意 GPT-SoVITS 模型（需要 `.pth` + `.ckpt` + 一段参考音频 `.wav`）。
以洛天依为例（HuggingFace 搜 `洛天依 GPT-SoVITS`）：

```
洛天依..._e8_s384.pth    172MB   (SoVITS 声音模型)
洛天依...-e15.ckpt       155MB   (GPT 文本模型)
洛天依....wav            189KB   (参考音频, 3~10 秒清晰人声)
```

### 3. 转换 + 合成

```bash
# 3.1 把 pth/ckpt 转成 ONNX（只需一次，约 20 秒）
python3 gsv_mobile.py convert 洛天依.pth 洛天依.ckpt ./lty_onnx

# 3.2 合成语音
python3 gsv_mobile.py tts ./lty_onnx 参考音频.wav \
    "我现在需要一个长达三秒的语音" \
    "你好呀，我是洛天依，很高兴认识你" \
    output.wav
```

> ⚠️ 参考文本必须与参考音频实际说的内容一致，这直接影响合成质量。

## 🕳️ 踩坑全记录（重要！）

### ① jieba_fast 没有 aarch64 wheel
`jieba_fast` 的 C 扩展无法在 musl/aarch64 编译。
**解法**：装纯 Python `jieba`，然后 `sed -i 's/jieba_fast/jieba/g'` 批量替换
genie_tts 源码里的 import（3 个文件）。分词速度稍慢但功能一致。

### ② polyphonic 文件名是 `.pickle` 不是 `.json`
官方 GenieData 仓库里是 LFS 存储的 `polyphonic.pickle`（1.3MB dict）。
部分镜像仓库把它存成 0 字节的 `.json` —— 下载回来根本不能用！
**解法**：走 Git LFS batch 接口拿真实下载地址（脚本已内置），
下载后命名为 `polyphonic.pickle` 放到 `genie_data/G2P/ChineseG2P/`。

### ③ RoBERTa tokenizer 藏在 `GenieData(Optional)` 目录
官方仓库结构是 `GenieData/` 和 `GenieData(Optional)/` 两棵树，
tokenizer 文件在后者，且**目录名里的括号必须 URL 编码**成 `%28 %29`。

### ④ libsndfile 要 glibc 版
Alpine 的 musl libsndfile 与 Python cffi 加载方式不兼容。
**解法**：从 Debian 仓库下载 `libsndfile1_arm64.deb` 解包，
并建软链 `libsndfile.so -> libsndfile.so.1`（soundfile 硬编码找无版本号的 .so）。

### ⑤ Server 模块连带 fastapi 依赖链
`genie_tts/__init__.py` 顶层 `from .Server import start_server` 会拉起
fastapi→annotated_doc 一长串依赖，推理根本用不到。
**解法**：注释掉这一行即可（`03_patch_genie_tts.sh` 已处理）。

### ⑥ GPU device discovery 报错是正常的
`onnxruntime` 启动时报
`GPU device discovery failed: Permission denied, "/sys/class/drm"`
—— 沙盒没有 GPU 权限，**这是正常警告**，CPU 推理照常进行，忽略即可。

### ⑦ sounddevice 缺失不影响合成
播放功能的警告可以无视，wav 文件照常写出。

## ⚡ 性能参考

在骁龙 8 级别 SoC（8 线程）上的实测：

| 阶段 | 耗时 |
|------|------|
| pth+ckpt → ONNX 转换 | ~20 秒（一次） |
| 角色加载（首次） | ~40 秒 |
| 合成 2.88 秒语音 | ~60 秒 |

## ❓ FAQ

**Q: 能换别的声音吗？**
A: 能。任何 GPT-SoVITS 格式的 `.pth` + `.ckpt` 模型都行，转换和合成流程完全相同。

**Q: 能实时变声吗？**
A: 本项目是离线合成（TTS），不是实时变声（VC）。实时方案参考 RVC 类项目。

**Q: 为什么不直接用 PyTorch？**
A: aarch64 + musl 没有 torch wheel；即使套 glibc，加载大模型会把低内存设备拖死。
ONNX Runtime CPU 推理是手机端的最优解。

**Q: iOS / 电脑能用吗？**
A: 电脑直接用官方 GPT-SoVITS 即可；iOS 沙盒限制更严，未测试。

## 📜 致谢

- [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS) — RVC-Boss
- [genie-tts](https://pypi.org/project/genie-tts/) — GPT-SoVITS 的 ONNX 推理封装
- [High-Logic/Genie](https://huggingface.co/High-Logic/Genie) — GenieData 预训练资源
- 洛天依模型 — B站「只想干饭的麦克斯韦妖」制作
- [hf-mirror.com](https://hf-mirror.com) — HuggingFace 国内镜像

## License

MIT
