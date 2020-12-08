local bg_color = Color(43,48,58,255)

local PANEL = {}

function PANEL:Init()
	self:SetDrawOnTop(true)

	self.Label = vgui.Create("DLabel", self)
	self.Label:SetFont(bVGUI.FONT(bVGUI.FONT_CIRCULAR, "REGULAR", 14))
	self.Label:SetText("Tooltip")
	self.Label:SetTextColor(bVGUI.COLOR_WHITE)
	self.Label:SetContentAlignment(5)
	self.Label:SetWrap(true)

	self.Arrow = {
		{x = 0, y = 0},
		{x = 0, y = 0},
		{x = 0, y = 0}
	}
end

function PANEL:Paint(w,h)
	draw.RoundedBox(4, 0, 0, w, h, self.BackgroundColor or bg_color)
	surface.DisableClipping(true)

	surface.SetDrawColor(self.BackgroundColor or bg_color)
	draw.NoTexture()

	self.Arrow[1].x = w / 2 - 7
	self.Arrow[1].y = h

	self.Arrow[2].x = w / 2 + 7
	self.Arrow[2].y = h

	self.Arrow[3].x = w / 2
	self.Arrow[3].y = h + 7

	surface.DrawPoly(self.Arrow)

	surface.DisableClipping(false)
end

function PANEL:Think()
	local x,y = self.Label:GetSize()
	self:SetSize(x + 15, y + 7)
	self.Label:Center()
	local x,y = gui.MousePos()
	self:SetPos(x - self:GetWide() / 2, y - self:GetTall() - 14 - 5)

	if (not system.HasFocus()) then
		self:Remove()
	elseif (self.VGUI_Element) then
		if (not IsValid(self.VGUI_Element)) then
			self:Remove()
		elseif (vgui.GetHoveredPanel() ~= self.VGUI_Element) then
			if (self.HoverFrameNumber) then
				if (FrameNumber() > self.HoverFrameNumber) then
					self:Remove()
				end
			else
				self.HoverFrameNumber = FrameNumber() + 1
			end
		end
	end
end

function PANEL:SetText(text)
	self.Label:SetText(text)
	self.Label:SetWrap(false)
	self.Label:SizeToContentsX()
	if (self.Label:GetWide() >= 200) then
		self.Label:SetWide(200)
		self.Label:SetWrap(true)
		self.Label:SetAutoStretchVertical(true)
	end
end

derma.DefineControl("OpenPermissions.Tooltip", nil, PANEL, "DPanel")