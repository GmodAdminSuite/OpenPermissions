if (not pon) then
	include("openpermissions/thirdparty/pon.lua")
end
function OpenPermissions:SerializeTable(tbl)
	return pon.encode(tbl)
end
function OpenPermissions:DeserializeTable(tbl)
	return pon.decode(tbl)
end

local NetworkedTblCache = {}
function OpenPermissions:ClearNetworkCache(tbl)
	NetworkedTblCache[tostring(tbl)] = nil
end
function OpenPermissions:StartNetworkTable(tbl, cache, clear_cache)
	local tbl_enc
	if (cache and not clear_cache and NetworkedTblCache[tostring(tbl)] ~= nil) then
		tbl_enc = NetworkedTblCache[tostring(tbl)]
	else
		tbl_enc = util.Compress(OpenPermissions:SerializeTable(tbl))
		if (cache) then
			NetworkedTblCache[tostring(tbl)] = tbl_enc
		end
	end
	net.WriteUInt(#tbl_enc, 16)
	net.WriteData(tbl_enc, #tbl_enc)
end
function OpenPermissions:ReceiveNetworkTable()
	local tbl_enc_len = net.ReadUInt(16)
	local tbl_dec = OpenPermissions:DeserializeTable(util.Decompress(net.ReadData(tbl_enc_len)))
	return tbl_dec
end

--## SteamIDs ##--

function OpenPermissions:SteamID64ToAccountID(steamid64)
	return OpenPermissions:SteamIDToAccountID(util.SteamIDFrom64(steamid64))
end

function OpenPermissions:SteamIDToAccountID(steamid)
	local acc32 = tonumber(steamid:sub(11))
	return (acc32 * 2) + (1 - (acc32 % 2))
end

function OpenPermissions:AccountIDToSteamID(account_id)
	local sid32 = tonumber(account_id) / 2
	if (sid32 % 1 > 0) then
		return "STEAM_0:1:" .. math.floor(sid32)
	else
		return "STEAM_0:0:" .. sid32
	end
end

function OpenPermissions:AccountIDToSteamID64(account_id)
	return util.SteamIDTo64(OpenPermissions:AccountIDToSteamID(account_id))
end

--## Usergroup Management ##--

function OpenPermissions:IsUserGroup(ply, usergroup)
	return ply:IsUserGroup(usergroup) or hook.Run("OpenPermissions:IsUserGroup", ply, usergroup) or false
end

function OpenPermissions:GetUserGroups(ply)
	local usergroups_tbl = {[ply:GetUserGroup()] = true}
	hook.Run("OpenPermissions:GetUserGroups", ply, usergroups_tbl)
	return usergroups_tbl
end

--## Internal Operators Indexing ##--
OpenPermissions.IndexedOperators = {}
for _,_s in ipairs(OpenPermissions.Operators.SteamIDs) do
	local s = string.Trim(_s)
	if (s:find("^STEAM_%d:%d:%d+$")) then
		OpenPermissions.IndexedOperators[OpenPermissions:SteamIDToAccountID(s)] = true
	elseif (s:find("^7656119%d+$")) then
		OpenPermissions.IndexedOperators[OpenPermissions:SteamID64ToAccountID(s)] = true
	else
		OpenPermissions:Print("Invalid SteamID in config file; not a SteamID/SteamID64: \"" .. _s .. "\"", "[ERROR]", OpenPermissions.COLOR_RED)
	end
end

function OpenPermissions:IsOperator(ply)
	if (SERVER) then
		if (OpenPermissions.IndexedOperators[ply:AccountID()]) then
			return true
		end
	end
	for _,u in ipairs(OpenPermissions.Operators.Usergroups) do
		if (OpenPermissions:IsUserGroup(ply, u)) then
			return true
		end
	end
	if (hook.Run("OpenPermissions:IsOperator", ply) == true) then
		return true
	end
	return false
end

--## HasPermission ##--

function OpenPermissions:HasPermission(ply, permission_id)
	if (OpenPermissions:IsOperator(ply)) then return true end

	if (OpenPermissions.DefaultPermissions[permission_id] == OpenPermissions.CHECKED_CROSSED) then
		return false
	end

	local has_permission = false

	if (type(permission_id) == "table") then
		for _,v in ipairs(permission_id) do
			if (OpenPermissions:HasPermission(ply, v)) then
				return true
			end
		end
		return false
	end

	for usergroup in pairs(OpenPermissions:GetUserGroups(ply)) do
		local ply_usergroup_registry = OpenPermissions.PermissionsRegistry[OpenPermissions.ACCESS_GROUP.USERGROUP .. " " .. usergroup]
		if (ply_usergroup_registry) then
			if (ply_usergroup_registry[permission_id] == OpenPermissions.CHECKBOX.TICKED or ply_usergroup_registry[permission_id] == true) then
				has_permission = true
			elseif (ply_usergroup_registry[permission_id] == OpenPermissions.CHECKBOX.CROSSED) then
				return false
			end
		end
	end

	local ply_steamid_registry = OpenPermissions.PermissionsRegistry[OpenPermissions.ACCESS_GROUP.STEAMID .. " " .. ply:AccountID()]
	if (ply_steamid_registry) then
		if (ply_steamid_registry[permission_id] == OpenPermissions.CHECKBOX.TICKED or ply_steamid_registry[permission_id] == true) then
			has_permission = true
		elseif (ply_steamid_registry[permission_id] == OpenPermissions.CHECKBOX.CROSSED) then
			return false
		end
	end

	local ply_team_registry = OpenPermissions.PermissionsRegistry[OpenPermissions.ACCESS_GROUP.TEAM .. " " .. OpenPermissions:GetTeamIdentifier(ply:Team())]
	if (ply_team_registry) then
		if (ply_team_registry[permission_id] == OpenPermissions.CHECKBOX.TICKED or ply_team_registry[permission_id] == true) then
			has_permission = true
		elseif (ply_team_registry[permission_id] == OpenPermissions.CHECKBOX.CROSSED) then
			return false
		end
	end

	if (DarkRP) then
		local ply_category_name = RPExtraTeams[ply:Team()].category
		local ply_category
		for i,category in ipairs(DarkRP.getCategories().jobs) do
			if (category.name == ply_category_name) then
				ply_category = i
				break
			end
		end
		if (ply_category) then
			local ply_category_registry = OpenPermissions.PermissionsRegistry[OpenPermissions.ACCESS_GROUP.DARKRP_CATEGORY .. " " .. OpenPermissions:DarkRP_GetCategoryIdentifier(ply_category)]
			if (ply_category_registry) then
				if (ply_category_registry[permission_id] == OpenPermissions.CHECKBOX.TICKED or ply_category_registry[permission_id] == true) then
					has_permission = true
				elseif (ply_category_registry[permission_id] == OpenPermissions.CHECKBOX.CROSSED) then
					return false
				end
			end
		end
	end

	for name, func in pairs(OpenPermissions.LuaFunctions) do
		local lua_function_registry = OpenPermissions.PermissionsRegistry[OpenPermissions.ACCESS_GROUP.LUA_FUNCTION .. " " .. name]
		if (lua_function_registry) then
			if (func(ply, permission_id) == true) then
				if (lua_function_registry[permission_id] == OpenPermissions.CHECKBOX.TICKED or lua_function_registry[permission_id] == true) then
					has_permission = true
				elseif (lua_function_registry[permission_id] == OpenPermissions.CHECKBOX.CROSSED) then
					return false
				end
			end
		end
	end

	if (has_permission == false and OpenPermissions.DefaultPermissions[permission_id] == OpenPermissions.CHECKED_TICKED) then
		has_permission = true
	end

	return has_permission
end

--## Teams ##--

local team_identifier_index = {}
function OpenPermissions:GetTeamIdentifier(team_index)
	local team_identifier = hook.Run("OpenPermissions:GetTeamIdentifier", team_index)
	if (team_identifier) then
		team_identifier_index[team_identifier] = team_index
		return team_identifier
	end
	if (DarkRP) then
		local team_identifier = RPExtraTeams[team_index].OPENPERMISSIONS_IDENTIFIER or RPExtraTeams[team_index].GAS_IDENTIFIER or RPExtraTeams[team_index].command
		team_identifier_index[team_identifier] = team_index
		return team_identifier
	else
		local team_identifier = team.GetName(team_index)
		team_identifier_index[team_identifier] = team_index
		return team_identifier
	end
end

function OpenPermissions:GetTeamFromIdentifier(team_identifier)
	if (team_identifier_index[team_identifier]) then return team_identifier_index[team_identifier] end

	local team_index = hook.Run("OpenPermissions:GetTeamFromIdentifier", team_identifier)
	if (team_index) then
		team_identifier_index[team_identifier] = team_index
		return team_index
	end
	if (DarkRP) then
		for _,job in pairs(RPExtraTeams) do
			if (job.OPENPERMISSIONS_IDENTIFIER == team_identifier or job.OPENPERMISSIONS_IDENTIFIER == team_identifier or job.command == team_identifier) then
				team_identifier_index[team_identifier] = job.team
				return job.team
			end
		end
	else
		for i,t in ipairs(team.GetAllTeams()) do
			if (t.Name == team_identifier) then
				team_identifier_index[team_identifier] = i
				return i
			end
		end
	end
end

local category_identifier_index = {}
function OpenPermissions:DarkRP_GetCategoryIdentifier(category_index)
	local category_identifier = hook.Run("OpenPermissions:DarkRP_GetCategoryIdentifier", category_index)
	if (category_identifier) then
		category_identifier_index[category_identifier] = category_index
		return category_identifier
	end

	local category = DarkRP.getCategories().jobs[category_index]
	local category_identifier = category.OPENPERMISSIONS_IDENTIFIER or category.GAS_IDENTIFIER or category.name

	category_identifier_index[category_identifier] = category_index
	return category_identifier
end

function OpenPermissions:DarkRP_GetCategoryFromIdentifier(category_identifier)
	if (category_identifier_index[category_identifier]) then return category_identifier_index[category_identifier] end

	local category_index = hook.Run("OpenPermissions:DarkRP_GetCategoryFromIdentifier", category_identifier)
	if (category_index) then
		category_identifier_index[category_index] = category_identifier
		return category_index
	end

	for i,category in pairs(DarkRP.getCategories().jobs) do
		local category_id = category.OPENPERMISSIONS_IDENTIFIER or category.GAS_IDENTIFIER or category.name
		if (category_id == category_identifier) then
			category_identifier_index[category_id] = i
			return i
		end
	end
end

--## Misc ##--

function OpenPermissions:table_IsEmpty(tbl)
	return next(tbl) == nil
end

function OpenPermissions:table_IsIdentical(tbl1, tbl2)
	local function r(tbl1, tbl2)
		for key, val in pairs(tbl1) do
			if (tbl2[key] == nil) then
				return false
			elseif (type(val) == "table") then
				if (r(val, tbl2[key]) == false) then
					return false
				end
			elseif (tbl2[key] ~= val) then
				return false
			end
		end
		for key, val in pairs(tbl2) do
			if (tbl1[key] == nil) then
				return false
			elseif (type(val) == "table") then
				if (r(val, tbl1[key]) == false) then
					return false
				end
			elseif (tbl1[key] ~= val) then
				return false
			end
		end
	end
	return r(tbl1, tbl2) ~= false
end

--## Enums ##--

OpenPermissions.ADDON = 0
OpenPermissions.PERMISSION = 1
OpenPermissions.CATEGORY = 2
OpenPermissions.SUBPERMISSION = 3

OpenPermissions.CHECKED_INHERIT = 0
OpenPermissions.CHECKED_TICKED = 1
OpenPermissions.CHECKED_CROSSED = 2

--## Networking ##--

OpenPermissions.PermissionsRegistry = {}
OpenPermissions.DefaultPermissions = {}
if (SERVER) then
	if (file.Exists("openpermissions.dat", "DATA")) then
		local read_file = file.Read("openpermissions.dat", "DATA")
		if (not read_file) then
			OpenPermissions:Print("Failed to read saved permissions data", "[ERROR]", OpenPermissions.COLOR_RED)
		else
			read_file = util.Decompress(read_file)
			if (not read_file) then
				OpenPermissions:Print("Failed to decompress saved permissions data", "[ERROR]", OpenPermissions.COLOR_RED)
			else
				local no_errors, deserialized = pcall(function()
					return OpenPermissions:DeserializeTable(read_file)
				end)
				if (not no_errors) then
					OpenPermissions:Print("Failed to deserialize decompressed saved permissions data", "[ERROR]", OpenPermissions.COLOR_RED)
				else
					OpenPermissions:Print("Saved permissions data successfully loaded", "[INFO]", OpenPermissions.COLOR_GREEN)
					OpenPermissions.PermissionsRegistry = deserialized
				end
			end
		end
	end
	net.Receive("OpenPermissions.SavePermissions", function(_, ply)
		if (not OpenPermissions:IsOperator(ply)) then return end
		OpenPermissions.PermissionsRegistry = OpenPermissions:ReceiveNetworkTable()
		
		file.Write("openpermissions.dat", util.Compress(OpenPermissions:SerializeTable(OpenPermissions.PermissionsRegistry)))

		net.Start("OpenPermissions.PermissionsRegistry")
			OpenPermissions:StartNetworkTable(OpenPermissions.PermissionsRegistry, true, true)
			OpenPermissions:StartNetworkTable(OpenPermissions.DefaultPermissions, true)
		net.SendOmit(ply)
	end)
	net.Receive("OpenPermissions.PermissionsRegistry", function(_, ply)
		net.Start("OpenPermissions.PermissionsRegistry")
			OpenPermissions:StartNetworkTable(OpenPermissions.PermissionsRegistry, true)
			OpenPermissions:StartNetworkTable(OpenPermissions.DefaultPermissions, true)
		net.Send(ply)
	end)
else
	net.Receive("OpenPermissions.PermissionsRegistry", function()
		OpenPermissions.PermissionsRegistry = OpenPermissions:ReceiveNetworkTable()
		OpenPermissions.DefaultPermissions = OpenPermissions:ReceiveNetworkTable()
		OpenPermissions:Print("Received permissions registry", "[INFO]")
	end)
	if (OpenPermissions_PermissionsRegistry_InitPostEntity) then
		net.Start("OpenPermissions.PermissionsRegistry")
		net.SendToServer()
	else
		hook.Add("InitPostEntity", "OpenPermissions.PermissionsRegistry", function()
			OpenPermissions_PermissionsRegistry_InitPostEntity = true
			net.Start("OpenPermissions.PermissionsRegistry")
			net.SendToServer()
		end)
	end
end