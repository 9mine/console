ls = function(name, message)
    local node_pos = nmine.node_pos_near(name)
    local host_info = platforms.storage_get(node_pos, "host_info")
    local result = platforms.execute_cmd(host_info,
                                         console_settings:get("lcmd"),
                                         message .. " " .. host_info["path"])
    return result .. "\n"
end

cd = function(name, message) change_directory(name, message) end

spawn_help = function(name)
    local player = minetest.get_player_by_name(name)

    local position = player:get_pos()

    local look_dir = player:get_look_dir()

    local direction = vector.multiply(look_dir, 6)

    local destination = vector.add(vector.add(position, direction), {x = 0, y = 2, z = 0})

    local rotated_look_dir = vector.rotate(look_dir, {x = 0, y = math.pi/2, z = 0})

    for i = 1, 2 do 
        local left_right_direction = vector.multiply(rotated_look_dir, math.random(-4, 4))
        local final_position = vector.add(destination, left_right_direction)
        minetest.set_node(final_position, {name = "mine9:platform"})
    end

end