local PANEL = {}

AccessorFunc( PANEL, "m_bShowIcons", "ShowIcons" )
AccessorFunc( PANEL, "m_iIndentSize", "IndentSize" )
AccessorFunc( PANEL, "m_iLineHeight", "LineHeight" )
AccessorFunc( PANEL, "m_pSelectedItem", "SelectedItem" )
AccessorFunc( PANEL, "m_bClickOnDragHover", "ClickOnDragHover" )

function PANEL:Init()

	self:SetShowIcons( true )
	self:SetIndentSize( 14 )
	self:SetLineHeight( 17 )

	self.RootNode = self:GetCanvas():Add( "DTree_Node" )
	self.RootNode:SetRoot( self )
	self.RootNode:SetParentNode( self )
	self.RootNode:Dock( TOP )
	self.RootNode:SetText( "" )
	self.RootNode:SetExpanded( true, true )
	self.RootNode:DockMargin( 0, 4, 0, 0 )

	self:SetPaintBackground( true )

end

function PANEL:Root()
	return self.RootNode
end

function PANEL:AddNode( strName, strIcon )

	return self.RootNode:AddNode( strName, strIcon )

end

function PANEL:ChildExpanded( bExpand )

	self:InvalidateLayout()

end

function PANEL:ShowIcons()

	return self.m_bShowIcons

end

function PANEL:ExpandTo( bExpand )
end

function PANEL:SetExpanded( bExpand )
end

function PANEL:Clear()
	self:Root():Clear()
end

function PANEL:Paint( w, h )

	derma.SkinHook( "Paint", "Tree", self, w, h )
	return true

end

function PANEL:DoClick( node )
	return false
end

function PANEL:DoRightClick( node )
	return false
end

function PANEL:SetSelectedItem( node )

	if ( IsValid( self.m_pSelectedItem ) ) then
		self.m_pSelectedItem:SetSelected( false )
	end

	self.m_pSelectedItem = node

	if ( node ) then
		node:SetSelected( true )
		node:OnNodeSelected( node )
	end

end

function PANEL:OnNodeSelected( node )
end

function PANEL:MoveChildTo( child, pos )

	self:InsertAtTop( child )

end

function PANEL:LayoutTree()

	self:InvalidateChildren( true )

end

derma.DefineControl("OpenPermissions.Tree", nil, PANEL, "OpenPermissions.ScrollPanel")