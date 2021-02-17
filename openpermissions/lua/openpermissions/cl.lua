local L = OpenPermissions.L
local Lf = OpenPermissions.Lf

local function DMenuOption_ColorIcon(option, color)
	option:SetIcon("icon16/box.png")
	function option.m_Image:Paint(w,h)
		surface.SetDrawColor(color)
		surface.DrawRect(0,0,w,h)
	end
end
local function GreenToRed_DMenu(i, max, option)
	DMenuOption_ColorIcon(option, Color(i / max * 255, 1 - (i / max) * 255, 0))
end

surface.CreateFont("OpenPermissions_14px", {
	font = "Roboto",
	size = 14,
})
surface.CreateFont("OpenPermissions_Tip", {
	font = "Roboto",
	size = 22,
})

function OpenPermissions:AddTooltip(pnl, options)
	pnl.OpenPermissions_Tooltip_OnCursorEntered = pnl.OnCursorEntered
	pnl.OpenPermissions_Tooltip_OnCursorExited = pnl.OnCursorExited

	function pnl:OnCursorEntered(...)
		pnl.OpenPermissions_Tooltip = vgui.Create("OpenPermissions.Tooltip")
		pnl.OpenPermissions_Tooltip:SetText(options.Text)
		pnl.OpenPermissions_Tooltip.VGUI_Element = pnl

		if (self.OpenPermissions_Tooltip_OnCursorEntered) then
			return self.OpenPermissions_Tooltip_OnCursorEntered(self, ...)
		end
	end

	function pnl:OnCursorExited(...)
		if (IsValid(self.OpenPermissions_Tooltip)) then
			self.OpenPermissions_Tooltip:Remove()
		end
		self.OpenPermissions_Tooltip = nil
		if (self.OpenPermissions_Tooltip_OnCursorExited) then
			return self.OpenPermissions_Tooltip_OnCursorExited(self, ...)
		end
	end
end
function OpenPermissions:RemoveTooltip(pnl)
	if (IsValid(pnl.OpenPermissions_Tooltip)) then
		pnl.OpenPermissions_Tooltip:Remove()
	end
	pnl.OpenPermissions_Tooltip = nil
	pnl.OnCursorEntered = pnl.OpenPermissions_Tooltip_OnCursorEntered
	pnl.OnCursorExited = pnl.OpenPermissions_Tooltip_OnCursorExited
end

local blur = Material("pp/blurscreen")
function OpenPermissions:OpenMenu(specific_addon)
	if (IsValid(OpenPermissions_Menu)) then
		OpenPermissions_Menu:Close()
	end

	OpenPermissions_Menu = vgui.Create("DFrame")

	local AccessGroups
	local PermissionsSave

	local Menu = OpenPermissions_Menu
	Menu:SetSize(850,500)
	Menu:SetTitle("OpenPermissions")
	Menu:SetIcon("icon16/shield.png")
	Menu:Center()
	Menu:MakePopup()

	local Tabs = vgui.Create("DPropertySheet", Menu)
	Tabs:Dock(FILL)

	local PermissionsTab = vgui.Create("DPanel", Tabs)
	PermissionsTab.Paint = nil

		local AccessGroupsDivider = vgui.Create("OpenPermissions.HorizontalDivider", PermissionsTab)
		AccessGroupsDivider:Dock(FILL)
		AccessGroupsDivider:SetDividerWidth(5)
		AccessGroupsDivider:SetLeftWidth(200)
		AccessGroupsDivider:SetRightMin(465)
		AccessGroupsDivider:SetLeftMin(150)

		local AddonsContainer = vgui.Create("OpenPermissions.ColumnLayout", AccessGroupsDivider)
		AccessGroupsDivider:SetRight(AddonsContainer)
		AddonsContainer:SetColumns(OpenPermissions_COLUMN_LAYOUT_COLUMN_GROW, OpenPermissions_COLUMN_LAYOUT_COLUMN_GROW, OpenPermissions_COLUMN_LAYOUT_COLUMN_GROW)
		AddonsContainer:SetPaddings(5,5)

		local AddonContentContainer = vgui.Create("DPanel", PermissionsTab)
		AddonContentContainer.Paint = nil
		AddonContentContainer:SetVisible(false)
		AddonContentContainer:Dock(FILL)
		AddonContentContainer:DockMargin(5,0,0,0)

			local AddonContent = vgui.Create("DPropertySheet", AddonContentContainer)
			AddonContent:Dock(FILL)
			function AddonContent:PaintOver(w,h)
				if (not self.ShowOverlay) then return end
				local x,y = self:LocalToScreen(0,0)
				local scrW,scrH = ScrW(), ScrH()
				surface.SetDrawColor(255,255,255)
				surface.SetMaterial(blur)
				for i=1,2 do
					blur:SetFloat("$blur", (i / 2) * 2)
					blur:Recompute()
					render.UpdateScreenEffectTexture()
					surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
				end

				surface.SetDrawColor(0,0,0,240)
				surface.DrawRect(0,0,w,h)

				draw.SimpleTextOutlined(L"select_an_access_group", "OpenPermissions_Tip", w / 2, h / 2, OpenPermissions.COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, OpenPermissions.COLOR_BLACK)
			end

			local PermissionsContent = vgui.Create("OpenPermissions.HorizontalDivider", AddonContent)
			PermissionsContent:SetDividerWidth(5)
			PermissionsContent:SetRightMin(150)
			PermissionsContent:SetLeftMin(150)
			PermissionsContent.Paint = nil

				local PermissionsTree = vgui.Create("OpenPermissions.Tree", PermissionsContent)

				local PropertiesContent = vgui.Create("OpenPermissions.ScrollPanel", PermissionsContent)
				PropertiesContent:DockMargin(5,0,0,0)
				PropertiesContent:SetWide(150)
				PropertiesContent:SetDrawBackground(true)
				function PropertiesContent:AddProperty(options, indent_level, no_checkbox)
					local permission_row = vgui.Create("DPanel", PropertiesContent)
					permission_row.Paint = nil
					permission_row:Dock(TOP)
					permission_row:SetTall(16)
					permission_row:DockMargin(5 + ((indent_level or 0) * (16 + 5)),5,5,0)

					OpenPermissions:AddTooltip(permission_row, {Text = options.Tip or options.Label})

					local checkbox
					if (not no_checkbox) then
						permission_row:SetMouseInputEnabled(true)
						permission_row:SetCursor("hand")

						checkbox = vgui.Create("OpenPermissions.Checkbox", permission_row)
						checkbox:SetCrossable(true)
						checkbox:Dock(LEFT)
						checkbox:DockMargin(0,0,5,0)

						function permission_row:OnMouseReleased(m)
							if (m == MOUSE_LEFT) then
								checkbox:DoClick()
							elseif (m == MOUSE_RIGHT) then
								checkbox:DoRightClick()
							end
						end
					end

					if (options.Icon) then
						local icon = vgui.Create("DImage", permission_row)
						icon:Dock(LEFT)
						icon:SetSize(16,16)
						icon:DockMargin(0,0,5,0)
						icon:SetImage(options.Icon)
						icon:SetMouseInputEnabled(false)
					elseif (options.Color) then
						local col_icon = vgui.Create("DPanel", permission_row)
						col_icon:Dock(LEFT)
						col_icon:SetSize(16,16)
						col_icon:DockMargin(0,0,5,0)
						col_icon:SetMouseInputEnabled(false)
						function col_icon:Paint(w,h)
							surface.SetDrawColor(options.Color)
							surface.DrawRect(0,0,w,h)
						end
					end

					local label = vgui.Create("DLabel", permission_row)
					label:Dock(FILL)
					label:SetTextColor(OpenPermissions.COLOR_BLACK)
					label:SetText(options.Label)
					label:SetContentAlignment(4)
					label:SetMouseInputEnabled(false)

					return checkbox
				end

				PermissionsContent:SetLeft(PermissionsTree)
				PermissionsContent:SetRight(PropertiesContent)
				PermissionsContent:BalanceWidths()

			AddonContent:AddSheet(L"permissions", PermissionsContent, "icon16/group.png")

			local OperationsContainer = vgui.Create("OpenPermissions.ScrollPanel", AddonContent)
			AddonContent:AddSheet(L"operations", OperationsContainer, "icon16/wrench_orange.png")

			function AddonContent:SetShowOverlay(show)
				self.ShowOverlay = show
				self:SetMouseInputEnabled(not show)
				for _,v in ipairs(self:GetItems()) do
					v.Panel:SetMouseInputEnabled(not show)
				end
			end
			AddonContent:SetShowOverlay(true)

				local DeleteAccessGroup = vgui.Create("DButton", OperationsContainer)
				DeleteAccessGroup:SetSize(250,30)
				DeleteAccessGroup:SetText(L"delete_access_group")
				DeleteAccessGroup:SetIcon("icon16/delete.png")

				local CopyPasteContainer = vgui.Create("DPanel", OperationsContainer)
				CopyPasteContainer.Paint = nil
				CopyPasteContainer:SetSize(250,30)
				CopyPasteContainer:AlignTop(DeleteAccessGroup:GetTall() + 5)

					local CopyPermissions = vgui.Create("DButton", CopyPasteContainer)
					CopyPermissions:SetText(L"copy")
					CopyPermissions:SetIcon("icon16/page_copy.png")
					CopyPermissions:DockMargin(0,0,5,0)

					local PastePermissions = vgui.Create("DButton", CopyPasteContainer)
					PastePermissions:SetText(L"paste")
					PastePermissions:SetIcon("icon16/page_paste.png")
					PastePermissions:DockMargin(0,0,5,0)
					PastePermissions:SetDisabled(true)

					function CopyPermissions:DoClick()
						PastePermissions:SetDisabled(false)
						PastePermissions.PermissionsData = {}
						local copied_clashes = false
						for _,line in ipairs(AccessGroups:GetSelected()) do
							local identifier = line.Data.Enum .. " " .. line.Data.Value
							if (not OpenPermissions.PermissionsRegistryEditing[line.Data.Enum] or not OpenPermissions.PermissionsRegistryEditing[line.Data.Value]) then continue end
							for access_group, perms in pairs(OpenPermissions.PermissionsRegistryEditing[line.Data.Enum]) do
								for permission_id, checked in pairs(perms) do
									if (PastePermissions.PermissionsData[permission_id] == nil) then
										local has_clashed = false
										for _,line_2 in ipairs(AccessGroups:GetSelected()) do
											local identifier_2 = line_2.Data.Enum .. " " .. line_2.Data.Value
											if (not OpenPermissions.PermissionsRegistryEditing[line_2.Data.Enum] or not OpenPermissions.PermissionsRegistryEditing[line_2.Data.Value]) then continue end
											if (identifier_2 == identifier) then continue end
											if (OpenPermissions.PermissionsRegistryEditing[line_2.Data.Enum][line_2.Data.Value][permission_id] ~= checked) then
												copied_clashes, has_clashed = true, true
												break
											end
										end
										if (not has_clashed) then
											PastePermissions.PermissionsData[permission_id] = checked
										else
											PastePermissions.PermissionsData[permission_id] = nil
										end
									elseif (PastePermissions.PermissionsData[permission_id] ~= checked) then
										copied_clashes = true
										PastePermissions.PermissionsData[permission_id] = nil
									end
								end
							end
						end
						if (copied_clashes) then
							Derma_Message(L"permission_clash_msg", "OpenPermissions", L"ok")
						end
					end
					function PastePermissions:DoClick()
						for _,line in ipairs(AccessGroups:GetSelected()) do
							OpenPermissions.PermissionsRegistryEditing[line.Data.Enum] = OpenPermissions.PermissionsRegistryEditing[line.Data.Enum] or {}
							OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value] = OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value] or {}
							table.Merge(OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value], PastePermissions.PermissionsData)
						end
					end

					function CopyPasteContainer:PerformLayout(w,h)
						CopyPermissions:SetSize((w - 2.5) / 2,h)
						CopyPermissions:AlignLeft(0)
						PastePermissions:SetSize((w - 2.5) / 2,h)
						PastePermissions:AlignRight(0)
					end

			local AddonNav = vgui.Create("DPanel", AddonContentContainer)
			AddonNav.Paint = nil
			AddonNav:Dock(BOTTOM)
			AddonNav:DockMargin(0,5,0,0)
			AddonNav:SetTall(30)

				PermissionsSave = vgui.Create("DButton", AddonNav)
				PermissionsSave:Dock(LEFT)
				PermissionsSave:SetWide(100)
				PermissionsSave:DockMargin(0,0,5,0)
				PermissionsSave:SetText(L"save")
				PermissionsSave:SetIcon("icon16/disk.png")
				PermissionsSave:SetDisabled(true)

				function PermissionsSave:RememberPermission(permission_id, checked)
					local is_disabled = true
					for _,line in ipairs(AccessGroups:GetSelected()) do
						if (checked == OpenPermissions.CHECKBOX.INHERIT or checked == false) then
							if (OpenPermissions.PermissionsRegistryEditing[line.Data.Enum] ~= nil and OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value] ~= nil) then
								OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value][permission_id] = nil
								if (OpenPermissions:table_IsEmpty(OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value])) then
									OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value] = nil
									if (OpenPermissions:table_IsEmpty(OpenPermissions.PermissionsRegistryEditing[line.Data.Enum])) then
										OpenPermissions.PermissionsRegistryEditing[line.Data.Enum] = nil
									end
								end
							end
						else
							OpenPermissions.PermissionsRegistryEditing[line.Data.Enum] = OpenPermissions.PermissionsRegistryEditing[line.Data.Enum] or {}
							OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value] = OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value] or {}
							OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value][permission_id] = checked
						end
						if (is_disabled) then
							if ((OpenPermissions.PermissionsRegistryEditing[line.Data.Enum] ~= nil and OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value] ~= nil) ~= (OpenPermissions.PermissionsRegistry[line.Data.Enum] ~= nil and OpenPermissions.PermissionsRegistry[line.Data.Enum][line.Data.Value] ~= nil)) then
								is_disabled = false
							else
								if (OpenPermissions.PermissionsRegistryEditing[line.Data.Enum] ~= nil and OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value] ~= nil and OpenPermissions.PermissionsRegistry[line.Data.Enum] ~= nil and OpenPermissions.PermissionsRegistry[line.Data.Enum][line.Data.Value] ~= nil and OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value][permission_id] ~= OpenPermissions.PermissionsRegistry[line.Data.Enum][line.Data.Value][permission_id]) then
									is_disabled = false
								elseif (not OpenPermissions:table_IsIdentical(OpenPermissions.PermissionsRegistryEditing, OpenPermissions.PermissionsRegistry)) then
									is_disabled = false
								end
							end
						end
					end
					self:SetDisabled(is_disabled)
				end
				function PermissionsSave:CheckedFromMemory(permission_id, checkbox)
					local checked
					for _,line in ipairs(AccessGroups:GetSelected()) do
						local should_be_checked = OpenPermissions.CHECKBOX.INHERIT
						if (OpenPermissions.PermissionsRegistryEditing[line.Data.Enum] ~= nil and OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value] ~= nil and OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value][permission_id] ~= nil) then
							should_be_checked = OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value][permission_id]
						elseif (OpenPermissions.DefaultPermissions[permission_id] ~= nil) then
							should_be_checked = OpenPermissions.DefaultPermissions[permission_id]
						end
						if (checked == nil) then
							checked = should_be_checked
						else
							if (should_be_checked ~= checked) then
								checkbox:SetAmbigious(true)
								return
							end
						end
					end
					checkbox:SetChecked(checked)
					checkbox:SetAmbigious(false)
				end
				function PermissionsSave:DoClick()
					OpenPermissions.PermissionsRegistry = table.Copy(OpenPermissions.PermissionsRegistryEditing)
					self:SetDisabled(true)
					surface.PlaySound("garrysmod/content_downloaded.wav")
					
					OpenPermissions:SerializeRegistry(OpenPermissions.REGISTRY.FLAT_FILE)
					net.Start("OpenPermissions.SavePermissions")
						OpenPermissions:StartNetworkTable(OpenPermissions.PermissionsRegistry)
					net.SendToServer()
					file.Delete("openpermissions_v2.dat")
				end

				local AddonBack = vgui.Create("DButton", AddonNav)
				AddonBack:Dock(LEFT)
				AddonBack:SetWide(100)
				AddonBack:DockMargin(0,0,5,0)
				AddonBack:SetText(L"back_btn")
				function AddonBack:DoClick()
					AddonsContainer:SetVisible(true)
					AddonContentContainer:SetVisible(false)

					AccessGroupsDivider:SetRight(AddonsContainer)
				end

				local AddonSelect = vgui.Create("OpenPermissions.ComboBox", AddonNav)
				AddonSelect:Dock(FILL)
				AddonSelect.AddonBtns = {}

				AddonSelect:SetSortItems(false)
				AddonSelect:AddChoice(L"all_addons", true, false, "icon16/layers.png")
				AddonSelect:AddSpacer()

				function AddonSelect:OnSelect(i, v, d)
					PropertiesContent:Clear()
					if (d == true) then
						function AccessGroups:OnRowSelected(i, row)
							AddonContent:SetShowOverlay(false)
							PermissionsTree:Clear()
							PropertiesContent:Clear()
							for id, data in pairs(OpenPermissions.Addons) do
								PermissionsTab:LoadPermissions(id, data, true)
							end
						end
						if (AccessGroups:GetSelectedLine() ~= nil) then
							AccessGroups:OnRowSelected()
						end
					else
						self.AddonBtns[d]:DoClick()
					end
				end

		local NavContent = vgui.Create("DPanel", PermissionsTab)
		AccessGroupsDivider:SetLeft(NavContent)
		NavContent.Paint = nil
		NavContent:Dock(LEFT)
		NavContent:SetWide(200)

			AccessGroups = vgui.Create("OpenPermissions.ListView", NavContent)
			AccessGroups:AddColumn(L"type"):SetFixedWidth(65)
			AccessGroups:AddColumn(L"access_group")
			AccessGroups:Dock(FILL)
			AccessGroups.Data = {}

			local KeyCategory = vgui.Create("DCollapsibleCategory", NavContent)
			KeyCategory:Dock(TOP)
			KeyCategory:SetTall(130)
			KeyCategory:DockMargin(0,0,0,5)
			KeyCategory:SetLabel(L"key")
			KeyCategory:SetExpanded(false)

				local KeyInfo = vgui.Create("OpenPermissions.ScrollPanel", NavContent)
				KeyInfo:SetDrawBackground(true)

				for name, enum in pairs(OpenPermissions.ACCESS_GROUP) do
					local Key = vgui.Create("DPanel", KeyInfo)
					Key:Dock(TOP)
					Key:DockMargin(5,5,5,0)

					local KeyColor = OpenPermissions.ACCESS_GROUP_KEY[enum]
					local KeyName = L("ACCESS_GROUP_" .. name)
					local KeyPoly = {
						{x = 9, y = 0},
						{x = 18, y = 9},
						{x = 9, y = 18},
						{x = 0, y = 9},
					}
					function Key:Paint(w,h)
						surface.SetDrawColor(KeyColor)
						draw.NoTexture()
						surface.DrawPoly(KeyPoly)

						draw.SimpleText(KeyName, "DermaDefault", 18 + 5, 8, OpenPermissions.COLOR_BLACK, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					end
				end

				KeyCategory:SetContents(KeyInfo)
			
			local MultipleTip = vgui.Create("DLabel", NavContent)
			MultipleTip:Dock(TOP)
			MultipleTip:SetContentAlignment(5)
			MultipleTip:DockMargin(0,0,0,5)
			MultipleTip:SetText(L"hold_ctrl_to_select_multiple")
			MultipleTip:SetTextColor(OpenPermissions.COLOR_BLACK)

			local AddAccessGroup = vgui.Create("DButton", NavContent)
			AddAccessGroup:SetText(L"add_access_group")
			AddAccessGroup:SetIcon("icon16/add.png")
			AddAccessGroup:Dock(BOTTOM)
			AddAccessGroup:DockMargin(0,5,0,0)
			AddAccessGroup:SetTall(30)

			function AddAccessGroup:Add(enum, text, value)
				local val = value or text
				if (AccessGroups.Data[enum] and AccessGroups.Data[enum][val]) then
					Derma_Message(L"access_group_exists", L"error", L"ok")
				else
					local type
					for name, _enum in pairs(OpenPermissions.ACCESS_GROUP) do
						if (_enum == enum) then
							type = name
							break
						end
					end
					local line = AccessGroups:AddLine(L("ACCESS_GROUP_" .. type), text)
					line.Data = {
						Enum = enum,
						Value = val
					}
					function line:Paint(w,h)
						derma.SkinHook("Paint", "ListViewLine", self, w, h)

						surface.SetDrawColor(OpenPermissions.ACCESS_GROUP_KEY[enum])
						surface.DrawRect(0,0,w,h)
					end
					AccessGroups.Data[enum] = AccessGroups.Data[enum] or {}
					AccessGroups.Data[enum][val] = true
				end
			end
			for enum, accessors in pairs(OpenPermissions.PermissionsRegistry) do
				for val, vals in pairs(accessors) do
					enum = tonumber(enum)
					if (enum == OpenPermissions.ACCESS_GROUP.STEAMID) then
						AddAccessGroup:Add(enum, OpenPermissions:AccountIDToSteamID(tonumber(val)), tonumber(val))
					elseif (enum == OpenPermissions.ACCESS_GROUP.TEAM) then
						local team_index = OpenPermissions:GetTeamFromIdentifier(val)
						if (team_index) then
							AddAccessGroup:Add(enum, team.GetName(team_index), val)
						end
					elseif (enum == OpenPermissions.ACCESS_GROUP.DARKRP_CATEGORY) then
						if (OpenPermissions.IsDarkRP) then
							local category_index = OpenPermissions:DarkRP_GetCategoryFromIdentifier(val)
							if (category_index) then
								AddAccessGroup:Add(enum, DarkRP.getCategories().jobs[category_index].name, val)
							end
						end
					else
						AddAccessGroup:Add(enum, val)
					end
				end
			end

			function AddAccessGroup:DoClick()
				local menu = DermaMenu()
				
				local ACCESS_GROUP_USERGROUP, _ = menu:AddSubMenu(L"ACCESS_GROUP_USERGROUP") _:SetIcon("icon16/group.png")

					ACCESS_GROUP_USERGROUP:AddOption(L"custom_ellipsis", function()
						Derma_StringRequest(L"add_access_group", L"enter_usergroup", LocalPlayer():GetUserGroup(), function(usergroup)
							AddAccessGroup:Add(OpenPermissions.ACCESS_GROUP.USERGROUP, usergroup)
						end)
					end):SetIcon("icon16/pencil.png")

					local usergroups = {superadmin = true, admin = true, user = true}
					for _,ply in ipairs(player.GetHumans()) do
						for usergroup in pairs(OpenPermissions:GetUserGroups(ply)) do
							usergroups[usergroup] = true
						end
					end
					usergroups = table.GetKeys(usergroups)
					table.sort(usergroups)
					for i,usergroup in ipairs(usergroups) do
						GreenToRed_DMenu(i, #usergroups, ACCESS_GROUP_USERGROUP:AddOption(usergroup, function()
							AddAccessGroup:Add(OpenPermissions.ACCESS_GROUP.USERGROUP, usergroup)
						end))
					end

				local ACCESS_GROUP_STEAMID, _ = menu:AddSubMenu(L"ACCESS_GROUP_STEAMID") _:SetIcon("icon16/user_gray.png")

					ACCESS_GROUP_STEAMID:AddOption(L"custom_ellipsis", function()
						Derma_StringRequest(L"add_access_group", Lf("enter_steamid", LocalPlayer():SteamID(), LocalPlayer():SteamID64()), LocalPlayer():SteamID(), function(_input)
							local steamid64
							if (_input:find("^STEAM_%d:%d:%d+$")) then
								steamid64 = util.SteamIDTo64(_input)
							elseif (_input:find("^7656119%d+$")) then
								steamid64 = _input
							else
								Derma_Message(L"invalid_steamid", L"error", L"ok")
								return
							end
							local steamid = util.SteamIDFrom64(steamid64)
							AddAccessGroup:Add(OpenPermissions.ACCESS_GROUP.STEAMID, steamid, OpenPermissions:SteamIDToAccountID(steamid))
						end)
					end):SetIcon("icon16/pencil.png")

					local steamids = {}
					for _,ply in ipairs(player.GetHumans()) do
						table.insert(steamids, {Distance = ply:GetPos():DistToSqr(LocalPlayer():GetPos()), Name = ply:Nick(), SteamID = ply:SteamID(), AccountID = ply:AccountID(), Color = team.GetColor(ply:Team())})
					end
					table.SortByMember(steamids, "Distance", true)
					for i,item in ipairs(steamids) do
						DMenuOption_ColorIcon(ACCESS_GROUP_STEAMID:AddOption(item.Name, function()
							AddAccessGroup:Add(OpenPermissions.ACCESS_GROUP.STEAMID, item.SteamID, item.AccountID)
						end), item.Color)
					end

				local ACCESS_GROUP_TEAM, _ = menu:AddSubMenu(L"ACCESS_GROUP_TEAM") _:SetIcon("icon16/flag_green.png")

					if (OpenPermissions.IsDarkRP) then
						local categories = {}
						for i,c in ipairs(DarkRP.getCategories().jobs) do
							if (GAS:table_IsEmpty(c.members)) then continue end
							table.insert(categories, {name = c.name, color = c.color, members = c.members})
						end
						table.SortByMember(categories, "name", true)
						for i,c in ipairs(categories) do
							local submenu, _submenu = ACCESS_GROUP_TEAM:AddSubMenu(c.name)
							DMenuOption_ColorIcon(_submenu, c.color)

							local members = {}
							for _,member in ipairs(c.members) do
								table.insert(members, {name = member.name, color = member.color, index = member.team})
							end
							table.SortByMember(members, "name", true)
							for _,member in ipairs(members) do
								DMenuOption_ColorIcon(submenu:AddOption(member.name, function()
									AddAccessGroup:Add(OpenPermissions.ACCESS_GROUP.TEAM, member.name, OpenPermissions:GetTeamIdentifier(member.index))
								end), member.color)
							end
						end
					else
						local teams = {}
						for i,t in ipairs(team.GetAllTeams()) do
							table.insert(teams, {Name = t.Name, Index = i, Color = t.Color})
						end
						table.SortByMember(teams, "Name", true)
						for i,item in ipairs(teams) do
							DMenuOption_ColorIcon(ACCESS_GROUP_TEAM:AddOption(item.Name, function()
								AddAccessGroup:Add(OpenPermissions.ACCESS_GROUP.TEAM, item.Name, OpenPermissions:GetTeamIdentifier(i))
							end), item.Color)
						end
					end

				local ACCESS_GROUP_LUA_FUNCTION, _ = menu:AddSubMenu(L"ACCESS_GROUP_LUA_FUNCTION") _:SetIcon("icon16/script.png")
					local lua_functions = table.GetKeys(OpenPermissions.LuaFunctions)
					if (#lua_functions == 0) then
						ACCESS_GROUP_LUA_FUNCTION:AddOption(L"none_info")
					else
						table.sort(lua_functions)
						for i,lua_func_name in ipairs(lua_functions) do
							GreenToRed_DMenu(i, #lua_functions, ACCESS_GROUP_LUA_FUNCTION:AddOption(lua_func_name, function()
								AddAccessGroup:Add(OpenPermissions.ACCESS_GROUP.LUA_FUNCTION, lua_func_name)
							end))
						end
					end

				if (OpenPermissions.IsDarkRP) then
					local ACCESS_GROUP_DARKRP_CATEGORY, _ = menu:AddSubMenu(L"ACCESS_GROUP_DARKRP_CATEGORY") _:SetIcon("icon16/wrench_orange.png")
					local darkrp_categories = {}
					for i,category in ipairs(DarkRP.getCategories().jobs) do
						table.insert(darkrp_categories, {Name = category.name, Color = category.color, Category = category})
					end
					table.SortByMember(darkrp_categories, "Name", true)
					for i,item in ipairs(darkrp_categories) do
						DMenuOption_ColorIcon(ACCESS_GROUP_DARKRP_CATEGORY:AddOption(item.Name, function()
							AddAccessGroup:Add(OpenPermissions.ACCESS_GROUP.DARKRP_CATEGORY, item.Name, OpenPermissions:DarkRP_GetCategoryIdentifier(i))
						end), item.Color)
					end
				end

				hook.Run("OpenPermissions:AddAccessGroup", menu)

				menu:Open()
			end

		local function permissions_node_clicked(self, addon_id, v)
			PropertiesContent:Clear()

			local indent_level = 0
			local function _r(tbl, permission_id, my_parent, i)
				i = (i or 0) + 1
				local final_checkbox
				for i,v in ipairs(tbl) do
					local my_permission_id = permission_id
					if (v[2].Value) then
						my_permission_id = my_permission_id .. "/" .. v[2].Value
					end
					local new_checkbox = PropertiesContent:AddProperty(v[2], indent_level)
					final_checkbox = new_checkbox
					v[3] = new_checkbox
					v[4] = my_parent

					function new_checkbox:CheckAmbigious()
						if (my_parent) then
							local all_state
							local ambigious = false
							for _,_v in ipairs(my_parent[1]) do
								if (not IsValid(_v[3])) then continue end
								if (_v[3]:IsAmbigious()) then
									ambigious = true
									break
								elseif (all_state == nil) then
									all_state = _v[3]:GetChecked()
								elseif (all_state ~= _v[3]:GetChecked()) then
									ambigious = true
									break
								end
							end
							my_parent[3]:SetAmbigious(ambigious)
							if (not ambigious) then
								my_parent[3]:SetChecked(all_state)
							end
							my_parent[3]:CheckAmbigious()
						end
					end
					function new_checkbox:OnChange()
						self:CheckAmbigious()
						if (#v[1] > 0) then
							local function __r(tbl)
								for _,_v in ipairs(tbl) do
									_v[3]:SetChecked(self:GetChecked())
									_v[3]:OnChange()
									__r(_v[1])
								end
							end
							__r(v[1])
						else
							PermissionsSave:RememberPermission(my_permission_id, self:GetChecked())
						end
					end

					PermissionsSave:CheckedFromMemory(my_permission_id, new_checkbox)

					if (#v[1] > 0) then
						indent_level = indent_level + 1
						_r(v[1], my_permission_id, v, i)
					end
				end
				if (final_checkbox) then
					final_checkbox:CheckAmbigious()
				end
				indent_level = indent_level - 1
			end
			_r(v[1], addon_id)
		end
		function PermissionsTab:LoadPermissions(addon_id, addon_data, shouldnt_clear)
			PermissionsTab.AddonID, PermissionsTab.AddonData = addon_id, addon_data

			if (not shouldnt_clear) then
				PermissionsTree:Clear()
				PropertiesContent:Clear()
			end

			local tree = addon_data[1]
			local addon_options = addon_data[2]

			local root_node = PermissionsTree:AddNode(addon_options.Name or addon_id, addon_options.Icon)
			if (not shouldnt_clear) then root_node:SetExpanded(true) end
			function root_node:DoClick()
				-- show all permissions
				permissions_node_clicked(self, addon_id, addon_data)
			end

			local is_root = true
			local function r(tbl, node, permission_id, prev_options)
				local lowest_level = true
				for _,v in ipairs(tbl) do
					if (#v[1] > 0) then
						lowest_level = false
						break
					end
				end
				if (not is_root and lowest_level) then
					-- if we can't go any deeper then show property checkboxes
					-- when the node is clicked
					function node:DoClick()
						PropertiesContent:Clear()

						if (#tbl > 1) then
							local checkboxes = {}
							local master_checkbox = PropertiesContent:AddProperty(prev_options)
							function master_checkbox:OnChange()
								self:SetAmbigious(false)
								for _,v in ipairs(checkboxes) do
									v:SetChecked(self:GetChecked())
									v:OnChange()
								end
							end

							for i,v in ipairs(tbl) do
								local my_permission_id = permission_id
								if (v[2].Value) then
									my_permission_id = my_permission_id .. "/" .. v[2].Value
								end
								local checkbox = PropertiesContent:AddProperty(v[2], 1)
								table.insert(checkboxes, checkbox)
								function checkbox:CheckAmbigious()
									local all_state
									local ambigious = false
									for _,v in ipairs(checkboxes) do
										if (v:IsAmbigious()) then
											ambigious = true
											break
										elseif (all_state == nil) then
											all_state = v:GetChecked()
										elseif (all_state ~= v:GetChecked()) then
											ambigious = true
											break
										end
									end
									master_checkbox:SetAmbigious(ambigious)
									if (not ambigious) then master_checkbox:SetChecked(all_state) end
								end
								function checkbox:OnChange()
									PermissionsSave:RememberPermission(my_permission_id, self:GetChecked())
									self:CheckAmbigious()
								end
								PermissionsSave:CheckedFromMemory(my_permission_id, checkbox)
							end
							checkboxes[1]:CheckAmbigious()
						else
							local my_permission_id = permission_id
							if (tbl[1][2].Value) then
								my_permission_id = my_permission_id .. "/" .. tbl[1][2].Value
							end
							local checkbox = PropertiesContent:AddProperty(tbl[1][2])
							function checkbox:OnChange()
								PermissionsSave:RememberPermission(my_permission_id, self:GetChecked())
							end
							PermissionsSave:CheckedFromMemory(my_permission_id, checkbox)
						end
					end
				else
					is_root = false
				end

				for _,v in ipairs(tbl) do
					local my_permission_id = permission_id
					if (v[2].Value) then
						my_permission_id = my_permission_id .. "/" .. v[2].Value
					end
					local new_node = node:AddNode(v[2].Label)
					if (v[2].Icon) then
						new_node:SetIcon(v[2].Icon)
					elseif (v[2].Color) then
						function new_node.Icon:PaintOver(w,h)
							surface.SetDrawColor(v[2].Color)
							surface.DrawRect(0,0,w,h)
						end
					end
					if (#v[1] == 0) then
						function new_node:DoClick()
							PropertiesContent:Clear()
							local checkbox = PropertiesContent:AddProperty(v[2])
							function checkbox:OnChange()
								PermissionsSave:RememberPermission(my_permission_id, self:GetChecked())
							end
							PermissionsSave:CheckedFromMemory(my_permission_id, checkbox)
						end
					else
						function new_node:DoClick()
							permissions_node_clicked(self, my_permission_id, v)
						end
						r(v[1], new_node, my_permission_id, v[2])
					end
				end
			end
			r(tree, root_node, addon_id)
		end

	local TesterTab = vgui.Create("DPanel", Tabs)
	TesterTab.Paint = nil

	local HelpTabContent = vgui.Create("DPanel", Tabs)
	HelpTabContent.Paint = nil

	Tabs:AddSheet(L"permissions", PermissionsTab, "icon16/group.png")
	Tabs:AddSheet(L"tester", TesterTab, "icon16/wrench_orange.png")
	local HelpTab = Tabs:AddSheet(L"help", HelpTabContent, "icon16/help.png")

	local HelpContent
	function Tabs:OnActiveTabChanged(old, new)
		if (new == HelpTab.Tab) then
			if (IsValid(HelpContent)) then
				HelpContent:SetVisible(true)
			else
				HelpContent = vgui.Create("DPanel", HelpTabContent)
				HelpContent.Paint = nil
				HelpContent:Dock(FILL)

				local HelpControls = vgui.Create("DHTMLControls", HelpContent)
				HelpControls:Dock(TOP)
				HelpControls.HomeURL = "https://gmodadminsuite.github.io/OpenPermissions"

				local HelpHTML = vgui.Create("DHTML", HelpContent)
				HelpHTML:Dock(FILL)
				HelpHTML:OpenURL(HelpControls.HomeURL)

				HelpControls:SetHTML(HelpHTML)
			end
		elseif (IsValid(HelpContent)) then
			HelpContent:SetVisible(false)
		end
	end

	--## Create Dynamic Content ##--

	function DeleteAccessGroup:DoClick()
		for i,line in pairs(AccessGroups:GetLines()) do
			if (not line:IsLineSelected()) then continue end
			if (AccessGroups.Data[line.Data.Enum][line.Data.Value] ~= nil) then
				AccessGroups.Data[line.Data.Enum][line.Data.Value] = nil
			end
			if (OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value] ~= nil) then
				OpenPermissions.PermissionsRegistryEditing[line.Data.Enum][line.Data.Value] = nil
			end
			AccessGroups:RemoveLine(i)
		end
		AddonContent:SetShowOverlay(true)
		AddonContent:SwitchToName(L"permissions")
		PermissionsTree:Clear()
		PropertiesContent:Clear()

		PermissionsSave:SetDisabled(false)
	end

	local sorted_addons = {}
	for id, data in pairs(OpenPermissions.Addons) do
		local options = data[2]
		table.insert(sorted_addons, {name = options.Name or id, id = id, data = data})
	end
	table.SortByMember(sorted_addons, "name", true)

	local AddonQueue = {}
	local ActiveAddon
	for _,addon_data in ipairs(sorted_addons) do
		local id, data = addon_data.id, addon_data.data
		local options = data[2]
		AddonSelect:AddChoice(options.Name or id, id, false, options.Icon)

		local Addon = vgui.Create("OpenPermissions.Addon", AddonsContainer)

		if (specific_addon == id) then
			ActiveAddon = Addon
		end

		AddonSelect.AddonBtns[id] = Addon

		Addon:SetSize(200,120)
		Addon:Setup(id, options)
		if (Addon.Addon.Logo) then
			OpenPermissions:AddTooltip(Addon, {
				Text = options.Name
			})
		end

		function Addon:DoClick()
			PropertiesContent:Clear()

			AddonSelect:SetValue(options.Name or id)

			AddonsContainer:SetVisible(false)
			AddonContentContainer:SetVisible(true)

			AccessGroupsDivider:SetRight(AddonContentContainer)

			CopyPermissions:SetDisabled(#AccessGroups:GetSelected() > 1)
			PastePermissions:SetDisabled(true)

			function AccessGroups:OnRowSelected(i, row)
				AddonContent:SetShowOverlay(false)
				PropertiesContent:Clear()
				PermissionsTab:LoadPermissions(id, data)
			end
			if (AccessGroups:GetSelectedLine() ~= nil) then
				AccessGroups:OnRowSelected()
			end
		end

		table.insert(AddonQueue, Addon)
		if (#AddonQueue == 3) then
			AddonsContainer:AddRow(AddonQueue[1], AddonQueue[2], AddonQueue[3])
			AddonQueue = {}
		end
	end
	if (#AddonQueue > 0) then
		AddonsContainer:AddRow(AddonQueue[1], AddonQueue[2], AddonQueue[3])
	end
	if (ActiveAddon) then
		ActiveAddon:DoClick()
	end
end

net.Receive("OpenPermissions.OpenMenu", function()
	OpenPermissions.Addons = OpenPermissions:ReceiveNetworkTable()
	OpenPermissions.PermissionsRegistryEditing = table.Copy(OpenPermissions.PermissionsRegistry)

	local specific_addon = net.ReadBool()
	if (specific_addon) then
		OpenPermissions:OpenMenu(net.ReadString())
	else
		OpenPermissions:OpenMenu()
	end
end)

concommand.Add("openpermissions", function(_, __, args)
	net.Start("OpenPermissions.OpenMenu")
		net.WriteString(table.concat(args, " "))
	net.SendToServer()
end, function(cmd, args)
	local stuff = {}
	if (OpenPermissions.Addons ~= nil) then
		if (#string.Trim(args) > 0) then
			for name in pairs(OpenPermissions.Addons) do
				if (name:lower():find(string.Trim(args):lower())) then
					stuff[#stuff + 1] = "openpermissions " .. name
				end
			end
		else
			for name in pairs(OpenPermissions.Addons) do
				stuff[#stuff + 1] = "openpermissions " .. name
			end
		end
	end
	table.sort(stuff)
	return stuff
end)

net.Receive("OpenPermissions.NoPermissions", function()
	OpenPermissions:ChatPrint(L"operator_only_menu", "[ERROR]", OpenPermissions.COLOR_RED)
end)

net.Receive("OpenPermissions.NotAnAddon", function()
	OpenPermissions:ChatPrint(L"not_an_addon", "[ERROR]", OpenPermissions.COLOR_RED)
end)