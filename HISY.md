# hisy-tech/zen-go

Temporary fork of [gorules/zen-go](https://github.com/gorules/zen-go), used by
hisy-core through a `replace` directive until upstream fixes
[gorules/zen-go#76](https://github.com/gorules/zen-go/issues/76).

## What is different from upstream

Only the prebuilt Rust archives `deps/{darwin,linux}_{amd64,arm64}/libzen_ffi.a`.
They are the archives of upstream tag `v0.20.0` with the embedded LLVM bitcode
removed:

- ELF (linux): sections `.llvmbc` and `.llvmcmd`
- Mach-O (darwin): sections `__LLVM,__bitcode` and `__LLVM,__cmdline`

Go 1.26.11 and 1.27.4 refuse to link cgo inputs that carry LTO bitcode
(`disallowed LTO section` in `cmd/go/internal/work/security.go`). The bitcode is
not used by a normal link, so removing it leaves the machine code untouched.
The Go sources, `go.mod` (still `module github.com/gorules/zen-go`) and the
Windows archive are upstream's, unchanged.

## Verifying

`hisy/strip-bitcode.sh` rebuilds the four archives from the upstream tag with a
pinned image and a pinned `llvm-objcopy`; the output is byte-for-byte
reproducible. The `Verify stripped archives` workflow runs it, fails if the
committed archives differ, and runs the upstream tests with Go 1.26.11.

## Tags

`v0.20.1-0.hisy.N`: upstream `v0.20.0` plus this change. The pre-release
suffix sorts before `v0.20.1`, so an upstream release always wins.

## Removing

When upstream publishes archives without bitcode: drop the `replace` of
`github.com/gorules/zen-go` from hisy-core, upgrade zen-go there, and archive
this repository.
