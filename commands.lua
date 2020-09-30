minetest.register_chatcommand("ls", {
    func = function(name, params)
        local response = ls(name, "ls")
        return true, response
    end
})

minetest.register_on_chat_message(function(name, message)
    if string.match(message, "^ls ") then
        local response = ls(name, message)
        minetest.chat_send_player(name, response)
        return true
    end
end)
