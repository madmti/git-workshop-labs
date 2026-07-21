#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABS_DIR="$SCRIPT_DIR/labs"
DIST_DIR="$SCRIPT_DIR/dist"

mkdir -p "$DIST_DIR"

for dir in "$LABS_DIR"/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    tar -czf "$DIST_DIR/$name.tar.gz" -C "$LABS_DIR" "$name"
done
