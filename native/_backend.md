# PA3D native audio backend (Steam Audio)

PA3D is the small DLL behind `core/audio/audio3d.rb` (the binaural soundscape). It exposes a
tiny integer/string ABI so the Ruby side never changes:

```
int  PA3D_Init(void)
int  PA3D_Channel(const char* wavPath, int loop)   // -> channel id, or -1
void PA3D_Listener(int x100, int y100)
void PA3D_Set(int ch, int x100, int y100, int vol100, int play)
void PA3D_Master(int vol100)
void PA3D_Shutdown(void)
```

Coordinates are tile units times 100. The listener faces north (`-z`); map `x -> x`,
map `y -> z`. Distance attenuation is linear, clamped between 1 and 14 tiles.

## Implementation

`pa3d_steam.c` -> `PA3D_steam.dll`. It uses **Steam Audio (phonon)** for the HRTF math and
**miniaudio** for the output device and mixing: each active channel is rendered with
`iplBinauralEffectApply` and the results are summed in a single playback callback (frame size
1024, 44100 Hz). Each DLL depends on `phonon.dll` of the matching architecture
(~46 MB x86 / ~53 MB x64) sitting beside it in the install's `accessibility/lib/` folder;
`SetDllDirectory` (set in `speech.rb`) puts that folder on the DLL search path so it resolves.

miniaudio is compiled into the DLL (header-only). Z/Ópalo are x86; Reminiscencia/Añil are x64.

## Building

Needs a mingw-w64 toolchain plus the Steam Audio SDK and a copy of `miniaudio.h` (neither is
vendored here because of size/licensing):

```bash
export MINIAUDIO_DIR=/path/to/folder/with/miniaudio.h
export STEAMAUDIO_DIR=/path/to/unzipped/sdk/steamaudio   # has include/ and lib/
./build.sh                                                # outputs to ./out
```

`test_steam.c` is a standalone correctness check (no audio device required): it creates a
context, HRTF and binaural effect, renders a 440 Hz tone toward several directions and asserts
the output is non-silent and properly panned (left direction => more energy in the left ear).
Run it with the matching `phonon.dll` beside the executable.
