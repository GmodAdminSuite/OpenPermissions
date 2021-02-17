OpenPermissions_Readying = true
OpenPermissions_Ready = nil

if (CLIENT and IsValid(OpenPermissions_Menu)) then
	OpenPermissions_Menu:Close()
end

OpenPermissions = {}
OpenPermissions.pon = include("openpermissions/thirdparty/pon.lua")

OpenPermissions.Version = "v1.0"

OpenPermissions.COLOR_WHITE      = Color(255,255,255)
OpenPermissions.COLOR_LIGHT_BLUE = Color(0,255,255)
OpenPermissions.COLOR_YELLOW     = Color(0,255,255)
OpenPermissions.COLOR_RED        = Color(255,0,0)
OpenPermissions.COLOR_GREEN      = Color(0,255,0)
OpenPermissions.COLOR_BLACK      = Color(0,0,0)
OpenPermissions.COLOR_SOFT_GREEN = Color(76,216,76)
OpenPermissions.COLOR_SOFT_RED   = Color(216,76,76)

local version_info = "Version: " .. OpenPermissions.Version
local padding = (65 - #version_info) / 2
local version_str = (" "):rep(math.ceil(padding)) .. version_info .. (" "):rep(math.floor(padding))

local github_link = "https://github.com/WilliamVenner/GLua-OpenPermissions"
local padding = (65 - #github_link) / 2
local github_str = (" "):rep(math.ceil(padding)) .. github_link .. (" "):rep(math.floor(padding))

MsgC(OpenPermissions.COLOR_YELLOW, [[

     _____             _____               _         _             
    |     |___ ___ ___|  _  |___ ___ _____|_|___ ___|_|___ ___ ___ 
    |  |  | . | -_|   |   __| -_|  _|     | |_ -|_ -| | . |   |_ -|
    |_____|  _|___|_|_|__|  |___|_| |_|_|_|_|___|___|_|___|_|_|___|
          |_|                                                      

]])
MsgC(OpenPermissions.COLOR_GREEN,  "  [=================================================================]\n")
MsgC(OpenPermissions.COLOR_YELLOW, "  [" ..                       version_str                       .. "]\n")
MsgC(OpenPermissions.COLOR_YELLOW, "  [" ..                       github_str                        .. "]\n")
MsgC(OpenPermissions.COLOR_GREEN,  "  [=================================================================]\n\n")

function OpenPermissions:Print(msg, prefix, color)
	MsgC(color or Color(0,255,255), "[OpenPermissions] " .. (prefix or "") .. " ", Color(255,255,255), msg, "\n")
end
function OpenPermissions:ChatPrint(msg, prefix, color)
	chat.AddText(color or Color(0,255,255), "[OpenPermissions] " .. (prefix or "") .. " ", Color(255,255,255), msg)
end

--## BillysErrors ##--

if (file.Exists("includes/modules/billyserrors.lua", "LUA")) then
	require("billyserrors")
end
if (SERVER and BillysErrors) then
	OpenPermissions.BillysErrors = BillysErrors:AddAddon({
		Name  = "OpenPermissions",
		Color = Color(80,0,255),
		Icon  = "icon16/group.png",
	})
end

--## Initialize configs ##--
OpenPermissions.Operators = {}

local function InstallConfigAddon()
	if (SERVER and BillysErrors) then
		OpenPermissions.BillysErrors:AddMessage("Looks like the OpenPermissions Config Addon has not been installed to your server: ", {Link = "https://gmodsto.re/openpermissions-config-addon"}, "\nYou need to install this addon in order to use & configure OpenPermissions.")
	else
		OpenPermissions:Print("Looks like the OpenPermissions Config Addon has not been installed to your server: https://gmodsto.re/openpermissions-config-addon\nYou need to install this addon in order to use & configure OpenPermissions.", "[ERROR]", OpenPermissions.COLOR_RED)
	end
end

if (not file.Exists("openpermissions_config.lua", "LUA")) then
	return InstallConfigAddon()
else
	local config_worked = include("openpermissions_config.lua")
	if (not config_worked) then
		if (SERVER and BillysErrors) then
			OpenPermissions.BillysErrors:AddMessage("Your config file appears to have an error! Please fix the errors by looking above or by resetting to the default config.")
		else
			OpenPermissions:Print("Your config file appears to have an error! Please fix the errors by looking above or by resetting to the default config.", "[ERROR]", OpenPermissions.COLOR_RED)
		end
		return
	end
end

if (not file.Exists("openpermissions_lua_functions.lua", "LUA")) then
	return InstallConfigAddon()
else
	local config_worked = include("openpermissions_lua_functions.lua")
	if (not config_worked) then
		if (SERVER and BillysErrors) then
			OpenPermissions.BillysErrors:AddMessage("Your Lua functions file appears to have an error! Please fix the errors by looking above or by resetting to the default Lua functions config.")
		else
			OpenPermissions:Print("Your Lua functions file appears to have an error! Please fix the errors by looking above or by resetting to the default Lua functions config.", "[ERROR]", OpenPermissions.COLOR_RED)
		end
		return
	else
		OpenPermissions.LuaFunctions = config_worked
	end
end

--## Languages ##--

if (CLIENT) then
	function OpenPermissions.L(phrase)
		return OpenPermissions.LANG.Phrases[phrase] or OpenPermissions.LANG_ENGLISH.Phrases[phrase] or phrase
	end
	function OpenPermissions.Lf(phrase, ...)
		return (OpenPermissions.LANG.Phrases[phrase] or OpenPermissions.LANG_ENGLISH.Phrases[phrase] or phrase):format(...)
	end

	function OpenPermissions:LoadPhrasebook()
		if (not file.Exists("openpermissions_lang.txt", "DATA")) then
			file.Write("openpermissions_lang.txt", "english")
		end
		local selected_language = file.Read("openpermissions_lang.txt", "DATA")
		if (not selected_language or not file.Find("openpermissions/lang/" .. selected_language .. ".lua", "LUA")) then selected_language = "english" end
		OpenPermissions.LANG_ENGLISH = include("openpermissions/lang/english.lua")
		if (selected_language == "english" or not file.Exists("openpermissions/lang/" .. selected_language .. ".lua", "LUA")) then
			OpenPermissions.LANG = OpenPermissions.LANG_ENGLISH or {}
		else
			OpenPermissions.LANG = include("openpermissions/lang/" .. selected_language .. ".lua") or {}
		end
	end
	OpenPermissions:LoadPhrasebook()
else
	local fs = file.Find("openpermissions/lang/*.lua", "LUA")
	for _,f in ipairs(fs) do
		AddCSLuaFile("openpermissions/lang/" .. f)
	end
end

--## Enums and Data Structures ##--

OpenPermissions.ACCESS_GROUP = {}
OpenPermissions.ACCESS_GROUP.USERGROUP = 1
OpenPermissions.ACCESS_GROUP.STEAMID = 2
OpenPermissions.ACCESS_GROUP.TEAM = 3
OpenPermissions.ACCESS_GROUP.LUA_FUNCTION = 4
OpenPermissions.ACCESS_GROUP.DARKRP_CATEGORY = 5

OpenPermissions.ACCESS_GROUP_KEY = {
	[OpenPermissions.ACCESS_GROUP.USERGROUP] = Color(216,76,76),
	[OpenPermissions.ACCESS_GROUP.STEAMID] = Color(81,174,255),
	[OpenPermissions.ACCESS_GROUP.TEAM] = Color(76,216,76),
	[OpenPermissions.ACCESS_GROUP.LUA_FUNCTION] = Color(76,76,216),
	[OpenPermissions.ACCESS_GROUP.DARKRP_CATEGORY] = Color(255,163,71),
}

OpenPermissions.CHECKBOX = {}
OpenPermissions.CHECKBOX.INHERIT = 0
OpenPermissions.CHECKBOX.TICKED = 1
OpenPermissions.CHECKBOX.CROSSED = 2

--## Add resources ##--

if (SERVER) then
	resource.AddWorkshop("1603635147")
	for _,f in ipairs((file.Find("materials/openpermissions/*.vmt", "GAME"))) do
		resource.AddFile("materials/openpermissions/" .. f)
	end
end

local function IsDarkRPCheck()
	hook.Remove(SERVER and "PlayerConnect" or "InitPostEntity", "OpenPermissions.IsDarkRP")
	OpenPermissions.IsDarkRP = DarkRP and DarkRP.getCategories and RPExtraTeams and true
end
hook.Add(SERVER and "PlayerConnect" or "InitPostEntity", "OpenPermissions.IsDarkRP", IsDarkRPCheck)

--## Initialize files ##--
include("openpermissions/sh.lua")
if (SERVER) then
	AddCSLuaFile("openpermissions/thirdparty/pon.lua")
	AddCSLuaFile("openpermissions_config.lua")
	AddCSLuaFile("openpermissions_lua_functions.lua")
	AddCSLuaFile("openpermissions/sh.lua")
	AddCSLuaFile("openpermissions/cl.lua")

	include("openpermissions/sv.lua")
else
	include("openpermissions/cl.lua")
end