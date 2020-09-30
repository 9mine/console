minetest.register_chatcommand("ls", {
    func = function(name, params)
        local response = ls(name)
        return true, response
    end
})

minetest.register_on_chat_message(function(name, message)
    if message == "ls" then
        local response = ls(name)
        minetest.chat_send_player(name, response)
        return true
    end
end)
