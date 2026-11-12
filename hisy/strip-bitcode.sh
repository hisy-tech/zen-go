#!/bin/sh
# Rebuilds deps/<platform>/libzen_ffi.a from the upstream tag without the
# embedded LLVM bitcode that Go >= 1.26.11 / 1.27.4 refuses to link
# (https://github.com/gorules/zen-go/issues/76). Nothing else is changed: only
# the bitcode sections are removed, and the output is reproducible because the
# tool runs in a pinned image with a pinned llvm-objcopy.
#
# Usage: hisy/strip-bitcode.sh   (from the repository root; needs git and docker)
set -eu

UPSTREAM_TAG=v0.20.0
IMAGE=debian:bookworm-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2c422d96a961d3376b179bc
LLVM_PACKAGE=llvm-14=1:14.0.6-12

cd "$(git rev-parse --show-toplevel)"

for platform in darwin_amd64 darwin_arm64 linux_amd64 linux_arm64; do
  git show "$UPSTREAM_TAG:deps/$platform/libzen_ffi.a" > "deps/$platform/libzen_ffi.a"
done

docker run --rm --platform linux/amd64 -v "$PWD/deps:/deps" "$IMAGE" sh -euc "
  apt-get update -qq >/dev/null
  apt-get install -y -qq --no-install-recommends '$LLVM_PACKAGE' >/dev/null
  objcopy=/usr/lib/llvm-14/bin/llvm-objcopy
  for platform in linux_amd64 linux_arm64; do
    \$objcopy --remove-section=.llvmbc --remove-section=.llvmcmd /deps/\$platform/libzen_ffi.a
  done
  for platform in darwin_amd64 darwin_arm64; do
    \$objcopy --remove-section=__LLVM,__bitcode --remove-section=__LLVM,__cmdline /deps/\$platform/libzen_ffi.a
  done
"

sha256sum deps/*/libzen_ffi.a 2>/dev/null || shasum -a 256 deps/*/libzen_ffi.a
