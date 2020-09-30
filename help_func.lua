ls = function(name, message)
    local node_pos = nmine.node_pos_near(name)
    local host_info = platforms.get_host_info(node_pos)
    local result = platforms.execute_cmd(host_info, config.lcmd,
                                         message .. " " .. host_info["path"])
    return result .. "\n"
end

cd = function(name, message)
    change_directory(name, message)
end
