print("Console mod is loading . . .  ")
local path = minetest.get_modpath("console")
console_settings = Settings(path .. "/mod.conf")
dofile(path .. "/help_func.lua")
dofile(path .. "/commands.lua")
print("Console mod successfully loaded.")