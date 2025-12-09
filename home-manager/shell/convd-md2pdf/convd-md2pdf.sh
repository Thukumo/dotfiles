if [ -z "$1" ]; then
  echo ディレクトリへのパスを引数として与えてください。
  exit 1
fi
if [ -d "$1" ]; then
  parallel "pandoc {} --pdf-engine typst -V \"mainfont=DejaVu Serif\" -o {.}.pdf" ::: "${1%/}"/*.md
else
  echo ディレクトリではありません。
  exit 2
fi

