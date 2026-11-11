#!/bin/sh
# ============================================================
# GPT-SoVITS Mobile - 下载 GenieData 预训练资源 (约 990MB)
# 用法: sh setup/02_download_geniedata.sh
# ============================================================
set -e
D=${GENIE_DATA_DIR:-/var/minis/workspace/luotianyi-rvc/genie_data}
mkdir -p "$D"
B="https://hf-mirror.com/jiangzhuo9357/gpt-sovits-v2pp-onnx/resolve/main/genie_data"
OFFICIAL="https://hf-mirror.com/High-Logic/Genie/resolve/main"

get() { # get <url> <output>
  [ -s "$2" ] && { echo "SKIP $(basename $2)"; return; }
  echo "下载 $1 ..."
  curl -sL --retry 3 -m 1800 "$1" -o "$2"
  echo "OK   $(basename $2) $(du -h "$2" | cut -f1)"
}

# --- 大模型 (从 v2pp-onnx 镜像仓库, 国内快) ---
get "$B/chinese-hubert-base/chinese-hubert-base.onnx"            "$D/chinese-hubert-base/chinese-hubert-base.onnx"
get "$B/chinese-hubert-base/chinese-hubert-base_weights_fp16.bin" "$D/chinese-hubert-base/chinese-hubert-base_weights_fp16.bin"
get "$B/RoBERTa/RoBERTa.onnx"                                     "$D/RoBERTa/RoBERTa.onnx"
get "$OFFICIAL/GenieData/speaker_encoder.onnx"                    "$D/speaker_encoder.onnx"

# --- tokenizer (官方仓库, 注意 RoBERTa 在 GenieData(Optional) 下, 括号要 URL 编码) ---
T="$OFFICIAL/GenieData%28Optional%29/RoBERTa/roberta_tokenizer"
get "$T/tokenizer_config.json"   "$D/RoBERTa/roberta_tokenizer/tokenizer_config.json"
get "$T/special_tokens_map.json" "$D/RoBERTa/roberta_tokenizer/special_tokens_map.json"
get "$T/tokenizer.json"          "$D/RoBERTa/roberta_tokenizer/tokenizer.json"
get "$T/vocab.txt"               "$D/RoBERTa/roberta_tokenizer/vocab.txt"

# --- G2P 中文词典 ---
get "$OFFICIAL/GenieData/G2P/ChineseG2P/opencpop-strict.txt" "$D/G2P/ChineseG2P/opencpop-strict.txt"
# polyphonic: 官方是 LFS 的 .pickle, 镜像仓库同名文件是空的, 必须走 LFS batch 接口
PICKLE="$D/G2P/ChineseG2P/polyphonic.pickle"
if [ ! -s "$PICKLE" ]; then
  echo "下载 polyphonic.pickle (LFS)..."
  python3 - "$PICKLE" <<'PYEOF'
import json, sys, os, urllib.request
out = sys.argv[1]
body = {"operation":"download","transfers":["basic"],"objects":[{
  "oid":"f425246160a32c578557cd3151cd0bb97f5f44c3aaf65e718dd2c3213c04fb4b","size":1322387}]}
req = urllib.request.Request(
  "https://hf-mirror.com/High-Logic/Genie.git/info/lfs/objects/batch",
  data=json.dumps(body).encode(),
  headers={"Accept":"application/vnd.git-lfs+json","Content-Type":"application/vnd.git-lfs+json"})
href = json.loads(urllib.request.urlopen(req, timeout=60).read())["objects"][0]["actions"]["download"]["href"]
urllib.request.urlretrieve(href, out)
print("OK polyphonic.pickle", os.path.getsize(out))
PYEOF
fi

echo
echo "✅ GenieData 下载完成！目录内容:"
find "$D" -type f -size +1k | sort
echo
echo "下一步: sh setup/03_patch_genie_tts.sh"