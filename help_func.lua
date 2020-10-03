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

spawn_matched = function(name, matched)
    local player = minetest.get_player_by_name(name)
    local position = player:get_pos()
    local look_dir = player:get_look_dir()
    local direction = vector.multiply(look_dir, 6)
    local destination = vector.add(vector.add(position, direction),
                                   {x = 0, y = 2, z = 0})

    local rotated_look_dir = vector.rotate(look_dir,
                                           {x = 0, y = math.pi / 2, z = 0})
    local free_space = {}
    for i = -4, 4 do table.insert(free_space, i) end

    free_space = nmine.shuffle(free_space)

    for k, file in pairs(matched) do
        local index, slot = next(free_space)
        if not slot then return end
        local left_right_direction = vector.multiply(rotated_look_dir, slot)
        table.remove(free_space, index)
        local final_position = vector.add(destination, left_right_direction)

        final_position.y = final_position.y + 10
        local name = file.h.host .. ":" .. file.h.port .. "\n" .. file.j.path
        local entity = minetest.add_entity(final_position,
                                           file.j.type == 128 and
                                               "directories:dir" or
                                               "directories:file")

        entity:set_nametag_attributes({color = "black", text = name})
        entity:set_armor_groups({immortal = 0})
        entity:set_properties({physical = false})
        entity:set_velocity({x = 0, y = -9.81, z = 0})
        entity:get_luaentity().path = file.j.path

        local front_of_entity = vector.subtract(file.j.pos, {x = 0, y = 0, z = 2} )

        entity:get_luaentity().on_punch =
            function(self, puncher) 
                puncher:set_look_vertical(0.3490)
                puncher:set_look_horizontal(0)
                puncher:set_pos(front_of_entity) 
            end
            
        minetest.after(0.05, stop, entity, position.y)
    end

end

