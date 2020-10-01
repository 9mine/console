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

minetest.register_on_chat_message(function(name, message)
    if string.match(message, "^ls") then
        local response = ls(name, message)
        minetest.chat_send_player(name, response)
        return true
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
