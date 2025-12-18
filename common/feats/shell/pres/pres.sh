tar cvf - "$1" | zstd -T0 -"${2:-3}"
