node_pos_near = function(name)
    local player = minetest.get_player_by_name(name)
    local pos = player:get_pos()
    local node_pos = minetest.find_node_near(pos, 6, {"mine9:platform"})
    return node_pos, player
end
ls = function(name, message)
    local node_pos = node_pos_near(name)
    local host_info = platforms.get_host_info(node_pos)
    local result = platforms.execute_cmd(host_info, config.lcmd,
                                         message .. " " .. host_info["path"])
    return result .. "\n"
end

cd = function(name, message)
    local node_pos, player = node_pos_near(name)
    local host_info = platforms.get_host_info(node_pos)
    local origin = platforms.get_creation_info(node_pos).origin
    local pos = get_next_pos(origin)
    host_info.path = host_info.path .. "/" .. message
    local content = get_dir(host_info)
    local orientation = "horizontal"
    local dir_size = content == nil and 2 or #content

    local platform_size = platforms.get_size_by_dir(dir_size)

    platforms.create(pos, platform_size, orientation, "mine9:platform")
    platforms.set_meta(pos, platform_size, "horizontal", "host_info", host_info)
    player:set_pos({x = pos.x + 1, y = pos.y + 1, z = pos.z + 1})
    list_dir(content, pos)

end
