function OpenPermissions:CreatePermissionsRegistry()
	local registry = {}
	for _, enum in pairs(OpenPermissions.ACCESS_GROUP) do registry[enum] = {} end
	return registry
end

OpenPermissions.REGISTRY = {}
OpenPermissions.REGISTRY.NETWORKED = 0
OpenPermissions.REGISTRY.FLAT_FILE = 1
function OpenPermissions:SerializeRegistry(dataType)
	if (dataType == OpenPermissions.REGISTRY.NETWORKED) then

		if (file.Exists("openpermissions_v2.dat", "DATA")) then
			-- Lazy but still probably quicker
			local data = file.Read("openpermissions_v2.dat", "DATA")
			net.WriteUInt(#data, 32)
			net.WriteData(data, #data)
		else
			net.WriteUInt(0, 32)
		end

	elseif (dataType == OpenPermissions.REGISTRY.FLAT_FILE) then

		local f = file.Open("openpermissions_v2.dat", "wb", "DATA")

		-- Write file header
		f:Write("OPENPERMISSIONS")

		local ids = {}
		local id = 0
		local ids_pos = f:Tell()
		f:Seek(ids_pos + (32 / 8)) -- Allocate a UShort for seeker position of IDs

		-- Write permissions registry
		local access_group_count = 0
		local access_group_pos = f:Tell()
		f:Seek(access_group_pos + (32 / 8))
		for access_group, accessors in pairs(OpenPermissions.PermissionsRegistry) do
			f:WriteUShort(access_group)
			access_group_count = access_group_count + 1

			local accessors_count = 0
			local accessors_pos = f:Tell()
			f:Seek(accessors_pos + (32 / 8))
			for accessor, permissions in pairs(accessors) do
				if (isnumber(accessor)) then
					f:WriteBool(false)
					f:WriteULong(accessor)
				elseif (isstring(accessor)) then
					f:WriteBool(true)
					f:WriteUShort(#accessor)
					f:Write(accessor)
				else
					error("Invalid accessor key type! (" .. type(accessor) .. ")")
				end
				accessors_count = accessors_count + 1

				local permissions_count = 0
				local permissions_pos = f:Tell()
				f:Seek(permissions_pos + (32 / 8))
				for permission_id, access in pairs(permissions) do
					if (not ids[permission_id]) then
						id = id + 1
						ids[permission_id] = id
					end
					f:WriteUShort(ids[permission_id])
					f:WriteBool(access == OpenPermissions.CHECKBOX.INHERIT)
					f:WriteBool(access == OpenPermissions.CHECKBOX.TICKED)
					permissions_count = permissions_count + 1
				end
				local pos = f:Tell()
				f:Seek(permissions_pos)
				f:WriteULong(permissions_count)
				f:Seek(pos)
			end
			local pos = f:Tell()
			f:Seek(accessors_pos)
			f:WriteULong(accessors_count)
			f:Seek(pos)
		end
		local pos = f:Tell()
		f:Seek(access_group_pos)
		f:WriteULong(access_group_count)
		f:Seek(pos)

		-- Write IDs
		local count = 0
		local countPos = f:Tell()
		f:Seek(countPos + (32 / 8)) -- We can seek back and write the count here
		for str, id in pairs(ids) do
			f:WriteUShort(#str)
			f:Write(str)
			f:WriteUShort(id)
			count = count + 1
		end
		f:Seek(countPos)
		f:WriteULong(count)

		f:Seek(ids_pos)
		f:WriteULong(countPos)

		f:Close()

		file.Write("openpermissions_v2.dat", util.Compress(file.Read("openpermissions_v2.dat", "DATA")))

	end
end
function OpenPermissions:DeserializeRegistry(dataType, stream)
	if (dataType == OpenPermissions.REGISTRY.NETWORKED) then
		
		-- Lazy but still probably quicker
		local data_len = net.ReadUInt(32)
		if (data_len == 0) then return end

		local data = net.ReadData(data_len)

		file.Write("openpermissions_networked.dat", data)
		OpenPermissions:DeserializeRegistry(OpenPermissions.REGISTRY.FLAT_FILE, "openpermissions_networked.dat")
		file.Delete("openpermissions_networked.dat")

	elseif (dataType == OpenPermissions.REGISTRY.FLAT_FILE) then
		
		local data = file.Read(stream or "openpermissions_v2.dat", "DATA")
		file.Write("openpermissions_stream.dat", util.Decompress(data))
		local f = file.Open("openpermissions_stream.dat", "rb", "DATA")

		assert(f:Read(#("OPENPERMISSIONS")) == "OPENPERMISSIONS", "Error! OpenPermissions data corrupted!")

		OpenPermissions.IDs = { Int = {}, Str = {} }
		OpenPermissions.PermissionsRegistry = OpenPermissions:CreatePermissionsRegistry()

		local ids = {}

		local pointer = f:ReadULong()
		local pos = f:Tell()
		f:Seek(pointer)

		-- Read permission IDs
		for i = 1, f:ReadULong() do
			local permission_str = f:Read(f:ReadUShort())
			local permission_id = f:ReadUShort()
			ids[permission_id] = permission_str
		end
		
		f:Seek(pos)

		-- Read permission registry
		for i = 1, f:ReadULong() do
			local access_group = f:ReadUShort()
			OpenPermissions.PermissionsRegistry[access_group] = {}
			
			for j = 1, f:ReadULong() do
				local accessor = f:ReadBool() and f:Read(f:ReadUShort()) or f:ReadULong()
				OpenPermissions.PermissionsRegistry[access_group][accessor] = {}

				for k = 1, f:ReadULong() do
					OpenPermissions.PermissionsRegistry[access_group][accessor][ids[f:ReadUShort()]] = f:ReadBool() and OpenPermissions.CHECKBOX.INHERIT or (f:ReadBool() and OpenPermissions.CHECKBOX.TICKED or OpenPermissions.CHECKBOX.CROSSED)
				end
			end
		end

		f:Close()
		file.Delete("openpermissions_stream.dat")

		return OpenPermissions.PermissionsRegistry

	end
end

function OpenPermissions:SerializeTable(tbl)
	return OpenPermissions.pon.encode(tbl)
end

function OpenPermissions:DeserializeTable(tbl)
	return OpenPermissions.pon.decode(tbl)
end

local NetworkedTblCache = {}
function OpenPermissions:ClearNetworkCache(tbl)
	NetworkedTblCache[tostring(tbl)] = nil
end
function OpenPermissions:StartNetworkTable(tbl, cache, clear_cache)
	if (tbl == OpenPermissions.PermissionsRegistry) then
		return OpenPermissions:SerializeRegistry(OpenPermissions.REGISTRY.NETWORKED)
	end

	local tbl_enc
	if (cache and not clear_cache and NetworkedTblCache[tostring(tbl)] ~= nil) then
		tbl_enc = NetworkedTblCache[tostring(tbl)]
	else
		tbl_enc = util.Compress(OpenPermissions:SerializeTable(tbl))
		if (cache) then
			NetworkedTblCache[tostring(tbl)] = tbl_enc
		end
	end
	net.WriteUInt(#tbl_enc, 32)
	net.WriteData(tbl_enc, #tbl_enc)
end
function OpenPermissions:ReceiveNetworkTable()
	local tbl_enc_len = net.ReadUInt(32)
	local tbl_dec = OpenPermissions:DeserializeTable(util.Decompress(net.ReadData(tbl_enc_len)))
	return tbl_dec
end

--## SteamIDs ##--

function OpenPermissions:SteamID64ToAccountID(steamid64)
	return OpenPermissions:SteamIDToAccountID(util.SteamIDFrom64(steamid64))
end

function OpenPermissions:SteamIDToAccountID(steamid)
	local acc32 = tonumber(steamid:sub(11))
	return (acc32 * 2) + tonumber(steamid:sub(9,9))
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

function OpenPermissions:IsUserGroup(ply, ...)
	local vararg = {...}
	if (#vararg == 1) then
		return ply:IsUserGroup(vararg[1]) or (not ply:IsBot() and hook.Run("OpenPermissions:IsUserGroup", ply, vararg[1]) == true) or false
	else
		for _,ug in ipairs(vararg) do
			if (ply:IsUserGroup(ug) or (not ply:IsBot() and hook.Run("OpenPermissions:IsUserGroup", ply, ug) == true)) then
				return true
			end
		end
		return false
	end
end

function OpenPermissions:IsUsergroups(ply, usergroups)
	local ply_usergroups = OpenPermissions:GetUserGroups(ply)
	for _,usergroup in ipairs(usergroups) do
		if (ply_usergroups[usergroup]) then
			return true
		end
	end
	return false
end

function OpenPermissions:GetUserGroups(ply)
	local usergroups_tbl = {[ply:GetUserGroup()] = true}
	if (not ply:IsBot()) then
		hook.Run("OpenPermissions:GetUserGroups", ply, usergroups_tbl)
	end
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
	if (ply:IsBot()) then return false end
	if (OpenPermissions.IndexedOperators[ply:AccountID()]) then
		return true
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

--## HasPermission, GetPermission ##--

function OpenPermissions:GetPermission(ply, permission_id, is_operator)
	if (type(ply) ~= "Player" or ply:AccountID() == nil) then
		OpenPermissions:Print("Tried to do a permission check on a non-player or a player without an assigned account ID?", "[ERROR]", OpenPermissions.COLOR_RED)
		debug.Trace()
		return false
	end
	if (ply:IsBot()) then return false end
	if (is_operator == true or (is_operator ~= false and OpenPermissions:IsOperator(ply))) then return true end
	
	local has_permission = OpenPermissions.CHECKBOX.INHERIT

	if (type(permission_id) == "table") then
		for _,v in ipairs(permission_id) do
			local r = OpenPermissions:GetPermission(ply, v)
			if (r ~= OpenPermissions.CHECKBOX.INHERIT) then
				return r
			end
		end
		return OpenPermissions.CHECKBOX.INHERIT
	end

	for usergroup in pairs(OpenPermissions:GetUserGroups(ply)) do
		local ply_usergroup_registry = OpenPermissions.PermissionsRegistry[OpenPermissions.ACCESS_GROUP.USERGROUP][usergroup]
		if (ply_usergroup_registry) then
			if (ply_usergroup_registry[permission_id] == OpenPermissions.CHECKBOX.TICKED or ply_usergroup_registry[permission_id] == true) then
				has_permission = OpenPermissions.CHECKBOX.TICKED
			elseif (ply_usergroup_registry[permission_id] == OpenPermissions.CHECKBOX.CROSSED) then
				return OpenPermissions.CHECKBOX.CROSSED
			end
		end
	end

	local ply_steamid_registry = OpenPermissions.PermissionsRegistry[OpenPermissions.ACCESS_GROUP.STEAMID][ply:AccountID()]
	if (ply_steamid_registry) then
		if (ply_steamid_registry[permission_id] == OpenPermissions.CHECKBOX.TICKED or ply_steamid_registry[permission_id] == true) then
			has_permission = OpenPermissions.CHECKBOX.TICKED
		elseif (ply_steamid_registry[permission_id] == OpenPermissions.CHECKBOX.CROSSED) then
			return OpenPermissions.CHECKBOX.CROSSED
		end
	end

	if (ply:Team()) then
		local ply_team_registry = OpenPermissions.PermissionsRegistry[OpenPermissions.ACCESS_GROUP.TEAM][OpenPermissions:GetTeamIdentifier(ply:Team())]
		if (ply_team_registry) then
			if (ply_team_registry[permission_id] == OpenPermissions.CHECKBOX.TICKED or ply_team_registry[permission_id] == true) then
				has_permission = OpenPermissions.CHECKBOX.TICKED
			elseif (ply_team_registry[permission_id] == OpenPermissions.CHECKBOX.CROSSED) then
				return OpenPermissions.CHECKBOX.CROSSED
			end
		end

		if (OpenPermissions.IsDarkRP and RPExtraTeams[ply:Team()]) then
			local ply_category_name = RPExtraTeams[ply:Team()].category
			local ply_category
			for i,category in ipairs(DarkRP.getCategories().jobs) do
				if (category.name == ply_category_name) then
					ply_category = i
					break
				end
			end
			if (ply_category) then
				local ply_category_registry = OpenPermissions.PermissionsRegistry[OpenPermissions.ACCESS_GROUP.DARKRP_CATEGORY][OpenPermissions:DarkRP_GetCategoryIdentifier(ply_category)]
				if (ply_category_registry) then
					if (ply_category_registry[permission_id] == OpenPermissions.CHECKBOX.TICKED or ply_category_registry[permission_id] == true) then
						has_permission = OpenPermissions.CHECKBOX.TICKED
					elseif (ply_category_registry[permission_id] == OpenPermissions.CHECKBOX.CROSSED) then
						return OpenPermissions.CHECKBOX.CROSSED
					end
				end
			end
		end
	end

	for name, func in pairs(OpenPermissions.LuaFunctions) do
		local lua_function_registry = OpenPermissions.PermissionsRegistry[OpenPermissions.ACCESS_GROUP.LUA_FUNCTION][name]
		if (lua_function_registry) then
			if (func(ply, permission_id) == true) then
				if (lua_function_registry[permission_id] == OpenPermissions.CHECKBOX.TICKED or lua_function_registry[permission_id] == true) then
					has_permission = OpenPermissions.CHECKBOX.TICKED
				elseif (lua_function_registry[permission_id] == OpenPermissions.CHECKBOX.CROSSED) then
					return OpenPermissions.CHECKBOX.CROSSED
				end
			end
		end
	end

	if (has_permission == OpenPermissions.CHECKBOX.INHERIT and OpenPermissions.DefaultPermissions[permission_id] == OpenPermissions.CHECKBOX.TICKED) then
		has_permission = OpenPermissions.CHECKBOX.TICKED
	end

	return has_permission
end

function OpenPermissions:HasPermission(ply, permission_id, is_operator)
	if (type(ply) ~= "Player" or ply:AccountID() == nil) then
		OpenPermissions:Print("Tried to do a permission check on a non-player or a player without an assigned account ID?", "[ERROR]", OpenPermissions.COLOR_RED)
		debug.Trace()
		return false
	end
	if (ply:IsBot()) then return false end
	if (is_operator == true or (is_operator ~= false and OpenPermissions:IsOperator(ply))) then return true end

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
		local ply_usergroup_registry = OpenPermissions.PermissionsRegistry[OpenPermissions.ACCESS_GROUP.USERGROUP][usergroup]
		if (ply_usergroup_registry) then
			if (ply_usergroup_registry[permission_id] == OpenPermissions.CHECKBOX.TICKED or ply_usergroup_registry[permission_id] == true) then
				has_permission = true
			elseif (ply_usergroup_registry[permission_id] == OpenPermissions.CHECKBOX.CROSSED) then
				return false
			end
		end
	end

	local ply_steamid_registry = OpenPermissions.PermissionsRegistry[OpenPermissions.ACCESS_GROUP.STEAMID][ply:AccountID()]
	if (ply_steamid_registry) then
		if (ply_steamid_registry[permission_id] == OpenPermissions.CHECKBOX.TICKED or ply_steamid_registry[permission_id] == true) then
			has_permission = true
		elseif (ply_steamid_registry[permission_id] == OpenPermissions.CHECKBOX.CROSSED) then
			return false
		end
	end

	if (ply:Team()) then
		local ply_team_registry = OpenPermissions.PermissionsRegistry[OpenPermissions.ACCESS_GROUP.TEAM][OpenPermissions:GetTeamIdentifier(ply:Team())]
		if (ply_team_registry) then
			if (ply_team_registry[permission_id] == OpenPermissions.CHECKBOX.TICKED or ply_team_registry[permission_id] == true) then
				has_permission = true
			elseif (ply_team_registry[permission_id] == OpenPermissions.CHECKBOX.CROSSED) then
				return false
			end
		end

		if (OpenPermissions.IsDarkRP and RPExtraTeams[ply:Team()]) then
			local ply_category_name = RPExtraTeams[ply:Team()].category
			local ply_category
			for i,category in ipairs(DarkRP.getCategories().jobs) do
				if (category.name == ply_category_name) then
					ply_category = i
					break
				end
			end
			if (ply_category) then
				local ply_category_registry = OpenPermissions.PermissionsRegistry[OpenPermissions.ACCESS_GROUP.DARKRP_CATEGORY][OpenPermissions:DarkRP_GetCategoryIdentifier(ply_category)]
				if (ply_category_registry) then
					if (ply_category_registry[permission_id] == OpenPermissions.CHECKBOX.TICKED or ply_category_registry[permission_id] == true) then
						has_permission = true
					elseif (ply_category_registry[permission_id] == OpenPermissions.CHECKBOX.CROSSED) then
						return false
					end
				end
			end
		end
	end

	for name, func in pairs(OpenPermissions.LuaFunctions) do
		local lua_function_registry = OpenPermissions.PermissionsRegistry[OpenPermissions.ACCESS_GROUP.LUA_FUNCTION][name]
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

	if (has_permission == false and OpenPermissions.DefaultPermissions[permission_id] == OpenPermissions.CHECKBOX.TICKED) then
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
	if (OpenPermissions.IsDarkRP and RPExtraTeams and team_index ~= 0) then
		if (RPExtraTeams[team_index]) then
			local team_identifier = RPExtraTeams[team_index].OPENPERMISSIONS_IDENTIFIER or RPExtraTeams[team_index].GAS_IDENTIFIER or RPExtraTeams[team_index].command
			team_identifier_index[team_identifier] = team_index
			return team_identifier
		end
	else
		local team_identifier = team.GetName(team_index)
		team_identifier_index[team_identifier] = team_index
		return team_identifier
	end
end

function OpenPermissions:GetTeamFromIdentifier(team_identifier)
	if (team_identifier == "Joining/Connecting") then return TEAM_CONNECTING end
	if (team_identifier == "Unassigned") then return TEAM_UNASSIGNED end
	if (team_identifier == "Spectator") then return TEAM_SPECTATOR end
	if (team_identifier_index[team_identifier]) then return team_identifier_index[team_identifier] end

	local team_index = hook.Run("OpenPermissions:GetTeamFromIdentifier", team_identifier)
	if (team_index) then
		team_identifier_index[team_identifier] = team_index
		return team_index
	end
	if (OpenPermissions.IsDarkRP and RPExtraTeams) then
		for _,job in ipairs(RPExtraTeams) do
			if (job.OPENPERMISSIONS_IDENTIFIER == team_identifier or job.command == team_identifier) then
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

OpenPermissions.PermissionsRegistry = OpenPermissions:CreatePermissionsRegistry()
OpenPermissions.DefaultPermissions = {}

--## Networking ##--

if (SERVER) then
	-- Convert old file format to new
	if (file.Exists("openpermissions.dat", "DATA") and not file.Exists("openpermissions_v2.dat", "DATA")) then
		local read_file = file.Read("openpermissions.dat", "DATA")
		if (not read_file) then
			OpenPermissions:Print("Failed to read saved permissions data", "[ERROR]", OpenPermissions.COLOR_RED)
		else
			read_file = util.Decompress(read_file)
			if (not read_file) then
				OpenPermissions:Print("Failed to decompress saved permissions data", "[ERROR]", OpenPermissions.COLOR_RED)
			else
				local no_errors, deserialized = pcall(OpenPermissions.pon.decode, read_file)
				if (not no_errors) then
					OpenPermissions:Print("Failed to deserialize decompressed saved permissions data", "[ERROR]", OpenPermissions.COLOR_RED)
				else
					--OpenPermissions:Print("Saved permissions data successfully loaded", "[INFO]", OpenPermissions.COLOR_GREEN)

					-- Restructure
					for access_group_str, permissions in pairs(deserialized) do
						local access_group, accessor = access_group_str:match("(%d) (.+)")
						OpenPermissions.PermissionsRegistry[access_group] = OpenPermissions.PermissionsRegistry[access_group] or {}
						OpenPermissions.PermissionsRegistry[access_group][accessor] = {}
						for permission_id_str, permission in pairs(permissions) do
							OpenPermissions.PermissionsRegistry[access_group][accessor][permission_id_str] = permission
						end
					end

					-- Save new data
					OpenPermissions:SerializeRegistry(OpenPermissions.REGISTRY.FLAT_FILE)

					file.Rename("openpermissions.dat", "openpermissions_v1.dat")
				end
			end
		end
	end

	if (file.Exists("openpermissions_v2.dat", "DATA")) then
		local no_errors = xpcall(OpenPermissions.DeserializeRegistry, function(err)
			OpenPermissions:Print("Failed to deserialize decompressed saved permissions data", "[ERROR]", OpenPermissions.COLOR_RED)

			print(err)
			debug.Trace()
		end, OpenPermissions, OpenPermissions.REGISTRY.FLAT_FILE)

		if (no_errors) then
			OpenPermissions:Print("Saved permissions data successfully loaded", "[INFO]", OpenPermissions.COLOR_GREEN)
		end
	end
	net.Receive("OpenPermissions.SavePermissions", function(_, ply)
		if (not OpenPermissions:IsOperator(ply)) then return end
		OpenPermissions:DeserializeRegistry(OpenPermissions.REGISTRY.NETWORKED)
		OpenPermissions:SerializeRegistry(OpenPermissions.REGISTRY.FLAT_FILE)

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
		OpenPermissions:DeserializeRegistry(OpenPermissions.REGISTRY.NETWORKED)
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