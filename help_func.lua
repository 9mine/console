ls = function(name, message)
    local node_pos = nmine.node_pos_near(name)
    local host_info = platforms.storage_get(node_pos, "host_info")
    local result = platforms.execute_cmd(host_info,
                                         console_settings:get("lcmd"),
                                         message .. " " .. host_info["path"])
    return result .. "\n"
end

cd = function(name, message) change_directory(name, message) end

parse_cmd_src_dst = function(message)
    local t = {}
    for str in string.gmatch(message, "[^ ]+") do table.insert(t, str) end
    local cmd = t[1]
    local src = t[2]
    local dst = t[3]
    return cmd, src, dst
end

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

get_src_entity = function(name, file_name)
    local node_pos = nmine.node_pos_near(name)
    local listing = platforms.storage_get(node_pos, "listing")
    local p = listing[file_name].pos
    p.y = listing[file_name].pos.y + 1.5
    local entity = minetest.get_objects_inside_radius(p, 1)[1]
    return entity, p

end

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
    if string.match(path, "/$") then dst_dir = string.match(path, ".*[^/]") end

    -- if path ends with name, check is exists and is it dir or file
    if string.match(path, "/%a+$") then
        local parent_dst_dir = string.match(path, "^/%a+$") and "/" or string.match(string.match(path, ".*/"), ".*[^/]")
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

get_dst_pos = function(plt_pos, file_name)
    if platforms.storage_get(plt_pos, "listing")[file_name] then
        return nil
    else
        local empty_slots = platforms.storage_get(plt_pos, "empty_slots")
        local index, empty_slot = next(empty_slots)
        table.remove(empty_slots, index)
        platforms.storage_set(plt_pos, "empty_slots", empty_slots)
        return empty_slot
    end
end

stop = function(entity, p)
    local y = entity:get_pos().y
    if (y - p) < 3 then
        entity:set_velocity({x = 0, y = 0, z = 0})
    else
        minetest.after(0.05, stop, entity, p)
    end
end

spawn_matched = function(name, matched)
    local player = minetest.get_player_by_name(name)
    local position = player:get_pos()
    local look_dir = player:get_look_dir()
    local direction = vector.multiply(look_dir, 6)
    local destination = vector.add(vector.add(position, direction),
                                   {x = 0, y = 2, z = 0})

    local rot_dir = vector.rotate(look_dir, {x = 0, y = math.pi / 2, z = 0})

    local spawn_line = {}
    local remove_line = {}
    for i = -4, 4 do table.insert(spawn_line, vector.multiply(rot_dir, i)) end
    spawn_line = nmine.shuffle(spawn_line)

    for k, file in pairs(matched) do
        local index, spawn_dest = next(spawn_line)
        if not spawn_dest then return end
        table.remove(spawn_line, index)
        local spawn_pos = vector.add(destination, spawn_dest)

        table.insert(remove_line, spawn_pos)
        spawn_pos.y = spawn_pos.y + 10
        local name = file.h.host .. ":" .. file.h.port .. "\n" .. file.j.path
        local entity = minetest.add_entity(spawn_pos, file.j.type == 128 and
                                               "directories:dir" or
                                               "directories:file")

        entity:set_nametag_attributes({color = "black", text = name})
        entity:set_armor_groups({immortal = 0})
        entity:set_properties({physical = false})
        entity:set_velocity({x = 0, y = -9.81, z = 0})
        entity:get_luaentity().path = file.j.path

        local front_of_entity = vector.subtract(file.j.pos,
                                                {x = 0, y = 0, z = 2})

        entity:get_luaentity().on_punch =
            function(self, puncher)
                for k, v in pairs(remove_line) do
                    v.y = v.y - 10
                    local objects = minetest.get_objects_inside_radius(v, 4)
                    while next(objects) ~= nil do
                        local x, y = next(objects)
                        if y:is_player() then
                        else
                            y:remove()
                        end
                        table.remove(objects, x)
                    end
                end

                local state = puncher:set_look_vertical(0.3490)
                puncher:set_look_horizontal(0)
                puncher:set_pos(front_of_entity)
            end

        minetest.after(0.05, stop, entity, position.y)
    end

end

shadow_file = function(file, pos)

    file:set_acceleration({x = 0, y = 0, z = 0})
    file:set_pos(pos)
end

stop = function(file, pos)
    file:set_properties({is_visible = false})
    file:set_acceleration({x = 0, y = -9.81, z = 0})
    pos.y = pos.y + 10
    file:set_pos(pos)
end
reset_regex = function(name)
    local node_pos = nmine.node_pos_near(name)
    local listing = platforms.storage_get(node_pos, "listing")
    for name, file in pairs(listing) do
        local p = file.pos
        p.y = file.pos.y + 11
        local e = minetest.get_objects_inside_radius(p, 1)[1]
        if e then
            e:set_properties({is_visible = true, physical = true})
            e:set_acceleration({x = 0, y = -9.81, z = 0})
        end
    end
end

handle_regex = function(name, message)
    local regex = string.gsub(message, "ls | grep ", "")
    local node_pos = nmine.node_pos_near(name)
    local listing = platforms.storage_get(node_pos, "listing")

    for name, file in pairs(listing) do
        if not string.match(name, regex) then
            local p = file.pos
            p.y = file.pos.y + 1.5
            local e = minetest.get_objects_inside_radius(p, 1)[1]
            e:set_acceleration({x = 0, y = 9.81, z = 0})
            minetest.after(1, stop, e, file.pos)
            minetest.after(2, shadow_file, e, file.pos)
        end
    end
end
