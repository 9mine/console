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
remove_file = function(file) file:remove() end
reset_regex = function(name)
    local node_pos = nmine.node_pos_near(name)
    local listing = platforms.storage_get(node_pos, "listing")
    for name, file in pairs(listing) do
        local p = file.pos
        p.y = file.pos.y + 1
        local entities = minetest.get_objects_inside_radius(p, 1)
        while next(entities) ~= nil do
            local x, y = next(entities)
            if y:is_player() then
            else
                y:set_properties({is_visible = true})
            end
            table.remove(entities, x)
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
            p.y = file.pos.y + 1
            local entities = minetest.get_objects_inside_radius(p, 1)
            while next(entities) ~= nil do
                local x, y = next(entities)
                if y:is_player() then
                else
                    y:set_properties({is_visible = false})
                end
                table.remove(entities, x)
            end
        end
    end
end
