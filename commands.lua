minetest.register_chatcommand("ls", {
    func = function(name, params)
        local response = ls(name, "ls " .. params)
        return true, response
    end
})

minetest.register_chatcommand("cd", {
    func = function(name, params)
        change_directory(name, params)
        return true
    end
})

minetest.register_chatcommand("whereis", {
    func = function(name, params)
        local response = ""
        local matched = {}
        local sd_platforms = minetest.deserialize(sd:get_string("platforms"))
        for k, v in pairs(sd_platforms) do
            for i, j in pairs(platforms.storage_get(v, "listing")) do
                if string.match(i, params) then
                    local h = platforms.storage_get(v, "host_info")
                    table.insert(matched, {j = j, h = h})
                    response = response .. h.host .. ":" .. h.port .. " " ..
                                   j.path .. "\n"
                end
            end
        end
        spawn_matched(name, matched)
        return true, response .. "\n"
    end
})

minetest.register_on_chat_message(function(name, message)
    if string.match(message, "^cp") or string.match(message, "^mv") then
        local cmd, src, dst = parse_cmd_src_dst(message)

        -- check source
        local src_path, file_type, file_name = get_src_path_type(name, src)
        if not src_path then
            minetest.chat_send_player(name, "no source found")
            return true
        end

        -- check destination
        local plt_pos = dst_exists(dst, src_path, file_type)
        if not plt_pos then
            minetest.chat_send_player(name, "no destination spawned")
            return true
        end

        local entity, ent_pos = get_src_entity(name, file_name)

        local dst_pos = get_dst_pos(plt_pos, file_name)

        if dst_pos ~= nil then
            print("animate file")

            local direction = vector.direction(ent_pos, dst_pos)
            local fast_direction = vector.multiply(direction, 50)

            entity:set_velocity({x = 0, y = 10, z = 0})
            entity:set_acceleration(fast_direction)
        else
            print("process file in place")
        end
        return true
    end

    if string.match(message, "^ls") then
        if string.match(message, "^ls$") then
            reset_regex(name, message)
            return true
        end
        if string.match(message, "^ls | grep") then
            handle_regex(name, message)
            return true
        else
            local response = ls(name, message)
            minetest.chat_send_player(name, response)
            return true
        end
    end

    if string.match(message, "^cd") then
        local destination = string.match(message, "[^(^cd )]+$")
        change_directory(name, destination)
        return true
    end

    if string.match(message, "^[%a%d]+") then
        local command = string.match(message, "^[%a][%a%d/]+")
        if string.match(tostring(console_settings:get("commands")), command) then
            local node_pos = nmine.node_pos_near(name)
            local host_info = platforms.storage_get(node_pos, "host_info")
            local result = platforms.execute_cmd(host_info,
                                                 console_settings:get("lcmd"),
                                                 message)
            minetest.chat_send_player(name, result .. "\n")
            local old_listing = platforms.storage_get(node_pos, "listing")
            local new_listing = get_dir(host_info)
            compare_listings(node_pos, old_listing, new_listing)
            return true
        else
            return false
        end
    end

end)
