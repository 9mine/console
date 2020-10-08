-- parse string in format "<cmd> <source> <destination>" 
-- (where <cmd> is 'mv' or 'cp', source - file on current platform
-- and destination is any path)
parse_cmd_src_dst = function(message)
    local t = {}
    for str in string.gmatch(message, "[^ ]+") do table.insert(t, str) end
    local cmd = t[1]
    local src = t[2]
    local dst = t[3]
    return cmd, src, dst
end

-- get path of current platform, type of file (dir or file) 
-- and parse file_name from provided source string
get_src_path_type = function(name, src)
    -- get platform path
    local node_pos = nmine.node_pos_near(name)
    local src_path = platforms.storage_get(node_pos, "host_info").path

    -- get source file type
    local type = nil
    local listing = platforms.storage_get(node_pos, "listing")
    local file_name = string.match(string.match(src, "/?%a+/?$"), "%a+")
    if file_name ~= nil then
        type = listing[file_name] ~= nil and listing[file_name].type
    end
    if not type then return nil end
    return src_path, type, file_name
end

-- return entity reference and position of the file
-- represented by file_name 
get_src_entity = function(name, file_name)
    local node_pos = nmine.node_pos_near(name)
    local listing = platforms.storage_get(node_pos, "listing")
    local p = listing[file_name].pos
    -- set position higher for entity to be in the searching radius
    p.y = listing[file_name].pos.y + 1.5
    local entity = minetest.get_objects_inside_radius(p, 1)[1]
    return entity, p
end

-- return platforms coordinates if destination exists, nil otherwise 
dst_exists = function(dst, src_path, type)
    local sd_platforms = minetest.deserialize(sd:get_string("platforms"))
    local dst_dir = src_path
    local path = dst

    -- if destination is relational, append source path
    if not string.match(dst, "^/") then
        path = src_path == "/" and src_path .. dst or src_path .. "/" .. dst
    end

    -- if destination is root
    if string.match(path, "^/$") then
        for _, plt_pos in pairs(sd_platforms) do
            if platforms.storage_get(plt_pos, "host_info").path == "/" then
                return plt_pos
            end
        end
    end
    -- if trailing shash, remove
    if string.match(path, "/$") then
        dst_dir = string.match(path, ".*[^/]")
    end

    -- if path ends with name, check is exists and is it dir or file
    if string.match(path, "/%a+$") then
        -- handle if parent dir is root
        local parent_dst_dir = string.match(path, "^/%a+$") and "/" or
                                   string.match(string.match(path, ".*/"),
                                                ".*[^/]")
        for _, plt_pos in pairs(sd_platforms) do
            if platforms.storage_get(plt_pos, "host_info").path ==
                parent_dst_dir then
                local dst_dir_or_file_name = string.match(path, "%a+$")
                local dst_dir_or_file =
                    platforms.storage_get(plt_pos, "listing")[dst_dir_or_file_name]

                -- if dst is not exist, create file in parent directory
                if (not dst_dir_or_file) then
                    dst_dir = parent_dst_dir
                    return dst_dir
                end

                -- if dst is directory, use it as a base
                if dst_dir_or_file.type == 128 then
                    dst_dir = path
                end

                -- cant'move dir to file
                if type == 128 and dst_dir_or_file.type ~= 128 then
                    dst_dir = nil
                    return
                end

                if type ~= 128 and dst_dir_or_file.type ~= 128 then
                    dst_dir = parent_dst_dir
                end
            end
        end
    end
    for _, plt_pos in pairs(sd_platforms) do
        if platforms.storage_get(plt_pos, "host_info").path == dst_dir then
            return plt_pos
        end
    end
end

-- return nil if file with given file_name already exists
-- at destination or give next empty slot if not
get_dst_pos = function(plt_pos, file_name)
    if platforms.storage_get(plt_pos, "listing") then
        local file_pos = platforms.storage_get(plt_pos, "listing")[file_name]
        if file_pos then return file_pos.pos end
    end
    local empty_slots = platforms.storage_get(plt_pos, "empty_slots")
    local index, empty_slot = next(empty_slots)
    table.remove(empty_slots, index)
    platforms.storage_set(plt_pos, "empty_slots", empty_slots)
    return empty_slot
end
