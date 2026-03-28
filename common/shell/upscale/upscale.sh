set -euo pipefail

usage() {
  cat <<'EOF'
Usage: upscale [options]

Options:
  --list-shaders               List available Anime4K shader names and exit
  --file PATH                  Single-file mode input (exclusive with --in-dir/--out-dir)
  --in-dir PATH                Input directory (required unless --file is used)
  --out-dir PATH               Output directory (required unless --file is used)
  --shader NAME                Anime4K shader file name (default: Anime4K_Upscale_CNN_x2_M.glsl)
  --cq N                       Constant quality (default: 24)
  --mode MODE                  fast|anime4k|auto (fast=CUDA only, auto=Anime4K->CUDA)
  --codec NAME                 Encoder codec (default: hevc_nvenc)
  --preset NAME                Encoder preset (default: p3)
  --bit-depth MODE             Output bit depth: auto|8|10 (default: auto)
  --width N                    Output width (default: 3840)
  --height N                   Output height (default: 2160)
  --vulkan-device-index N      Vulkan device index (default: 1)
  --decode-hw MODE             auto | sw | vulkan | cuda (default: auto)
  --prime-offload              Enable NVIDIA PRIME offload env vars
  --no-prime-offload           Disable NVIDIA PRIME offload env vars
  -w N                         Alias of --width
  -h N                         Alias of --height
  --help                       Show this help
EOF
}

require_arg() {
  local flag="$1"
  local value="${2:-}"
  if [[ -z "$value" ]]; then
    echo "Missing value for $flag" >&2
    exit 1
  fi
}

CLI_IN_DIR=""
CLI_OUT_DIR=""
CLI_FILE=""
CLI_SHADER=""
CLI_CQ=""
CLI_UPSCALE_MODE=""
CLI_NVENC_CODEC=""
CLI_NVENC_PRESET=""
CLI_BIT_DEPTH_MODE=""
CLI_TARGET_W=""
CLI_TARGET_H=""
CLI_VULKAN_DEVICE_INDEX=""
CLI_DECODE_HW=""
CLI_USE_PRIME_OFFLOAD=""
CLI_LIST_SHADERS="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      require_arg "$1" "${2:-}"
      CLI_FILE="$2"
      shift 2
      ;;
    --list-shaders)
      CLI_LIST_SHADERS="1"
      shift
      ;;
    --in-dir)
      require_arg "$1" "${2:-}"
      CLI_IN_DIR="$2"
      shift 2
      ;;
    --out-dir)
      require_arg "$1" "${2:-}"
      CLI_OUT_DIR="$2"
      shift 2
      ;;
    --shader)
      require_arg "$1" "${2:-}"
      CLI_SHADER="$2"
      shift 2
      ;;
    --cq)
      require_arg "$1" "${2:-}"
      CLI_CQ="$2"
      shift 2
      ;;
    --mode)
      require_arg "$1" "${2:-}"
      CLI_UPSCALE_MODE="$2"
      shift 2
      ;;
    --codec)
      require_arg "$1" "${2:-}"
      CLI_NVENC_CODEC="$2"
      shift 2
      ;;
    --preset)
      require_arg "$1" "${2:-}"
      CLI_NVENC_PRESET="$2"
      shift 2
      ;;
    --bit-depth)
      require_arg "$1" "${2:-}"
      CLI_BIT_DEPTH_MODE="$2"
      shift 2
      ;;
    -w|--width)
      require_arg "$1" "${2:-}"
      CLI_TARGET_W="$2"
      shift 2
      ;;
    -h|--height)
      require_arg "$1" "${2:-}"
      CLI_TARGET_H="$2"
      shift 2
      ;;
    --vulkan-device-index)
      require_arg "$1" "${2:-}"
      CLI_VULKAN_DEVICE_INDEX="$2"
      shift 2
      ;;
    --decode-hw)
      require_arg "$1" "${2:-}"
      CLI_DECODE_HW="$2"
      shift 2
      ;;
    --prime-offload)
      CLI_USE_PRIME_OFFLOAD="1"
      shift
      ;;
    --no-prime-offload)
      CLI_USE_PRIME_OFFLOAD="0"
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ $# -gt 0 ]]; then
  echo "Unexpected positional arguments: $*" >&2
  usage >&2
  exit 1
fi

if [[ "$CLI_LIST_SHADERS" != "1" && -n "$CLI_FILE" && ( -n "$CLI_IN_DIR" || -n "$CLI_OUT_DIR" ) ]]; then
  echo "--file is exclusive with --in-dir/--out-dir" >&2
  exit 1
fi

if [[ "$CLI_LIST_SHADERS" != "1" && -z "$CLI_FILE" && ( -z "$CLI_IN_DIR" || -z "$CLI_OUT_DIR" ) ]]; then
  echo "--in-dir and --out-dir are required unless --file is used" >&2
  usage >&2
  exit 1
fi

USE_PRIME_OFFLOAD="${CLI_USE_PRIME_OFFLOAD:-0}"
if [[ "$USE_PRIME_OFFLOAD" == "1" ]]; then
  export __NV_PRIME_RENDER_OFFLOAD="${__NV_PRIME_RENDER_OFFLOAD:-1}"
  export __NV_PRIME_RENDER_OFFLOAD_PROVIDERS="${__NV_PRIME_RENDER_OFFLOAD_PROVIDERS:-NVIDIA-G0}"
  export __GLX_VENDOR_LIBRARY_NAME="${__GLX_VENDOR_LIBRARY_NAME:-nvidia}"
fi

ANIME4K_SHADER_DIR="__ANIME4K_SHADER_DIR__"
if [[ "$CLI_LIST_SHADERS" == "1" ]]; then
  found=0
  shopt -s nullglob
  for shader_file in "$ANIME4K_SHADER_DIR"/*.glsl; do
    found=1
    basename "$shader_file"
  done
  shopt -u nullglob
  if [[ "$found" == "0" ]]; then
    echo "(none found under $ANIME4K_SHADER_DIR)"
  fi
  exit 0
fi

SINGLE_FILE_MODE=0
if [[ -n "$CLI_FILE" ]]; then
  SINGLE_FILE_MODE=1
  INPUT_FILE="$(realpath "$CLI_FILE")"
  IN_DIR="$(dirname "$INPUT_FILE")"
  OUT_DIR="$(dirname "$INPUT_FILE")"
else
  IN_DIR="$(realpath "$CLI_IN_DIR")"
  OUT_DIR="$(realpath -m "$CLI_OUT_DIR")"
fi
ANIME4K_SHADER="${CLI_SHADER:-Anime4K_Upscale_CNN_x2_M.glsl}"
SHADER_PATH="${ANIME4K_SHADER_DIR}/${ANIME4K_SHADER}"
CQ="${CLI_CQ:-24}"
FFMPEG_BIN="__FFMPEG_BIN__"
FFPROBE_BIN="__FFPROBE_BIN__"
UPSCALE_MODE="${CLI_UPSCALE_MODE:-auto}"   # anime4k | fast | auto
NVENC_CODEC="${CLI_NVENC_CODEC:-hevc_nvenc}"
NVENC_PRESET="${CLI_NVENC_PRESET:-p3}"
BIT_DEPTH_MODE="${CLI_BIT_DEPTH_MODE:-auto}" # auto | 8 | 10
TARGET_W="${CLI_TARGET_W:-3840}"
TARGET_H="${CLI_TARGET_H:-2160}"
VULKAN_DEVICE_INDEX="${CLI_VULKAN_DEVICE_INDEX:-1}"
DECODE_HW="${CLI_DECODE_HW:-auto}" # auto | sw | vulkan | cuda
JOBS=1
FILTERS_OUTPUT=""
RUN_USED_DECODE=""
RUN_USED_BIT_DEPTH=""
RUN_USED_PIX_FMT=""

list_available_anime4k_shaders() {
  local shader_file
  local found=0
  shopt -s nullglob
  for shader_file in "$ANIME4K_SHADER_DIR"/*.glsl; do
    found=1
    basename "$shader_file"
  done
  shopt -u nullglob
  if [[ "$found" == "0" ]]; then
    echo "(none found under $ANIME4K_SHADER_DIR)"
  fi
}

validate_anime4k_shader_selection() {
  if [[ "$ANIME4K_SHADER" == */* ]]; then
    echo "--shader expects a file name only (no path): $ANIME4K_SHADER" >&2
    exit 1
  fi
  if [[ -n "$CLI_SHADER" && ! -f "$SHADER_PATH" ]]; then
    echo "Unknown Anime4K shader: $ANIME4K_SHADER" >&2
    echo "Available shaders:" >&2
    list_available_anime4k_shaders >&2
    exit 1
  fi
}

has_filter() {
  local filter_name="$1"
  [[ "$FILTERS_OUTPUT" == *" ${filter_name} "* ]]
}

refresh_filters_output() {
  FILTERS_OUTPUT="$("$FFMPEG_BIN" -nostdin -hide_banner -filters 2>/dev/null || true)"
}

can_use_libplacebo() {
  "$FFMPEG_BIN" -nostdin -v error \
    -init_hw_device "vulkan=vk:${VULKAN_DEVICE_INDEX}" -filter_hw_device vk \
    -f lavfi -i color=size=32x32:rate=1 -frames:v 1 \
    -vf "libplacebo=w=32:h=32:custom_shader_path=$SHADER_PATH" \
    -f null - >/dev/null 2>&1
}

can_use_cuda_nvenc() {
  "$FFMPEG_BIN" -nostdin -v error \
    -f lavfi -i testsrc2=size=320x180:rate=1 -frames:v 2 \
    -vf "format=yuv420p,hwupload_cuda,scale_cuda=640:360" \
    -c:v hevc_nvenc \
    -f null - >/dev/null 2>&1
}

is_valid_video() {
  local path="$1"
  "$FFPROBE_BIN" -v error -select_streams v:0 \
    -show_entries stream=codec_name,width,height \
    -of default=noprint_wrappers=1:nokey=1 \
    "$path" >/dev/null 2>&1
}

validate_decode_hw() {
  case "$DECODE_HW" in
    auto|sw|vulkan|cuda)
      ;;
    *)
      echo "Invalid DECODE_HW: $DECODE_HW (expected: auto | sw | vulkan | cuda)" >&2
      exit 1
      ;;
  esac
}

validate_decode_hw_for_backend() {
  case "$BACKEND:$DECODE_HW" in
    cuda:auto|cuda:sw|cuda:cuda|libplacebo:auto|libplacebo:sw|libplacebo:vulkan)
      ;;
    cuda:vulkan)
      echo "--decode-hw vulkan is incompatible with CUDA backend." >&2
      exit 1
      ;;
    libplacebo:cuda)
      echo "--decode-hw cuda is incompatible with Anime4K/libplacebo backend." >&2
      exit 1
      ;;
  esac
}

validate_bit_depth_mode() {
  case "$BIT_DEPTH_MODE" in
    auto|8|10)
      ;;
    *)
      echo "Invalid --bit-depth: $BIT_DEPTH_MODE (expected: auto | 8 | 10)" >&2
      exit 1
      ;;
  esac
}

get_input_bit_depth() {
  local path="$1"
  local pix_fmt bits
  pix_fmt="$("$FFPROBE_BIN" -v error -select_streams v:0 \
    -show_entries stream=pix_fmt -of default=noprint_wrappers=1:nokey=1 \
    "$path" 2>/dev/null || true)"
  bits="$("$FFPROBE_BIN" -v error -select_streams v:0 \
    -show_entries stream=bits_per_raw_sample -of default=noprint_wrappers=1:nokey=1 \
    "$path" 2>/dev/null || true)"

  if [[ "$bits" =~ ^[0-9]+$ ]]; then
    echo "$bits"
    return 0
  fi
  case "$pix_fmt" in
    *p010*|*yuv420p10*|*yuv422p10*|*yuv444p10*|*gbrp10*)
      echo 10
      ;;
    *)
      echo 8
      ;;
  esac
}

choose_pix_fmt_for_input() {
  local input_path="$1"
  case "$BIT_DEPTH_MODE" in
    8)
      echo "nv12"
      ;;
    10)
      echo "p010le"
      ;;
    auto)
      if (( "$(get_input_bit_depth "$input_path")" >= 10 )); then
        echo "p010le"
      else
        echo "nv12"
      fi
      ;;
  esac
}

bit_depth_from_pix_fmt() {
  local pix_fmt="$1"
  case "$pix_fmt" in
    p010le|*10*)
      echo "10"
      ;;
    nv12|*8*)
      echo "8"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

resolve_ffmpeg_binary() {
  refresh_filters_output
}

select_backend() {
  case "$UPSCALE_MODE" in
    fast)
      if has_filter "scale_cuda" && can_use_cuda_nvenc; then
        echo "cuda"
        return 0
      fi
      echo "Fast mode requires CUDA (scale_cuda + NVENC)." >&2
      exit 1
      ;;
    anime4k)
      if has_filter "libplacebo" && [[ -f "$SHADER_PATH" ]] && can_use_libplacebo; then
        echo "libplacebo"
        return 0
      fi
      echo "Anime4K mode requires libplacebo+Vulkan and shader: $ANIME4K_SHADER" >&2
      echo "Available shaders:" >&2
      list_available_anime4k_shaders >&2
      exit 1
      ;;
    auto)
      if has_filter "libplacebo" && [[ -f "$SHADER_PATH" ]] && can_use_libplacebo; then
        echo "libplacebo"
        return 0
      elif has_filter "scale_cuda" && can_use_cuda_nvenc; then
        echo "cuda"
        return 0
      fi
      ;;
    *)
      echo "Invalid UPSCALE_MODE: $UPSCALE_MODE (expected: fast | anime4k | auto)" >&2
      exit 1
      ;;
  esac

  echo "No supported GPU backend available (auto tried Anime4K then CUDA)." >&2
  echo "Anime4K shader setting: $ANIME4K_SHADER" >&2
  exit 1
}

print_runtime_config() {
  local mode_display decode_request decode_plan bit_depth_request bit_depth_plan
  if [[ "$SINGLE_FILE_MODE" == "1" ]]; then
    echo "File:     $INPUT_FILE"
  else
    echo "Scanning: $IN_DIR"
    echo "Output:   $OUT_DIR"
  fi

  mode_display="$UPSCALE_MODE"
  if [[ "$UPSCALE_MODE" == "auto" ]]; then
    mode_display="auto -> $BACKEND"
  fi

  decode_request="$DECODE_HW"
  decode_plan="$DECODE_HW"
  if [[ "$DECODE_HW" == "auto" ]]; then
    if [[ "$BACKEND" == "libplacebo" ]]; then
      decode_plan="vulkan (fallback: sw)"
    else
      decode_plan="cuda (fallback: sw)"
    fi
  fi

  bit_depth_request="$BIT_DEPTH_MODE"
  case "$BIT_DEPTH_MODE" in
    auto)
      bit_depth_plan="input-based (>=10bit -> 10/p010le, else 8/nv12)"
      ;;
    10)
      bit_depth_plan="fixed 10 (p010le)"
      ;;
    8)
      bit_depth_plan="fixed 8 (nv12)"
      ;;
  esac

  echo "Backend:  $BACKEND"
  echo "Mode:     $mode_display"
  echo "Jobs:     $JOBS"
  echo "FFmpeg:   $FFMPEG_BIN"
  echo "Prime:    $USE_PRIME_OFFLOAD"
  echo "Codec:    $NVENC_CODEC"
  echo "BitDepthRq: $bit_depth_request"
  echo "BitDepthPl: $bit_depth_plan"
  echo "Shader:   $ANIME4K_SHADER"
  echo "Vulkan:   vk:${VULKAN_DEVICE_INDEX}"
  echo "DecodeRq: $decode_request"
  echo "DecodePl: $decode_plan"
}

remux_if_no_upscale_needed() {
  local input_path="$1"
  local temp_output="$2"
  local input_dims input_w input_h
  local mux_flags=()

  if [[ "$temp_output" == *.mp4 || "$temp_output" == *.m4v || "$temp_output" == *.mov ]]; then
    mux_flags=(-movflags +faststart)
  fi

  input_dims="$("$FFPROBE_BIN" -v error -select_streams v:0 \
    -show_entries stream=width,height -of csv=p=0:s=x "$input_path" 2>/dev/null || true)"
  input_w="${input_dims%x*}"
  input_h="${input_dims#*x}"

  if [[ "$input_w" =~ ^[0-9]+$ && "$input_h" =~ ^[0-9]+$ ]] && (( input_w >= TARGET_W && input_h >= TARGET_H )); then
    echo "No upscale needed (${input_w}x${input_h} >= ${TARGET_W}x${TARGET_H}), remuxing: $input_path"
    if "$FFMPEG_BIN" -nostdin -hide_banner -loglevel error -stats -y -i "$input_path" \
      -map 0 -c copy "${mux_flags[@]}" \
      "$temp_output"; then
      RUN_USED_DECODE="copy"
      RUN_USED_PIX_FMT="copy"
      RUN_USED_BIT_DEPTH="$(get_input_bit_depth "$input_path")"
      return 0
    fi
    echo "Remux failed, falling back to re-encode: $input_path"
    rm -f "$temp_output"
  fi

  return 1
}

encode_libplacebo() {
  local input_path="$1"
  local temp_output="$2"
  local mux_flags=()
  local output_pix_fmt
  local decode_mode="$DECODE_HW"
  output_pix_fmt="$(choose_pix_fmt_for_input "$input_path")"
  RUN_USED_PIX_FMT="$output_pix_fmt"
  RUN_USED_BIT_DEPTH="$(bit_depth_from_pix_fmt "$output_pix_fmt")"

  if [[ "$temp_output" == *.mp4 || "$temp_output" == *.m4v || "$temp_output" == *.mov ]]; then
    mux_flags=(-movflags +faststart)
  fi

  if [[ "$decode_mode" == "auto" ]]; then
    decode_mode="vulkan"
  fi

  if [[ "$decode_mode" == "vulkan" ]]; then
    if ! "$FFMPEG_BIN" -nostdin -hide_banner -loglevel error -stats -y \
      -init_hw_device "vulkan=vk:${VULKAN_DEVICE_INDEX}" -filter_hw_device vk \
      -hwaccel vulkan -hwaccel_output_format vulkan \
      -i "$input_path" \
      -vf "libplacebo=w=$TARGET_W:h=$TARGET_H:custom_shader_path=$SHADER_PATH" \
      -pix_fmt "$output_pix_fmt" \
      -c:v "$NVENC_CODEC" -preset "$NVENC_PRESET" -rc vbr -cq "$CQ" \
        -c:a copy \
        "${mux_flags[@]}" \
        "$temp_output"; then
      if [[ "$DECODE_HW" != "auto" ]]; then
        return 1
      fi
      if [[ ! -f "$input_path" ]]; then
        echo "Input disappeared before software-decode retry: $input_path" >&2
        return 1
      fi
      echo "Vulkan decode failed; retrying with software decode: $input_path"
      "$FFMPEG_BIN" -nostdin -hide_banner -loglevel error -stats -y -i "$input_path" \
        -init_hw_device "vulkan=vk:${VULKAN_DEVICE_INDEX}" -filter_hw_device vk \
        -vf "libplacebo=w=$TARGET_W:h=$TARGET_H:custom_shader_path=$SHADER_PATH" \
        -pix_fmt "$output_pix_fmt" \
        -c:v "$NVENC_CODEC" -preset "$NVENC_PRESET" -rc vbr -cq "$CQ" \
        -c:a copy \
        "${mux_flags[@]}" \
        "$temp_output"
      RUN_USED_DECODE="sw"
    else
      RUN_USED_DECODE="vulkan"
    fi
  else
    "$FFMPEG_BIN" -nostdin -hide_banner -loglevel error -stats -y -i "$input_path" \
      -init_hw_device "vulkan=vk:${VULKAN_DEVICE_INDEX}" -filter_hw_device vk \
      -vf "libplacebo=w=$TARGET_W:h=$TARGET_H:custom_shader_path=$SHADER_PATH" \
      -pix_fmt "$output_pix_fmt" \
      -c:v "$NVENC_CODEC" -preset "$NVENC_PRESET" -rc vbr -cq "$CQ" \
      -c:a copy \
      "${mux_flags[@]}" \
      "$temp_output"
    RUN_USED_DECODE="sw"
  fi
}

encode_cuda() {
  local input_path="$1"
  local temp_output="$2"
  local mux_flags=()
  local output_pix_fmt pre_filter
  local decode_mode="$DECODE_HW"
  output_pix_fmt="$(choose_pix_fmt_for_input "$input_path")"
  RUN_USED_PIX_FMT="$output_pix_fmt"
  RUN_USED_BIT_DEPTH="$(bit_depth_from_pix_fmt "$output_pix_fmt")"
  if [[ "$output_pix_fmt" == "p010le" ]]; then
    pre_filter="format=p010le,hwupload_cuda"
  else
    pre_filter="format=nv12,hwupload_cuda"
  fi

  if [[ "$temp_output" == *.mp4 || "$temp_output" == *.m4v || "$temp_output" == *.mov ]]; then
    mux_flags=(-movflags +faststart)
  fi

  if [[ "$decode_mode" == "auto" ]]; then
    decode_mode="cuda"
  fi

  if [[ "$decode_mode" == "cuda" ]]; then
    if ! "$FFMPEG_BIN" -nostdin -hide_banner -loglevel error -stats -y \
      -hwaccel cuda -hwaccel_output_format cuda \
      -i "$input_path" \
      -vf "scale_cuda=${TARGET_W}:${TARGET_H}" \
      -pix_fmt "$output_pix_fmt" \
      -c:v "$NVENC_CODEC" -preset "$NVENC_PRESET" -rc vbr -cq "$CQ" \
        -c:a copy \
        "${mux_flags[@]}" \
        "$temp_output"; then
      if [[ "$DECODE_HW" != "auto" ]]; then
        return 1
      fi
      if [[ ! -f "$input_path" ]]; then
        echo "Input disappeared before software-decode retry: $input_path" >&2
        return 1
      fi
      echo "CUDA decode failed; retrying with software decode: $input_path"
      "$FFMPEG_BIN" -nostdin -hide_banner -loglevel error -stats -y -i "$input_path" \
        -vf "${pre_filter},scale_cuda=${TARGET_W}:${TARGET_H}" \
        -pix_fmt "$output_pix_fmt" \
        -c:v "$NVENC_CODEC" -preset "$NVENC_PRESET" -rc vbr -cq "$CQ" \
        -c:a copy \
        "${mux_flags[@]}" \
        "$temp_output"
      RUN_USED_DECODE="sw"
    else
      RUN_USED_DECODE="cuda"
    fi
  else
    "$FFMPEG_BIN" -nostdin -hide_banner -loglevel error -stats -y -i "$input_path" \
      -vf "${pre_filter},scale_cuda=${TARGET_W}:${TARGET_H}" \
      -pix_fmt "$output_pix_fmt" \
      -c:v "$NVENC_CODEC" -preset "$NVENC_PRESET" -rc vbr -cq "$CQ" \
      -c:a copy \
      "${mux_flags[@]}" \
      "$temp_output"
    RUN_USED_DECODE="sw"
  fi
}

process_file() {
  local rel_path="$1"
  local input output temp_output backend_tag shader_tag anime4k_shader
  local single_file_mode="${SINGLE_FILE_MODE:-0}"
  if [[ "$BACKEND" == "libplacebo" ]]; then
    anime4k_shader="${ANIME4K_SHADER:-${SHADER_PATH##*/}}"
    shader_tag="${anime4k_shader%.glsl}"
    shader_tag="${shader_tag// /_}"
    backend_tag="anime4k.${shader_tag}"
  else
    backend_tag="$BACKEND"
  fi

  if [[ "$single_file_mode" == "1" ]]; then
    input="$INPUT_FILE"
    output="${input%.*}.${backend_tag}.${input##*.}"
  else
    input="$IN_DIR/$rel_path"
    if [[ "$rel_path" == *.* ]]; then
      output="$OUT_DIR/${rel_path%.*}.${backend_tag}.${rel_path##*.}"
    else
      output="$OUT_DIR/${rel_path}.${backend_tag}"
    fi
  fi
  if [[ ! -f "$input" ]]; then
    echo "Skipping missing input: $input" >&2
    return 0
  fi
  if [[ "$output" == *.* ]]; then
    temp_output="${output%.*}.part.${output##*.}"
  else
    temp_output="${output}.part"
  fi
  mkdir -p "$(dirname "$output")"

  if [[ -f "$output" ]]; then
    if is_valid_video "$output"; then
      echo "Skipping: $output (already valid)"
      return 0
    fi
    echo "Re-encoding invalid output: $output"
    rm -f "$output"
  fi

  echo "Upscaling [$BACKEND]: $input -> $output"
  RUN_USED_DECODE=""
  RUN_USED_BIT_DEPTH=""
  RUN_USED_PIX_FMT=""
  rm -f "$temp_output"

  if remux_if_no_upscale_needed "$input" "$temp_output"; then
    if ! is_valid_video "$temp_output"; then
      echo "Invalid remux output: $temp_output" >&2
      exit 1
    fi
    mv -f "$temp_output" "$output"
    echo "RunUsed: decode=${RUN_USED_DECODE:-unknown}, bitdepth=${RUN_USED_BIT_DEPTH:-unknown}, pix_fmt=${RUN_USED_PIX_FMT:-unknown}"
    echo "Done: $output"
    return 0
  fi

  case "$BACKEND" in
    libplacebo)
      encode_libplacebo "$input" "$temp_output"
      ;;
    cuda)
      encode_cuda "$input" "$temp_output"
      ;;
    *)
      echo "Unknown backend: $BACKEND" >&2
      exit 1
      ;;
  esac

  if ! is_valid_video "$temp_output"; then
    echo "Invalid encoded output: $temp_output" >&2
    exit 1
  fi
  mv -f "$temp_output" "$output"
  echo "RunUsed: decode=${RUN_USED_DECODE:-unknown}, bitdepth=${RUN_USED_BIT_DEPTH:-unknown}, pix_fmt=${RUN_USED_PIX_FMT:-unknown}"
  echo "Done: $output"
}

if [[ "$SINGLE_FILE_MODE" == "1" ]]; then
  if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Input file not found: $INPUT_FILE" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$INPUT_FILE")"
else
  if [[ ! -d "$IN_DIR" ]]; then
    echo "Input directory not found: $IN_DIR" >&2
    exit 1
  fi
  mkdir -p "$OUT_DIR"
fi

validate_decode_hw
validate_bit_depth_mode
validate_anime4k_shader_selection
resolve_ffmpeg_binary
BACKEND="$(select_backend)"
validate_decode_hw_for_backend

print_runtime_config

on_interrupt() {
  echo "Interrupted. Stopping immediately." >&2
  exit 130
}
trap on_interrupt INT TERM

if [[ "$SINGLE_FILE_MODE" == "1" ]]; then
  process_file "$INPUT_FILE"
else
  while IFS= read -r rel_path; do
    process_file "$rel_path"
  done < <(
    fd -j "$JOBS" -t f -e mp4 -e mkv -e avi --base-directory "$IN_DIR" .
  )
fi
