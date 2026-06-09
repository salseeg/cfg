#!/bin/bash
# Patches vim-lsp to respond to client/registerCapability requests.
# Without this, LSP servers that send registerCapability (e.g. Expert)
# block forever waiting for a response and never handle completions.
# See: https://github.com/prabirshrestha/vim-lsp/issues/598

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCH="$SCRIPT_DIR/vim-lsp-register-capability.patch"
TARGET="$HOME/.vim/plugged/vim-lsp"

if [ ! -d "$TARGET" ]; then
    echo "vim-lsp not found at $TARGET" >&2
    exit 1
fi

cd "$TARGET"

if grep -q "client/registerCapability" autoload/lsp.vim; then
    echo "Patch already applied."
    exit 0
fi

git apply "$PATCH"
echo "Patched vim-lsp: client/registerCapability handler added."
