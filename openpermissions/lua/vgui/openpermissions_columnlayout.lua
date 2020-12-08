local PANEL = {}

OpenPermissions_COLUMN_LAYOUT_COLUMN_GROW = 0
OpenPermissions_COLUMN_LAYOUT_COLUMN_SHRINK = 1
OpenPermissions_COLUMN_LAYOUT_COLUMN_GROW_COLUMN = 2

function PANEL:Init()
	self.Columns = {}
	self.Rows = {}
	self.ColumnPadding = 0
	self.RowPadding = 0

	function self.pnlCanvas:PerformLayout()
		self:GetParent():ColumnLayout()
		self:InvalidateParent(true)
	end
end

function PANEL:SetPaddings(column_padding, row_padding)
	self.ColumnPadding = column_padding
	self.RowPadding = row_padding
end

function PANEL:SetColumns(...)
	self.Columns = {...}
	self.GrowColumnCount = 0
	for _,v in ipairs(self.Columns) do
		if (v == OpenPermissions_COLUMN_LAYOUT_COLUMN_GROW or v == OpenPermissions_COLUMN_LAYOUT_COLUMN_GROW_COLUMN) then
			self.GrowColumnCount = self.GrowColumnCount + 1
		end
	end
end

function PANEL:AddRow(...)
	local i = table.insert(self.Rows, {...})
	self.pnlCanvas:InvalidateLayout(true)
	return i
end

function PANEL:RemoveRow(row_index)
	for _,element in ipairs(self.Rows[row_index]) do
		element:Remove()
	end
	table.remove(self.Rows, row_index)
	self.pnlCanvas:InvalidateLayout(true)
end

function PANEL:ColumnLayout()
	local column_widths = {}
	local row_heights = {}
	for row_i, elements in ipairs(self.Rows) do
		for column_i, element in ipairs(elements) do
			if (self.Columns[column_i] == OpenPermissions_COLUMN_LAYOUT_COLUMN_SHRINK) then
				local element_w = element:GetWide()
				local column_w = column_widths[column_i]
				if (not column_w or element_w > column_w) then
					column_widths[column_i] = element_w
				end
			end
			if (self.Columns[column_i] ~= OpenPermissions_COLUMN_LAYOUT_COLUMN_GROW_COLUMN) then
				local element_h = element:GetTall()
				local row_h = row_heights[row_i]
				if (not row_h or element_h > row_h) then
					row_heights[row_i] = element_h
				end
			end
		end
	end
	local grow_column_width = 0
	for i,v in pairs(column_widths) do
		grow_column_width = grow_column_width - v - self.ColumnPadding
	end
	grow_column_width = ((grow_column_width + self:GetWide()) / self.GrowColumnCount) - 4

	local row_y = 0
	for row_i, elements in ipairs(self.Rows) do
		local column_x = 0
		for column_i, element in ipairs(elements) do
			local column_sizing = self.Columns[column_i]
			if (column_sizing == OpenPermissions_COLUMN_LAYOUT_COLUMN_SHRINK) then
				element:SetWide(column_widths[column_i])
				element:SetPos(column_x, row_y)
				column_x = column_x + column_widths[column_i] + self.ColumnPadding
			elseif (column_sizing == OpenPermissions_COLUMN_LAYOUT_COLUMN_GROW or column_sizing == OpenPermissions_COLUMN_LAYOUT_COLUMN_GROW_COLUMN) then
				if (OpenPermissions_COLUMN_LAYOUT_COLUMN_GROW_COLUMN) then
					element:SetWide(grow_column_width)
				else
					element:SetSize(grow_column_width, row_heights[row_i])
				end
				element:SetPos(column_x, row_y)
				column_x = column_x + grow_column_width + self.ColumnPadding
			end
		end
		row_y = row_y + row_heights[row_i] + self.RowPadding
	end
end

derma.DefineControl("OpenPermissions.ColumnLayout", nil, PANEL, "OpenPermissions.ScrollPanel")