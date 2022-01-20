# mpv-cut
A video cutting/clipping script for mpv

## Installation
### Linux
Place it inside the mpv scripts folder normally on: `~/.config/mpv/scripts`

### Windows
Place it inside the mpv scripts folder normally on `%appdata%\mpv\scripts`

## Usage
Press the default key `c` to mark the first position, and where you desire to save, on the last position, press `c` again.

## Settings
The settings can be changed editing the script file.
```lua
local settings = {
    key_mark_cut = "c",
    video_ext = "mp4",
    audio_track_extract = "1"
}
```

- `key_mark_cut` is the key for cutting the video.
- `video_ext` is the output extension of the video.
- `audio_track_extract` is the audio track you want to keep out of the video.
