if [ -z $1 ]; then
  echo ディレクトリへのパスを引数として与えてください。
  exit 1
fi
if [ -d $1 ]; then
  mainfont="${CONVD_MD2PDF_MAINFONT:-DejaVu Serif}"
  parallel "pandoc {} --pdf-engine typst -V \"mainfont=$mainfont\" -o {.}.pdf" ::: ${1%/}/*.md
else
  echo ディレクトリではありません。
  exit 2
fi

