#!/bin/sh
# Debian PyTorch 环境启动器
R=/var/minis/workspace/debian/rootfs
P=$R/usr/local/lib/python3.11/dist-packages
export PYTHONPATH=$P
export SSL_CERT_FILE=$R/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_DIR=$R/etc/ssl/certs
export HOME=/tmp
export TMPDIR=/tmp
export OMP_NUM_THREADS=8
export MKL_NUM_THREADS=8
exec $R/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1 \
  --library-path $R/lib/aarch64-linux-gnu:$R/usr/lib/aarch64-linux-gnu:$P/torch/lib:$P/torch.libs \
  $R/usr/bin/python3 "$@"
