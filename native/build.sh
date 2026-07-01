#!/usr/bin/env bash
# Builds the PA3D positional-audio backend (Steam Audio) for win32 (x86) and win64 (x64).
# Requires a mingw-w64 toolchain (i686-/x86_64-w64-mingw32-gcc), the Steam Audio SDK and a copy
# of miniaudio.h (both fetched, not vendored here):
#
#   miniaudio.h     -> set MINIAUDIO_DIR to the folder containing it (https://miniaud.io)
#   Steam Audio SDK -> set STEAMAUDIO_DIR to the unzipped sdk/steamaudio folder
#                      (download steamaudio_<ver>.zip from https://valvesoftware.github.io/steam-audio)
#
# Outputs PA3D_steam_{x86,x64}.dll and test_steam.exe into ./out. Each dll needs phonon.dll of the
# matching architecture (sdk/steamaudio/lib/windows-x86|x64) beside it at runtime.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
out="$here/out"; mkdir -p "$out"
MINIAUDIO_DIR="${MINIAUDIO_DIR:-$here}"
STEAMAUDIO_DIR="${STEAMAUDIO_DIR:-}"
CFLAGS="-O2 -static-libgcc"
[ -n "$STEAMAUDIO_DIR" ] || { echo "set STEAMAUDIO_DIR to the unzipped sdk/steamaudio folder"; exit 1; }

build_steam() {
  local cc="$1" tag="$2" libdir="$3"
  "$cc" $CFLAGS -shared -o "$out/PA3D_steam_${tag}.dll" "$here/pa3d_steam.c" "$here/pa3d.def" \
    -I"$STEAMAUDIO_DIR/include" -I"$MINIAUDIO_DIR" \
    -L"$STEAMAUDIO_DIR/lib/$libdir" -lphonon -lwinmm -lole32
  echo "built $out/PA3D_steam_${tag}.dll (needs phonon.dll from $libdir beside it)"
}

build_steam i686-w64-mingw32-gcc   x86 windows-x86
build_steam x86_64-w64-mingw32-gcc x64 windows-x64

x86_64-w64-mingw32-gcc $CFLAGS -o "$out/test_steam.exe" "$here/test_steam.c" \
  -I"$STEAMAUDIO_DIR/include" -L"$STEAMAUDIO_DIR/lib/windows-x64" -lphonon -lm
echo "built $out/test_steam.exe (copy windows-x64/phonon.dll beside it to run)"
