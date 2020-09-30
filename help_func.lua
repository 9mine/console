ls = function(name)
    local player = minetest.get_player_by_name(name)
    local pos = player:get_pos()
    local node_pos = minetest.find_node_near(pos, 6, {"mine9:platform"})
    local host_info = platforms.get_host_info(node_pos)
    local content = get_dir(host_info)
    local response = ""
    for k, v in pairs(content) do response = response .. v.name .. "\n" end
    return response
end
