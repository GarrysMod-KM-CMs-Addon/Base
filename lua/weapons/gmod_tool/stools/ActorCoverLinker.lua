TOOL.Category = "Actor"
TOOL.Name = "#tool.ActorCoverLinker.name"

if CLIENT then function TOOL.BuildCPanel( CPanel ) CPanel:Help "#ActorCoverLinkerToolHelp" end return end

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
	local tCovers = __COVERS_STATIC__[ pArea:GetID() ]
	if tCovers then
		for iIndex, tCover in ipairs( tCovers ) do
			if util.DistanceToLine( tCover[ 1 ], tCover[ 2 ], vPos ) > 4 then continue end
			local pCover = self.pCover
			if pCover then
				local t = pCover[ 4 ]
				if t then
					local t2 = t[ pArea:GetID() ]
					if t2 then t2[ iIndex ] = true
					else t[ pArea:GetID() ] = { [ iIndex ] = true } end
				else pCover[ 4 ] = { [ pArea:GetID() ] = { [ iIndex ] = true } } end
				local t = tCover[ 4 ]
				if t then
					local t2 = t[ self.iAreaID ]
					if t2 then t2[ self.iCoverID ] = true
					else t[ self.iAreaID ] = { [ self.iCoverID ] = true } end
				else tCover[ 4 ] = { [ self.iAreaID ] = { [ self.iCoverID ] = true } } end
				self.pCover = nil
				return
			end
			self.pCover = tCover
			self.iAreaID = pArea:GetID()
			self.iCoverID = iIndex
			return
		end
	end
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
		for iIndex, tCover in ipairs( tCovers ) do
			if util.DistanceToLine( tCover[ 1 ], tCover[ 2 ], vPos ) > 4 then continue end
			local pCover = self.pCover
			if pCover then
				local t = pCover[ 4 ]
				if t then
					local t2 = t[ pArea:GetID() ]
					if t2 then t2[ iIndex ] = nil
					else t[ pArea:GetID() ] = { [ iIndex ] = nil } end
				else pCover[ 4 ] = { [ pArea:GetID() ] = { [ iIndex ] = nil } } end
				local t = tCover[ 4 ]
				if t then
					local t2 = t[ self.iAreaID ]
					if t2 then t2[ self.iCoverID ] = nil
					else t[ self.iAreaID ] = { [ self.iCoverID ] = nil } end
				else tCover[ 4 ] = { [ self.iAreaID ] = { [ self.iCoverID ] = nil } } end
				self.pCover = nil
				return
			end
			self.pCover = tCover
			self.iAreaID = pArea:GetID()
			self.iCoverID = iIndex
			return
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
	local tCover = self.pCover
	if tCover then
		local vStart, vEnd = tCover[ 1 ], tCover[ 2 ]
		local vDirection = ( vEnd - vStart ):GetNormalized()
		debugoverlay.Line( vStart, vEnd, .1, Color( 0, 255, 0 ), true )
		local vStart, vEnd = tCover[ 1 ], tCover[ 2 ]
		local vCenter = ( vStart + vEnd ) * .5
		local vRight = ( vEnd - vStart ):GetNormalized():Angle():Right()
		if tCover[ 3 ] then
			debugoverlay.Line( vCenter, vCenter + vRight * 12, .1, Color( 0, 255, 0 ), true )
		else
			debugoverlay.Line( vCenter, vCenter - vRight * 12, .1, Color( 0, 255, 0 ), true )
		end
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
			for iAreaID, tIndices in pairs( tCover[ 4 ] || {} ) do
				for iIndex in pairs( tIndices ) do
					local tNewCover = __COVERS_STATIC__[ iAreaID ][ iIndex ]
					local vStart, vEnd = tNewCover[ 1 ], tNewCover[ 2 ]
					local vDirection = ( vEnd - vStart ):GetNormalized()
					debugoverlay.Line( vStart, vEnd, .1, Color( 0, 255, 255 ), true )
					local vStart, vEnd = tNewCover[ 1 ], tNewCover[ 2 ]
					local vCenter = ( vStart + vEnd ) * .5
					debugoverlay.Line( vCenter, ( tCover[ 1 ] + tCover[ 2 ] ) * .5, .1, Color( 0, 255, 255 ), true )
					local vRight = ( vEnd - vStart ):GetNormalized():Angle():Right()
					if tNewCover[ 3 ] then
						debugoverlay.Line( vCenter, vCenter + vRight * 12, .1, Color( 0, 255, 255 ), true )
					else
						debugoverlay.Line( vCenter, vCenter - vRight * 12, .1, Color( 0, 255, 255 ), true )
					end
				end
			end
		end
	end
end
