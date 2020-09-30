ls = function(name, message)
    local player = minetest.get_player_by_name(name)
    local pos = player:get_pos()
    local node_pos = minetest.find_node_near(pos, 6, {"mine9:platform"})
    local host_info = platforms.get_host_info(node_pos)
    local result = platforms.execute_cmd(host_info, config.lcmd, message .. " " .. host_info["path"])
    return result
end