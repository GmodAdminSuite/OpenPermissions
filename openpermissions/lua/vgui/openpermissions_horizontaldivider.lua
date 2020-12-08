local PANEL = {}

function PANEL:SetRightWidth(width)
	self.InitialRightWidth = width

	local oldpaint = self.Paint
	self.Paint = function(self, w, h)
		self:SetLeftWidth(w - self.InitialRightWidth)
		self.Paint = oldpaint
	end
end

function PANEL:BalanceWidths()
	local oldpaint = self.Paint
	self.Paint = function(self, w, h)
		self:SetLeftWidth((w - self:GetDividerWidth()) / 2)
		self.Paint = oldpaint
	end
end

derma.DefineControl("OpenPermissions.HorizontalDivider", nil, PANEL, "DHorizontalDivider")