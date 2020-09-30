minetest.register_chatcommand("ls", {
    func = function(name, params) 
        local response = ls(name)
        return true, response
    end
})