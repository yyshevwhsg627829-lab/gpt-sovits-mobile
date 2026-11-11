#!/bin/sh
# ============================================================
# GPT-SoVITS Mobile - 环境自检
# 用法: sh setup/04_verify.sh
# ============================================================
R=${DEBIAN_ROOTFS:-/var/minis/workspace/debian/rootfs}
PY=${PY_LAUNCHER:-/var/minis/workspace/debian/py.sh}
D=${GENIE_DATA_DIR:-/var/minis/workspace/luotianyi-rvc/genie_data}

cat > /tmp/gsv_verify.py <<EOF
import os
os.environ["GENIE_DATA_DIR"] = "$D"
ok = True
for mod in ["onnxruntime", "soundfile", "soxr", "pypinyin", "g2pM", "jieba"]:
    try:
        __import__(mod); print("  ✅", mod)
    except Exception as e:
        print("  ❌", mod, e); ok = False
try:
    import genie_tts as genie
    print("  ✅ genie_tts", end=" ")
    fn = [x for x in dir(genie) if not x.startswith("_")]
    assert "tts" in fn and "load_character" in fn
    print("(tts/load_character 可用)")
except Exception as e:
    print("  ❌ genie_tts:", e); ok = False

import genie_tts.Core.Resources as R
for name, path in [("hubert", "chinese-hubert-base/chinese-hubert-base.onnx"),
                   ("RoBERTa", "RoBERTa/RoBERTa.onnx"),
                   ("tokenizer", "RoBERTa/roberta_tokenizer/tokenizer.json"),
                   ("G2P", "G2P/ChineseG2P/polyphonic.pickle"),
                   ("speaker_encoder", "speaker_encoder.onnx")]:
    p = os.path.join("$D", path)
    if os.path.getsize(p) > 1000 if os.path.exists(p) else False:
        print("  ✅", name, round(os.path.getsize(p)/1e6,1), "MB")
    else:
        print("  ❌", name, "缺失或为空"); ok = False
print()
print("🎉 环境自检通过！可以跑 03_convert_and_tts 了" if ok else "❌ 有缺失项，按提示补齐")
EOF
$PY /tmp/gsv_verify.py