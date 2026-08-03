local SortByMember = table.SortByMember
local insert = table.insert
local remove = table.remove
local IsEmpty = table.IsEmpty

local GetNearestNavArea = navmesh.GetNearestNavArea

local unpack = unpack

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

function ENT:SearchAreas( vPos, fWeighter, MyTable )
	vPos = vPos || self:GetPos()

	local pArea = GetNearestNavArea( vPos )
	if !pArea then return function() end end

	MyTable = MyTable || CEntity_GetTable( self )

	local tQueue, tVisited = { { pArea, 0 } }, {}

	local bCantClimb, flJumpHeight, flNegDeathDrop = !MyTable.bCanClimb, MyTable.loco:GetJumpHeight(), -MyTable.loco:GetDeathDropHeight()

	local tAllies = MyTable.GetAlliesByClass( self, MyTable )

	local flOff = math.max( math.abs( self:OBBMaxs().x ), math.abs( self:OBBMins().x ) ) * 1.5

	local flOffDistSqr = flOff * 3
	flOffDistSqr = flOffDistSqr * flOffDistSqr

	local vOffStanding, vOffDucking = Vector( 0, 0, MyTable.vHullMaxs.z )
	if MyTable.vHullDuckMaxs && MyTable.vHullDuckMaxs.z != MyTable.vHullMaxs.z then vOffDucking = Vector( 0, 0, MyTable.vHullDuckMaxs.z ) end

	local bDisAllowWater = !MyTable.bCanSwim

	fWeighter = fWeighter || function( _/*pFrom*/, _/*pTo*/, flCurrentDistance, flAdditionalDistance ) return flCurrentDistance + flAdditionalDistance end

	return function()
		while !IsEmpty( tQueue ) do
			local pArea, flDistance = unpack( remove( tQueue ) )

			local iIdentifier = pArea:GetID()
			if tVisited[ iIdentifier ] then continue end
			tVisited[ iIdentifier ] = true

			local bNew
			for _, t in ipairs( pArea:GetAdjacentAreaDistances() ) do
				local pNew = t.area

				if tVisited[ pNew:GetID() ] then continue end

				if bDisAllowWater && pNew:IsUnderwater() then continue end

				local flChange = pArea:ComputeAdjacentConnectionHeightChange( pNew )
				if bCantClimb && flChange > flJumpHeight || flChange <= flNegDeathDrop then continue end

				insert( tQueue, { pNew, fWeighter( pArea, pNew, flDistance, t.dist ) } )

				bNew = true
			end

			// Sorting is expensive. We need to only sort this if we actually did something.
			if bNew then SortByMember( tQueue, 2 ) end

			return pArea, flDistance
		end
	end
end

// TODO: Implement flSpacing in a way that isn't CPU heavy as shit
function ENT:SearchNodes( vPos, fWeighter, flSpacing )
	if !vPos then vPos = self:GetPos() end

	local area = GetNearestNavArea( vPos )
	if !area then return function() end end

	// flSpacing = self:BoundingRadius() * ( flSpacing || 10 )
	local tQueue, tVisited = { { true, area, 0, 0, vPos } }, { [ area:GetID() ] = true }
	local bCantClimb, flJumpHeight, flNegDeathDrop = !self.bCanClimb, self.loco:GetJumpHeight(), -self.loco:GetDeathDropHeight()
	local tAllies = self:GetAlliesByClass()
	local flOff = math.max( math.abs( self:OBBMaxs().x ), math.abs( self:OBBMins().x ) ) * 1.5
	local flOffDistSqr = flOff * 3
	flOffDistSqr = flOffDistSqr * flOffDistSqr
	local vOffStanding, vOffDucking = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && self.vHullDuckMaxs.z != self.vHullMaxs.z then vOffDucking = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	fWeighter = fWeighter || function( _/*vNew*/, flCurrentDistance, flAdditionalDistance/*, pArea*/ ) return flCurrentDistance + flAdditionalDistance end
	local function F()
		if !IsEmpty( tQueue ) then
			local bIsArea, area, dist, weight, vPrev = unpack( remove( tQueue ) )
			if bIsArea then
				local vCenter = area:GetCenter()
				local f
				for _, t in ipairs( area:GetAdjacentAreaDistances() ) do
					local new = t.area
					local id = new:GetID()
					if tVisited[ id ] then continue end
					tVisited[ id ] = true
					if bDisAllowWater && area:IsUnderwater() then continue end
					local d = area:ComputeAdjacentConnectionHeightChange( new )
					if bCantClimb && d > flJumpHeight || d <= flNegDeathDrop then continue end
					insert( tQueue, { true, new, dist + t.dist, fWeighter( new:GetClosestPointOnArea( vCenter ), dist, t.dist, new ), vCenter } )
				end
				local v = area:GetCorner( 0 ) // NORTH_WEST
				local flCornerX, flCornerY = v.x, v.y
				local flSizeX, flSizeY = area:GetSizeX(), area:GetSizeY()
				f = vCenter:Distance( vPrev )
				local n = dist + f
				insert( tQueue, { false, vCenter, n, fWeighter( v, dist, n ), vCenter } )
				// Sorting is expensive. We need to only sort this if we actually did something.
				SortByMember( tQueue, 4 )
				return F(), area, dist
			end
			return area
		end
	end
	return F
end
