util.AddNetworkString("OpenPermissions.OpenMenu")
util.AddNetworkString("OpenPermissions.NoPermissions")
util.AddNetworkString("OpenPermissions.SavePermissions")
util.AddNetworkString("OpenPermissions.PermissionsRegistry")
util.AddNetworkString("OpenPermissions.NotAnAddon")

function OpenPermissions:OpenMenu(ply, addon)
	if (OpenPermissions:IsOperator(ply)) then
		if (addon) then
			net.Start("OpenPermissions.OpenMenu")
				OpenPermissions:StartNetworkTable(OpenPermissions.NetworkedAddons, true)
				net.WriteBool(true)
				net.WriteString(addon)
			net.Send(ply)
		else
			net.Start("OpenPermissions.OpenMenu")
				OpenPermissions:StartNetworkTable(OpenPermissions.NetworkedAddons, true)
				net.WriteBool(false)
			net.Send(ply)
		end
	else
		net.Start("OpenPermissions.NoPermissions")
		net.Send(ply)
	end
end

net.Receive("OpenPermissions.OpenMenu", function(_, ply)
	local addon = net.ReadString()
	if (#addon > 0) then
		if (OpenPermissions.Addons[addon]) then
			OpenPermissions:OpenMenu(ply, addon)
		else
			net.Start("OpenPermissions.NotAnAddon")
			net.Send(ply)
		end
	else
		OpenPermissions:OpenMenu(ply)
	end
end)

hook.Add("PlayerSay", "openpermissions_chat_command", function(ply, txt)
	if (txt:lower() == "!openpermissions") then
		OpenPermissions:OpenMenu(ply)
		return ""
	elseif (txt:lower():sub(1,17) == "!openpermissions ") then
		local arg = txt:lower():sub(18)
		if (OpenPermissions.Addons[arg]) then
			OpenPermissions:OpenMenu(ply, arg)
		else
			net.Start("OpenPermissions.NotAnAddon")
			net.Send(ply)
		end
		return ""
	end
end)

local function BroadcastPermissionsRegistry()
	net.Start("OpenPermissions.PermissionsRegistry")
		OpenPermissions:StartNetworkTable(OpenPermissions.PermissionsRegistry, true, true)
		OpenPermissions:StartNetworkTable(OpenPermissions.DefaultPermissions, true, true)
	net.Broadcast()
end

local OP_TREE_ITEM = {}
function OP_TREE_ITEM:Init()
	self.Items = {}
	if (self.Options.Default ~= nil) then
		OpenPermissions.DefaultPermissions[self:GetID()] = self.Options.Default
	end
	if (OpenPermissions_Readying ~= true) then
		timer.Remove("OpenPermissions:BroadcastPermissionsRegistry")
		timer.Create("OpenPermissions:BroadcastPermissionsRegistry", 4, 1, BroadcastPermissionsRegistry)
	end
end
function OP_TREE_ITEM:GetTree()
	return self.Items
end
function OP_TREE_ITEM:GetIcon()
	return self.Options.Icon
end
function OP_TREE_ITEM:GetLabel()
	return self.Options.Label
end
function OP_TREE_ITEM:AddToTree(options)
	local new_tree_item = table.Copy(OP_TREE_ITEM)
	if (options.Value) then
		new_tree_item.ID = self.ID .. "/" .. options.Value
	else
		new_tree_item.ID = self.ID
	end
	new_tree_item.Options = options
	new_tree_item:Init()

	table.insert(self.Items, new_tree_item)
	new_tree_item.NetworkedTree = self.NetworkedTree[table.insert(self.NetworkedTree, {{}, options})][1]

	return new_tree_item
end
function OP_TREE_ITEM:GetID()
	return self.ID
end

local OP_ADDON = {}
function OP_ADDON:Init()
	self.Items = {}
end
function OP_ADDON:GetTree()
	return self.Items
end
function OP_ADDON:GetID()
	return self.ID
end
function OP_ADDON:GetName()
	return self.Options.Name or self.ID
end
function OP_ADDON:AddToTree(options)
	local new_tree_item = table.Copy(OP_TREE_ITEM)
	if (options.Value) then
		new_tree_item.ID = self.ID .. "/" .. options.Value
	else
		new_tree_item.ID = self.ID
	end
	new_tree_item.Options = options
	new_tree_item:Init()

	table.insert(self.Items, new_tree_item)
	new_tree_item.NetworkedTree = OpenPermissions.NetworkedAddons[self:GetID()][1][table.insert(OpenPermissions.NetworkedAddons[self:GetID()][1], {{}, options})][1]

	return new_tree_item
end

OpenPermissions.Addons = {}
OpenPermissions.NetworkedAddons = {}
function OpenPermissions:RegisterAddon(id, options)
	local new_addon = table.Copy(OP_ADDON)
	new_addon.ID = id
	new_addon.Options = options
	new_addon:Init()

	OpenPermissions.Addons[id] = new_addon
	OpenPermissions.NetworkedAddons[id] = {{}, options}

	return new_addon
end

OpenPermissions_Ready = true
hook.Run("OpenPermissions:Ready")
OpenPermissions_Readying = nil