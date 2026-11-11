#!/usr/bin/env python3
# ============================================================
# GPT-SoVITS Mobile - 模型转换 + 语音合成 一体化脚本
# 用法:
#   python3 gsv_mobile.py convert <model.pth> <model.ckpt> <输出目录>
#   python3 gsv_mobile.py tts <onnx目录> <参考音频> <参考文本> <要合成的文本> <输出.wav>
# ============================================================
import os, sys

DATA_DIR = os.environ.get("GENIE_DATA_DIR",
    "/var/minis/workspace/luotianyi-rvc/genie_data")
os.environ["GENIE_DATA_DIR"] = DATA_DIR

import genie_tts as genie


def convert(pth, ckpt, out_dir):
    """把 GPT-SoVITS 的 .pth + .ckpt 转成 ONNX（只转换一次，之后可复用）"""
    os.makedirs(out_dir, exist_ok=True)
    print("开始转换（首次约 20 秒）...", flush=True)
    genie.convert_to_onnx(
        torch_pth_path=pth,
        torch_ckpt_path=ckpt,
        output_dir=out_dir,
    )
    total = 0
    for f in sorted(os.listdir(out_dir)):
        sz = os.path.getsize(os.path.join(out_dir, f))
        total += sz
        print(f"  {f:44s} {sz/1e6:8.1f} MB")
    print(f"转换完成! 共 {total/1e6:.0f} MB → {out_dir}")


def tts(onnx_dir, ref_audio, ref_text, text, save_path,
        character="voice", language="zh"):
    """加载角色 → 设置参考音频 → 合成语音"""
    print(f"[1/3] 加载角色 ({character})...", flush=True)
    genie.load_character(
        character_name=character,
        onnx_model_dir=onnx_dir,
        language=language,
    )
    print(f"[2/3] 设置参考音频: {ref_audio}", flush=True)
    genie.set_reference_audio(
        character_name=character,
        audio_path=ref_audio,
        audio_text=ref_text,
    )
    print(f"[3/3] 合成: 「{text}」", flush=True)
    genie.tts(
        character_name=character,
        text=text,
        save_path=save_path,
    )
    sz = os.path.getsize(save_path)
    print(f"✅ 合成完成 → {save_path} ({sz/1024:.0f} KB)")


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "convert":
        if len(sys.argv) != 5: sys.exit(__doc__)
        convert(sys.argv[2], sys.argv[3], sys.argv[4])
    elif cmd == "tts":
        if len(sys.argv) != 7: sys.exit(__doc__)
        tts(*sys.argv[2:7])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()