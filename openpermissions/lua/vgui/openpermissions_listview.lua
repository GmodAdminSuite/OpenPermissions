local PANEL = {}

function PANEL:Init()
	self.CurrentOffset = 0
	self.TargetOffset = 0
	self.StartTime = 0
	self.EndTime = 0

	self.VBar:SetHideButtons(true)
	self.VBar:SetWide(5)
	self.VBar:DockMargin(3,3,3,3)

	function self.VBar:Paint() end
	function self.VBar.btnGrip:Paint(w,h)
		surface.SetDrawColor(0,0,0,150)
		surface.DrawRect(0,0,w,h)
	end

	self.VBar.CurrentY = 0
	self.VBar.TargetY = 0
	function self.VBar:PerformLayout()

		local Wide = self:GetWide()
		local BtnHeight = Wide
		if ( self:GetHideButtons() ) then BtnHeight = 0 end
		local Scroll = self:GetScroll() / self.CanvasSize
		local BarSize = math.max( self:BarScale() * ( self:GetTall() - ( BtnHeight * 2 ) ), 10 )
		local Track = self:GetTall() - ( BtnHeight * 2 ) - BarSize
		Track = Track + 1

		Scroll = Scroll * Track

		self.TargetY = BtnHeight + Scroll
		self.btnGrip:SetSize( Wide, BarSize )

		if ( BtnHeight > 0 ) then
			self.btnUp:SetPos( 0, 0, Wide, Wide )
			self.btnUp:SetSize( Wide, BtnHeight )

			self.btnDown:SetPos( 0, self:GetTall() - BtnHeight )
			self.btnDown:SetSize( Wide, BtnHeight )
			
			self.btnUp:SetVisible( true )
			self.btnDown:SetVisible( true )
		else
			self.btnUp:SetVisible( false )
			self.btnDown:SetVisible( false )
			self.btnDown:SetSize( Wide, BtnHeight )
			self.btnUp:SetSize( Wide, BtnHeight )
		end

	end

	function self.VBar:Think()
		self.CurrentY = Lerp(FrameTime() * 10, self.CurrentY, self.TargetY)
		self.btnGrip:SetPos(0, math.Round(self.CurrentY))
	end

	self.pnlCanvas.CurrentOffset = 0
	self.pnlCanvas.TargetOffset = 0
	function self.pnlCanvas:Think()
		self.CurrentOffset = Lerp(FrameTime() * 10, self.CurrentOffset, self.TargetOffset)
		self:SetPos(0, math.Round(self.CurrentOffset + self:GetParent():GetHeaderHeight()))
	end
end

function PANEL:OnVScroll(offset)
	self.pnlCanvas.TargetOffset = offset
end

function PANEL:PerformLayout()

	-- Do Scrollbar
	local Wide = self:GetWide()
	local YPos = 0

	if ( IsValid( self.VBar ) ) then

		self.VBar:SetPos( self:GetWide() - 5 - 3, 3 )
		self.VBar:SetSize( 5, self:GetTall() - 6 )
		self.VBar:SetUp( self.VBar:GetTall() - self:GetHeaderHeight(), self.pnlCanvas:GetTall() )
		YPos = self.VBar:GetOffset()

		if ( self.VBar.Enabled ) then Wide = Wide - 5 end

	end

	if ( self.m_bHideHeaders ) then
		self.pnlCanvas:SetPos( 0, YPos )
	else
		self.pnlCanvas:SetPos( 0, YPos + self:GetHeaderHeight() )
	end

	self.pnlCanvas:SetSize( Wide + self.VBar:GetWide(), self.pnlCanvas:GetTall() )

	self:FixColumnsLayout()

	--
	-- If the data is dirty, re-layout
	--
	if ( self:GetDirty() ) then

		self:SetDirty( false )
		local y = self:DataLayout()
		self.pnlCanvas:SetTall( y )

		-- Layout again, since stuff has changed..
		self:InvalidateLayout( true )

	end

end

derma.DefineControl("OpenPermissions.ListView", nil, PANEL, "DListView")