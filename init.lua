print("Console mod is loading . . .  ")
config = luaconfig.loadConfig();
local path = minetest.get_modpath("console")
dofile(path .. "/help_func.lua")
dofile(path .. "/config.lua")
dofile(path .. "/commands.lua")
print("Console mod successfully loaded.")