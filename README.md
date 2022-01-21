# mpv-cut
A video cutting/clipping/slicing script for [mpv](https://mpv.io/)

## Installation
### Linux
Place it inside the Linux mpv scripts folder normally on: `~/.config/mpv/scripts`, and install the FFmpeg package if not already installed.
- Ubuntu: `sudo apt install ffmpeg`
- Arch: `sudo pacman -S ffmpeg` or `yay -S ffmpeg`

### Windows
Place it inside the Windows mpv scripts folder normally on `%appdata%\mpv\scripts`, and install the FFmpeg package if not already installed with [Chocolatey](https://chocolatey.org/install).
- Chocolatey (open cmd/powershell as admin): `choco install ffmpeg-full` or `cinst ffmpeg-full`

## Usage
Press the default key `C` to mark the first position, and where you desire to save, on the last position, press `C` again.  
Use `Shift+C` for cutting with a smaller file size. Disclaimer: This will result in way slower cutting speeds.

## Settings
The settings can be changed by editing the [script](https://github.com/b1scoito/mpv-cut/blob/main/mpv_cut.lua#L7) file.
```lua
local settings = {
    key_mark_cut = "c",
    video_extension = "mp4",

    -- if you want faster cutting, leave this blank
    ffmpeg_custom_parameters = "",

    web = {
        -- small file settings
        key_mark_cut = "shift+c",

        audio_target_bitrate = "128", -- kbps
        video_target_file_size = "8",  -- mb
        video_target_scale = "1280:-1" -- https://trac.ffmpeg.org/wiki/Scaling everthing after "scale=" will be considered, keep "original" for no changes to the scaling
    }
}
```

### Further explanation

- `key_mark_cut`: The key for cutting the video.
- `video_extension`: The output extension of the video.
- `ffmpeg_custom_parameters`: FFmpeg custom parameters to use. Disclaimer: This _will_ result in way slower cutting speeds as it is not going to use `-c copy` anymore.
- `web.key_mark_cut`: The key for cutting the video with a shareable web file size (todo).
- `web.audio_target_bitrate`: Target audio bitrate for the web cut.
- `web.video_target_file_size`: Target file size for the web cut.
- `web.video_target_scale`: Target video scale (https://trac.ffmpeg.org/wiki/Scaling), keep "original" for no changes to the scaling.
