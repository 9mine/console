ls = function(name, message)
    local node_pos = nmine.node_pos_near(name)
    local host_info = platforms.storage_get(node_pos, "host_info")
    local result = platforms.execute_cmd(host_info,
                                         console_settings:get("lcmd"),
                                         message .. " " .. host_info["path"])
    return result .. "\n"
end

cd = function(name, message) change_directory(name, message) end

stop = function(entity, p)
    local y = entity:get_pos().y
    if (y - p) < 3 then
        entity:set_velocity({x = 0, y = 0, z = 0})
    else
        minetest.after(0.05, stop, entity, p)
    end
end

spawn_help = function(name)
    local player = minetest.get_player_by_name(name)

    local position = player:get_pos()

    local look_dir = player:get_look_dir()

    local direction = vector.multiply(look_dir, 6)

    local destination = vector.add(vector.add(position, direction),
                                   {x = 0, y = 2, z = 0})

    local rotated_look_dir = vector.rotate(look_dir,
                                           {x = 0, y = math.pi / 2, z = 0})
    local help = {"HELP", "HILFEN"}
    for k, v in ipairs(help) do
        local left_right_direction = vector.multiply(rotated_look_dir,
                                                     math.random(-4, 4))
        local final_position = vector.add(destination, left_right_direction)
        local entity = minetest.add_entity(
                           {
                x = final_position.x,
                y = final_position.y + 10,
                z = final_position.z
            }, "directories:file")
        entity:set_properties({physical = false})
        entity:set_nametag_attributes({color = "black", text = v})
        entity:set_velocity({x = 0, y = -9.81, z = 0})
        minetest.after(0.05, stop, entity, position.y)
    end

end

