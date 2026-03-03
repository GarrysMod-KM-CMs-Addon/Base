TOOL.Category = "Actor"
TOOL.Name = "#tool.ActorCover.name"

if CLIENT then function TOOL.BuildCPanel( CPanel ) CPanel:Help "#ActorCoverToolHelp" end return end

function TOOL:LeftClick()
	local pOwner = self:GetOwner()
	local tr = util.TraceLine {
		start = pOwner:EyePos(),
		endpos = pOwner:EyePos() + pOwner:GetAimVector() * 999999,
		mask = MASK_SOLID_BRUSHONLY,
		filter = pOwner
	}
	local vStart = self.vStart
	local vEnd = self.vEnd
	local vPos = tr.HitPos
	local pArea = navmesh.GetNearestNavArea( vPos )
	if !IsValid( pArea ) then return end
	vPos[ 3 ] = pArea:GetZ( vPos )
	if vStart then
		if vEnd then
			local vCenter = ( vStart + vEnd ) * .5
			local vDirection = ( vEnd - vStart ):GetNormalized()
			local vRight = vDirection:Angle():Right()
			local tParticipatingAreas = {}
			for flCurrent = 0, vStart:Distance( vEnd ), 12 do
				local vCurrent = vStart + vDirection * flCurrent
				local pArea = navmesh.GetNearestNavArea( vCurrent )
				if !pArea then continue end
				tParticipatingAreas[ pArea:GetID() ] = true
			end
			local tCover = { vStart, vEnd, ( vPos - vStart ):GetNormalized():Dot( vRight ) > 0 }
			for ID in pairs( tParticipatingAreas ) do
				local tCovers = __COVERS_STATIC__[ ID ]
				if tCovers then table.insert( tCovers, tCover )
				else __COVERS_STATIC__[ ID ] = { tCover } end
			end
			self.vStart = nil
			self.vEnd = nil
		else
			self.vEnd = vPos
		end
	else self.vStart = vPos end
end

function TOOL:RightClick()
	local pOwner = self:GetOwner()
	local tr = util.TraceLine {
		start = pOwner:EyePos(),
		endpos = pOwner:EyePos() + pOwner:GetAimVector() * 999999,
		mask = MASK_SOLID_BRUSHONLY,
		filter = pOwner
	}
	local vPos = tr.HitPos
	local pArea = navmesh.GetNearestNavArea( vPos )
	if !IsValid( pArea ) then return end
	vPos[ 3 ] = pArea:GetZ( vPos )
	local tCovers = __COVERS_STATIC__[ pArea:GetID() ]
	if tCovers then
		local tCoversToRemove = {}
		for iIndex, tCover in ipairs( tCovers ) do
			if util.DistanceToLine( tCover[ 1 ], tCover[ 2 ], vPos ) > 4 then continue end
			tCoversToRemove[ tCover ] = true
		end
		for tCover in pairs( tCoversToRemove ) do
			local tParticipatingAreas = {}
			local vStart, vEnd = tCover[ 1 ], tCover[ 2 ]
			local vDirection = ( vEnd - vStart ):GetNormalized()
			for flCurrent = 0, vStart:Distance( vEnd ), 12 do
				local vCurrent = vStart + vDirection * flCurrent
				local pArea = navmesh.GetNearestNavArea( vCurrent )
				if !pArea then continue end
				tParticipatingAreas[ pArea:GetID() ] = true
			end
			for ID in pairs( tParticipatingAreas ) do
				local tCovers = __COVERS_STATIC__[ ID ]
				if tCovers then
					local tNewCovers = {}
					for iIndex, tLoopCover in ipairs( tCovers ) do
						if tLoopCover == tCover then continue end
						tNewCovers[ iIndex ] = tLoopCover
					end
					if table.IsEmpty( tNewCovers ) then __COVERS_STATIC__[ ID ] = nil
					else __COVERS_STATIC__[ ID ] = tNewCovers end
				end
			end
		end
	end
end

function TOOL:Think()
	local pOwner = self:GetOwner()
	local tr = util.TraceLine {
		start = pOwner:EyePos(),
		endpos = pOwner:EyePos() + pOwner:GetAimVector() * 999999,
		mask = MASK_SOLID_BRUSHONLY,
		filter = pOwner
	}
	local vPos = tr.HitPos
	local pArea = navmesh.GetNearestNavArea( vPos )
	if !IsValid( pArea ) then return end
	local vStart = self.vStart
	if vStart then
		vPos[ 3 ] = pArea:GetZ( vPos )
		local vEnd = self.vEnd
		if vEnd then
			debugoverlay.Line( vStart, vEnd, .1, Color( 0, 255, 255 ), true )
			local vCenter = ( vStart + vEnd ) * .5
			local vRight = ( vEnd - vStart ):GetNormalized():Angle():Right()
			if ( vPos - vStart ):GetNormalized():Dot( vRight ) < 0 then
				debugoverlay.Line( vCenter, vCenter - vRight * 12, .1, Color( 0, 255, 255 ), true )
			else
				debugoverlay.Line( vCenter, vCenter + vRight * 12, .1, Color( 0, 255, 255 ), true )
			end
		else debugoverlay.Line( vStart, vPos, .1, Color( 0, 255, 255 ), true ) end
	end
	local tCovers = __COVERS_STATIC__[ pArea:GetID() ]
	if tCovers then
		for _, tCover in ipairs( tCovers ) do
			local vStart, vEnd = tCover[ 1 ], tCover[ 2 ]
			local vDirection = ( vEnd - vStart ):GetNormalized()
			debugoverlay.Line( vStart, vEnd, .1, Color( 0, 255, 255 ), true )
			local vStart, vEnd = tCover[ 1 ], tCover[ 2 ]
			local vCenter = ( vStart + vEnd ) * .5
			local vRight = ( vEnd - vStart ):GetNormalized():Angle():Right()
			if tCover[ 3 ] then
				debugoverlay.Line( vCenter, vCenter + vRight * 12, .1, Color( 0, 255, 255 ), true )
			else
				debugoverlay.Line( vCenter, vCenter - vRight * 12, .1, Color( 0, 255, 255 ), true )
			end
		end
	end
end
