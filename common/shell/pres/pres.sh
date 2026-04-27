#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: pres <directory_or_file> [zstd_level] [output_file]"
    echo "If output_file is omitted and stdout is a terminal, it defaults to <directory_or_file>.tar.zst"
    exit 1
fi

TARGET="${1%/}"
LEVEL="${2:-3}"

if [ -t 1 ]; then
    OUTPUT="${3:-${TARGET}.tar.zst}"
    echo "Archiving $TARGET to $OUTPUT (zstd level $LEVEL)..." >&2
    tar -I "zstd -T0 -$LEVEL" -cvf "$OUTPUT" "$TARGET"
else
    if [ $# -ge 3 ]; then
        tar -I "zstd -T0 -$LEVEL" -cvf "$3" "$TARGET"
    else
        tar -I "zstd -T0 -$LEVEL" -cvf - "$TARGET"
    fi
fi
