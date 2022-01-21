---@diagnostic disable: lowercase-global, undefined-global

msg = require("mp.msg")
utils = require("mp.utils")

-- #region globals
local settings = {
    key_mark_cut = "c",
    video_extension = "mp4",

    -- if you want faster cutting, leave this blank
    ffmpeg_custom_parameters = "",

    web = {
        -- small file settings
        key_mark_cut = "shift+c",

        audio_target_bitrate = "128", -- kbps
        video_target_file_size = "8"  -- mb
    }
}

local vars = {
    path = nil,
    filename = nil,

    video_duration = nil,

    used_web_mark_pos = nil,

    pos = {
        start_pos = nil,
        end_pos = nil
    }
}
-- #endregion

-- #region utils
function str_split(input, separator)
    if not separator then
        separator = "%s"
    end

    local t = {}
    for str in string.gmatch(input, "([^" .. separator .. "]+)") do
        table.insert(t, str)
    end

    return t
end

function to_timestamp(seconds)
    local hrs = seconds / 3600
    local mins = (seconds % 3600) / 60
    local secs = seconds % 60

    return string.format("%02d:%02d:%02d", math.floor(hrs), math.floor(mins), math.floor(secs))
end

function reset_pos()
    vars.pos.start_pos = nil
    vars.pos.end_pos = nil
end

function exec(args)
    log(msg.info, string.format("Executing %s", table.concat(args, " ")))

    local ret = mp.command_native({
        name = "subprocess",
        args = args,
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false
    })

    log(msg.info, "Finished executing.")

    return ret.status, ret.stdout, ret.stderr
end

function log(type, fmt, delay)
    if delay and delay > 0 then
        mp.osd_message(fmt, delay)
    end

    type(fmt)
end
-- #endregion

-- #region main
function ffmpeg_cut(time_start, time_end, input_file, output_file)
    input_file = string.format("\"%s\"", input_file)

    if string.len(settings.ffmpeg_custom_parameters) > 0 and not vars.used_web_mark_pos then
        ffmpeg_custom_arguments = {}
        for substr in settings.ffmpeg_custom_parameters:gmatch("%S+") do
            table.insert(ffmpeg_custom_arguments, substr)
        end
    
        local arr_start = {"ffmpeg", "-y", "-i", input_file}
        for _, value in pairs(ffmpeg_custom_arguments) do
            table.insert(arr_start, value)
        end
    
        local arr_end = {"-ss", time_start, "-to", time_end, output_file}
        for _, value in pairs(arr_end) do
            table.insert(arr_start, value)
        end

        local status, _, _ = exec(arr_start)
        if status > 0 then
            return false
        end

        return true
    end

    local status, _, _ = exec({"ffmpeg", "-y", "-ss", time_start, "-to", time_end, "-i", input_file, "-c", "copy", output_file})
    if status > 0 then
        return false
    end

    return true
end

function ffmpeg_resize(input_file, output_file)
    input_file = string.format("\"%s\"", input_file)

    local target_bitrate = (settings.web.video_target_file_size * 8192) / math.floor(vars.video_duration) -- Video bitrate
    target_bitrate = target_bitrate - settings.web.audio_target_bitrate -- Audio bitrate

    if target_bitrate < 0 then
        log(msg.error, "Target video bitrate is lower than 0! Try making your target file size bigger.", 10)
        return false
    end

    local formatted_target_bitrate = string.format("%sk", math.floor(target_bitrate))
    log(msg.info, string.format("Target video bitrate: %s.", formatted_target_bitrate))

    -- Double pass from https://trac.ffmpeg.org/wiki/Encode/H.264#twopass
    local status, _, _ = exec({"ffmpeg", "-y", "-i", input_file, "-c:v", "libx264", "-b:v", formatted_target_bitrate, "-pass", "1", "-an", "-f", "null", "NUL"})
    if status > 0 then
        return false
    end

    status, _, _ = exec({"ffmpeg", "-y", "-i", input_file, "-c:v", "libx264", "-b:v", formatted_target_bitrate, "-pass", "2", "-c:a", "aac", "-b:a", string.format("%sk", settings.web.audio_target_bitrate), output_file})
    if status > 0 then
        return false
    end

    return true
end

function web_mark_pos()
    vars.used_web_mark_pos = true

    mark_pos(vars.used_web_mark_pos)
end

function mark_pos(is_web)
    local current_pos = mp.get_property_number("time-pos")

    if not vars.pos.start_pos then
        vars.pos.start_pos = current_pos
        log(msg.info, string.format("Marked %ss as start position", current_pos), 3)
        return
    end

    vars.pos.end_pos = current_pos

    if vars.pos.start_pos >= vars.pos.end_pos then
        log(msg.error, string.format("Invalid time selected!", current_pos), 3)
        reset_pos()
        return
    end

    log(msg.info, string.format("Marked %ss as end position", current_pos), 3)

    local output_name = string.format("%s-cut.%s", str_split(vars.filename, ".")[1], settings.video_extension)
    -- Cut
    if not ffmpeg_cut(to_timestamp(vars.pos.start_pos), to_timestamp(vars.pos.end_pos), vars.path, output_name) then
        log(msg.error, "Failed to execute FFmpeg cut!", 10)
        reset_pos()
        return
    end

    -- Resize video
    if is_web then
        local output_name_resized = string.format("%s-cut-resized.%s", str_split(vars.filename, ".")[1], settings.video_extension)

        if not ffmpeg_resize(output_name, output_name_resized) then
            log(msg.error, "Failed to execute FFmpeg resize!", 10)
            reset_pos()
            return
        end

        -- Find a better way to do this
        local status, err_msg = os.remove(output_name)
        if not status then
            log(msg.error, string.format("Failed to delete: %s!", err_msg))
        end

        status, err_msg = os.remove("ffmpeg2pass-0.log")
        if not status then
            log(msg.error, string.format("Failed to delete: %s!", err_msg))
        end

        status, err_msg = os.remove("ffmpeg2pass-0.log.mbtree")
        if not status then
            log(msg.error, string.format("Failed to delete: %s!", err_msg))
        end

        log(msg.info, string.format("Saved as %s.", output_name_resized), 10)
        reset_pos()

        mp.set_property("keep-open", "no")
        vars.used_web_mark_pos = false

        return
    end

    -- Reset vars
    reset_pos()
    mp.set_property("keep-open", "no")

    log(msg.info, string.format("Saved as %s.", output_name), 10)

end
-- #endregion

-- #region events
mp.register_event("file-loaded", function()
    local duration = mp.get_property("duration")
    local path = mp.get_property("path")
    local _, filename = utils.split_path(path)

    mp.set_property("keep-open", "always")

    -- Populate variables
    vars.path, vars.filename, vars.video_duration = path, filename, duration
end)

mp.add_key_binding(settings.key_mark_cut, "mark_pos", mark_pos)
mp.add_key_binding(settings.web.key_mark_cut, "web_mark_pos", web_mark_pos)
-- #endregion
