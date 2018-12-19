local function markup_Escape(str)
	return (tostring(str):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local PANEL = {}

function PANEL:Init()
	self:SetText("")
end

function PANEL:GenerateMarkup(text, maxwidth)
	self.Addon.Markup = markup.Parse("<color=255,255,255>" .. markup_Escape(text) .. "</color>", maxwidth)
end

function PANEL:Setup(id, options)
	self.Addon = {}

	self.Addon.Name = options.Name or id
	self.Addon.Color = options.Color or OpenPermissions.COLOR_BLACK

	if (options.Logo and options.Logo.Path and options.Logo.Width and options.Logo.Height) then
		self.Addon.Logo = {
			Material = Material(options.Logo.Path),
			Width = options.Logo.Width / 2,
			Height = options.Logo.Height / 2
		}
	end
end

function PANEL:Paint(w,h)
	derma.SkinHook("Paint", "Button", self, w, h)

	if (not self.Addon) then return end

	surface.SetDrawColor(self.Addon.Color)
	surface.DrawRect(5, 5, w - 10, h - 10)

	if (self.Addon.Logo) then
		local x,y = w / 2 - self.Addon.Logo.Width / 2, h / 2 - self.Addon.Logo.Height / 2
		surface.SetDrawColor(255,255,255)
		surface.SetMaterial(self.Addon.Logo.Material)
		surface.DrawTexturedRect(x, y, self.Addon.Logo.Width, self.Addon.Logo.Height)
	elseif (self.Addon.Markup) then
		self.Addon.Markup:Draw(w / 2, h / 2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		self:GenerateMarkup(self.Addon.Name, w - 20)
	end
end

derma.DefineControl("OpenPermissions.Addon", nil, PANEL, "DButton")