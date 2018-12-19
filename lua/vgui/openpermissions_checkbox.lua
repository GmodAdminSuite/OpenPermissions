local PANEL = {}

function PANEL:Init()
	self:SetMouseInputEnabled(true)
	self:SetCursor("hand")
	self:SetSize(16,16)

	self.Crossable = false
	self.Checked = false
end

function PANEL:SetCrossable(crossable)
	self.Crossable = crossable == true
	if (crossable) then
		self.Checked = 0
	else
		self.Checked = false
	end
end
function PANEL:IsCrossable()
	return self.Crossable
end

function PANEL:DoClick()
	self:SetAmbigious(false)
	if (self.Crossable) then
		self.Checked = self.Checked + 1
		if (self.Checked == 3) then
			self.Checked = 0
		end
	else
		self.Checked = not self.Checked
	end
	if (self.OnChange) then
		self:OnChange()
	end
end
function PANEL:DoRightClick()
	if (self.Crossable) then
		self:SetAmbigious(false)
		self.Checked = self.Checked - 1
		if (self.Checked == -1) then
			self.Checked = 2
		end
		if (self.OnChange) then
			self:OnChange()
		end
	end
end

function PANEL:OnMousePressed(m)
	if (m == MOUSE_LEFT) then
		self.Debounce_LEFT = true
	elseif (m == MOUSE_RIGHT) then
		self.Debounce_RIGHT = true
	end
end
function PANEL:OnMouseReleased(m)
	if (m == MOUSE_LEFT) then
		if (self.Debounce_LEFT) then
			self:DoClick()
		end
		self.Debounce_LEFT = nil
	elseif (m == MOUSE_RIGHT) then
		if (self.Debounce_RIGHT) then
			self:DoRightClick()
		end
		self.Debounce_RIGHT = nil
	end
end

function PANEL:GetChecked()
	return self.Checked
end
function PANEL:SetChecked(checked)
	self:SetAmbigious(false)
	self.Checked = checked
end

function PANEL:SetAmbigious(ambigious)
	self.Ambigious = ambigious
end
function PANEL:IsAmbigious()
	return self.Ambigious
end

local mat_checked = Material("openpermissions/checked.vtf")
local mat_crossed = Material("openpermissions/crossed.vtf")
local darker_soft_green = Color(52,145,52)
function PANEL:Paint(w,h)
	surface.SetDrawColor(OpenPermissions.COLOR_WHITE)
	surface.DrawRect(0,0,w,h)

	if (self.Crossable and self.Ambigious) then
		surface.SetDrawColor(OpenPermissions.COLOR_BLACK)
	elseif (self.Checked == true or self.Checked == 1) then
		surface.SetDrawColor(darker_soft_green)
	elseif (self.Checked == 2) then
		surface.SetDrawColor(OpenPermissions.COLOR_SOFT_RED)
	else
		surface.SetDrawColor(OpenPermissions.COLOR_BLACK)
	end
	surface.DrawOutlinedRect(0,0,w,h)

	if (self.Crossable and self.Ambigious) then
		surface.SetDrawColor(OpenPermissions.COLOR_SOFT_GREEN)
		surface.DrawRect(3,3,w - 6, h - 6)
	elseif (self.Checked == true or self.Checked == 1) then
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(mat_checked)
		surface.DrawTexturedRect(0,0,w,h)
	elseif (self.Checked == 2) then
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(mat_crossed)
		surface.DrawTexturedRect(0,0,w,h)
	end
end

derma.DefineControl("OpenPermissions.Checkbox", nil, PANEL, "DPanel")