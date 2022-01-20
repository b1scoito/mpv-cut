# mpv-cut
A video cutting/clipping/slicing script for mpv

## Installation
### Linux
Place it inside the Linux mpv scripts folder normally on: `~/.config/mpv/scripts`

### Windows
Place it inside the Windows mpv scripts folder normally on `%appdata%\mpv\scripts`

## Usage
Press the default key `C` to mark the first position, and where you desire to save, on the last position, press `C` again.

## Settings
The settings can be changed editing the [script](https://github.com/b1scoito/mpv-cut/blob/main/mpv_cut.lua#L7) file.
```lua
local settings = {
    key_mark_cut = "c",
    web_key_mark_cut = "shift+c",

    -- output video extension
    video_ext = "mp4",

    -- web save settings
    web_audio_target_bitrate = "128", -- kbps
    web_video_target_file_size = "8"  -- mb
}
```

### Further explanation

- `key_mark_cut`: The key for cutting the video.
- `web_key_mark_cut`: The key for cutting the video with a shareable web file size (todo).
- `video_ext`: The output extension of the video.
- `web_audio_target_bitrate`: Target audio bitrate for the web cut.
- `web_video_target_file_size`: Target file size for the web cut.
