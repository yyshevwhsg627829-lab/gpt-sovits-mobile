# GitHub 发布指南（复制粘贴即用）

## 1️⃣ 创建仓库

打开 https://github.com/new ，按下面填写：

**Repository name**
```
gpt-sovits-mobile
```

**Description**（仓库简介，会显示在搜索结果里）
```
Run GPT-SoVITS voice cloning TTS fully offline on your Android phone (PRoot sandbox, ONNX CPU inference). No PC, no GPU, no cloud. 中文语音克隆合成，手机本地离线跑通。
```

**选择 Public**，不要勾选任何 "Initialize" 选项（不要 README / .gitignore / license，我们已经带了）。

**Topics**（仓库创建后，右侧 ⚙️ About 里添加）
```
gpt-sovits, tts, voice-cloning, onnx, android, termux, proot, offline, speech-synthesis, luo-tianyi, chinese-tts, edge-ai
```

---

## 2️⃣ 上传文件

仓库页面点 **"uploading an existing file"** 链接，
把 `gpt-sovits-mobile/` 文件夹里的**全部内容**拖进去（README.md、gsv_mobile.py、setup/、samples/、py.sh、LICENSE），
注意是拖**文件夹里的东西**，不是拖外层文件夹本身（否则会多一层目录）。

Commit message 填：
```
feat: GPT-SoVITS 手机本地离线 TTS 完整方案
```

> 💡 samples/lty_first_local.wav 只有 184KB，直接上传没问题，它是最有说服力的效果展示。

---

## 3️⃣ 首个 Release（可选但推荐）

发布后进 **Releases → Create a new release**：

**Tag**: `v1.0.0`　**Title**: `v1.0.0 首个版本 · 洛天依示例`

**Release Notes**：
```markdown
## 🎉 GPT-SoVITS Mobile 首个版本

在 Android 手机沙盒（Alpine PRoot / Termux）中完全离线跑通 GPT-SoVITS 语音合成。

### ✅ 已验证
- 洛天依模型：pth+ckpt → ONNX 转换（约 20 秒）
- 手机端合成 2.88 秒中文语音（32000Hz），见 samples/
- 全流程零编译：全部依赖使用 manylinux aarch64 预编译 wheel

### 📦 包含
- 一键环境脚本（依赖 → 资源下载 → 修补 → 自检）
- 7 个关键踩坑记录（jieba_fast 替代 / LFS polyphonic / URL 括号编码 等）

### 🚀 快速开始
见 README.md，四条命令完成环境搭建。
```

---

## 4️⃣ 社区宣传文案（任选）

### B站 / 贴吧 / 论坛短帖
```
【突破】安卓手机本地跑 GPT-SoVITS 语音克隆，全离线！

不需要电脑、不需要显卡、不需要联网调用 API——
一部安卓手机，在沙盒里用 ONNX 推理把 GPT-SoVITS 完整跑通了。

洛天依模型实测：pth+ckpt 转 ONNX 仅 20 秒，合成 2.88 秒中文语音约 1 分钟。
原理：musl 沙盒套 Debian glibc rootfs + onnxruntime CPU 推理，
所有坑（jieba_fast 无 aarch64 轮子、LFS 模型文件、libsndfile…）都写成了脚本。

开源地址：github.com/<你的用户名>/gpt-sovits-mobile
四条命令完成环境搭建，换任何 GPT-SoVITS 模型都能用。
```

### V2EX / 长文开头
```
起因是想在手机上用洛天依的声音做点东西，但 GPT-SoVITS 官方要求 PC + 显卡，
云端 API 又都要联网上传文本。索性研究了一遍它的推理结构，发现核心就是
几个 ONNX 模型：RoBERTa（BERT 韵律）+ CN-HuBERT（参考音频特征）+ VITS/T2S。

于是做了一套方案：在 Android 的 PRoot 沙盒里套一层 Debian glibc rootfs，
Python 3.11 + onnxruntime 1.22（aarch64 manylinux wheel，免编译）跑 genie_tts
封装的推理流程。模型下载约 1.3GB，合成一条 3 秒语音约 1 分钟，完全离线。

踩坑记录都写进了 README 和一键脚本，欢迎试用/提 issue：
github.com/<你的用户名>/gpt-sovits-mobile
```

### Twitter/X / 朋友圈一句话
```
在安卓手机上完全离线跑通了 GPT-SoVITS 语音克隆🤯 无 PC 无 GPU，ONNX CPU 推理，洛天依实测 OK，方案已开源：github.com/<你的用户名>/gpt-sovits-mobile
```

---

## 5️⃣ 后续维护小提示

- 收到 issue 说"缺文件/0 字节"→ 99% 是 polyphonic.pickle 没走 LFS 下载，指到 README 踩坑记录 ②
- 如果有人反馈 Termux 原生（非 PRoot）环境，提醒他必须先装 Debian rootfs
- 好用的第三方模型可以加到 README 做个 "Tested models" 表格
