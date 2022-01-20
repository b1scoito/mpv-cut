---@diagnostic disable: lowercase-global, undefined-global

msg = require("mp.msg")
utils = require("mp.utils")

-- #region globals
local settings = {
    key_mark_cut = "c",
    video_ext = "mp4"
}

local var = {
    str_path = nil,
    str_dir = nil,
    str_filename = nil,

    sec_duration = nil
}

local pos = {
    start_pos = nil,
    end_pos = nil
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
    pos.start_pos = nil
    pos.end_pos = nil
end
-- #endregion

function ffmpeg_cut(time_start, time_end, input_file, output_file)
    mp.command_native_async({
        name = "subprocess",
        args = {"ffmpeg", "-ss", time_start, "-to", time_end, "-i", input_file, "-c", "copy", output_file}
    }, function(res, val, err)
        if err then
            msg.error(err)
            return err
        end
    end)

    return nil
end

-- #region main
function mark_cut_pos()
    local current_pos = mp.get_property_number("time-pos")

    if not pos.start_pos then
        pos.start_pos = current_pos
        mp.osd_message(string.format("Marked %s as start position", current_pos), 5)
        return
    end

    pos.end_pos = current_pos

    if pos.start_pos >= pos.end_pos then
        mp.osd_message(string.format("Invalid time to cut!", current_pos), 5)
        reset_pos()
        return
    end

    mp.osd_message(string.format("Marked %s as end position", current_pos), 5)
    
    local output_name = string.format("%s-cut.%s", str_split(var.str_filename, ".")[1], settings.video_ext)
    -- Cut
    if ffmpeg_cut(to_timestamp(pos.start_pos), to_timestamp(pos.end_pos), var.str_path, output_name) then
        mp.osd_message("Failed to execute FFmpeg!", 10)
    end

    -- Reset vars
    reset_pos()

    mp.osd_message(string.format("Saved as %s successfully.", output_name), 5)
    
end
-- #endregion

mp.register_event("file-loaded", function()
    local duration = mp.get_property("duration")
    local path = mp.get_property("path")
    local dir, filename = utils.split_path(path)

    -- Populate variables
    var.str_path, var.str_dir, var.str_filename, var.sec_duration = path, dir, filename, duration
end)

mp.add_key_binding(settings.key_mark_cut, "mark_cut_pos", mark_cut_pos)