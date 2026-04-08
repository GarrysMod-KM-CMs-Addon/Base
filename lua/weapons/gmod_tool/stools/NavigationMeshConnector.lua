TOOL.Category = "Navigation Mesh"
TOOL.Name = "#tool.NavigationMeshConnector.name"

if CLIENT then function TOOL.BuildCPanel( CPanel ) CPanel:Help "#NavigationMeshConnectorToolHelp" end return end

function TOOL:LeftClick()
	local pOwner = self:GetOwner()
	if !pOwner:IsSuperAdmin() then return end
	local tr = util.TraceLine {
		start = pOwner:EyePos(),
		endpos = pOwner:EyePos() + pOwner:GetAimVector() * 999999,
		mask = MASK_SOLID_BRUSHONLY,
		filter = pOwner
	}
	local pArea = navmesh.GetNearestNavArea( tr.HitPos )
	if !pArea then return end
	local pOther = self.pOther
	if pOther then
		if pArea:IsConnected( pOther ) && pOther:IsConnected( pArea ) then
			pArea:Disconnect( pOther )
			pOther:Disconnect( pArea )
		else
			pArea:ConnectTo( pOther )
			pOther:ConnectTo( pArea )
		end
		navmesh.Save()
		self.pOther = nil
	else self.pOther = pArea end
end

function TOOL:Reload() self.pOther = nil end
