ENT.tAlertSearchedAreas = {}
ENT.tAlertContext = {}

function ENT:PrepareAlert( MyTable )
	MyTable.tAlertSearchedAreas = {}
	//	MyTable.tAlertContext = {}
end

function ENT:ShareAlertContext( pOther, MyTable )
	// Nuh uh!
	//	pOther.tAlertSearchedAreas = {}
	pOther.tAlertContext = table.Copy( MyTable.tAlertContext )
	pOther:SetSchedule( "Alert" ).ALERT_PREPARED = true
end

RegisterSchedule( "Alert", { Execute = function( self, pSchedule, MyTable )
	local tEnemies = MyTable.tEnemies
	if !table.IsEmpty( tEnemies ) then return true end

	MyTable.EScheduleState = ACTOR_STATE_ALERT

	if !pSchedule.ALERT_PREPARED then MyTable.PrepareAlert( self, MyTable ) end

	MyTable.SetSchedule( self, "AlertFindDestination", MyTable )
end } )

local function LookAround( self, pSchedule, MyTable )
	if math.random( 3 ) == 1 then
		MyTable.SetSchedule( self, "AlertFindDestination", MyTable ).bShutTheHellUp = math.random( 3 ) == 1 && !pSchedule.bShutTheHellUp || !!pSchedule.bShutTheHellUp
		return
	end

	local flTime = CurTime() + math.random() * math.random() * 8

	while CurTime() <= flTime do
		if CurTime() > ( pSchedule.flNextLook || 0 ) then
			local a = Angle( math.Rand( -20, 20 ), math.Rand( -70, 70 ) )
			MyTable.vaAimTargetPose = self:GetAngles() + a
			pSchedule.flNextLook = CurTime() + ( math.abs( a[ 1 ] ) + math.abs( a[ 2 ] ) ) / math.Rand( 20, 40 )
		end

		coroutine.yield()
	end

	if math.random( 3 ) == 1 then
		MyTable.SetSchedule( self, "AlertFindDestination", MyTable ).bShutTheHellUp = math.random( 3 ) == 1 && !pSchedule.bShutTheHellUp || !!pSchedule.bShutTheHellUp
		return
	end

	MyTable.vaAimTargetBody = ( -pSchedule.aInitialFacing:Forward() ):Angle()
	MyTable.vaAimTargetPose = MyTable.vaAimTargetBody

	coroutine.wait( math.Rand( 1, 2 ) )

	local flTime = CurTime() + math.random() * math.random() * 8

	while CurTime() <= flTime do
		if CurTime() > ( pSchedule.flNextLook || 0 ) then
			local a = Angle( math.Rand( -20, 20 ), math.Rand( -70, 70 ) )
			MyTable.vaAimTargetPose = self:GetAngles() + a
			pSchedule.flNextLook = CurTime() + ( math.abs( a[ 1 ] ) + math.abs( a[ 2 ] ) ) / math.Rand( 20, 40 )
		end

		coroutine.yield()
	end

	MyTable.SetSchedule( self, "AlertFindDestination", MyTable ).bShutTheHellUp = math.random( 3 ) == 1 && !pSchedule.bShutTheHellUp || !!pSchedule.bShutTheHellUp
end

RegisterSchedule( "AlertLookAround", { Execute = function( self, pSchedule, MyTable )
	local tEnemies = MyTable.tEnemies
	if !table.IsEmpty( tEnemies ) then return true end

	MyTable.EScheduleState = ACTOR_STATE_ALERT

	if !pSchedule.aInitialFacing then pSchedule.aInitialFacing = self:GetAngles() end

	if pSchedule.bShutTheHellUp == nil then pSchedule.bShutTheHellUp = math.random( 2 ) == 1 end

	if pSchedule.bShutTheHellUp then
		local fHush = MyTable.GekkoChirpControllerHush
		if fHush then fHush( self, MyTable, MyTable.m_flFrameTime ) end
	else
		local fRaise = MyTable.GekkoChirpControllerRaise
		if fRaise then fRaise( self, MyTable, MyTable.m_flFrameTime ) end
	end

	local pCoroutine = pSchedule.m_pCoroutine

	if !pSchedule.m_pCoroutine then
		pCoroutine = coroutine.create( LookAround )
		pSchedule.m_pCoroutine = pCoroutine
	end

	local bNoErrors, Return = coroutine.resume( pCoroutine, self, pSchedule, MyTable )
	if !bNoErrors then return true end
end } )

// TODO: As they walk, they should turn their head left and/or right
// using tracelines to aforementioned directions
local function GoToDestination( self, pSchedule, MyTable )
	local vGoal = pSchedule.pDestination:GetCenter()

	local pPath = pSchedule.pPath
	if !pPath then
		pPath = Path "Follow"
		pSchedule.pPath = pPath
	end

	local flStuckTime, vLastPos = 0, self:GetPos()
	local bDoubleChecked, bTripleChecked

	while flStuckTime <= 4 do
		local pGoal = pPath:GetCurrentGoal()
		if pGoal then
			MyTable.vaAimTargetBody = ( pGoal.pos - self:GetPos() ):Angle()
			MyTable.vaAimTargetPose = MyTable.vaAimTargetBody
		end

		if LevelOfDetail( pSchedule, "flNextPath" ) then MyTable.ComputePath( self, pPath, vGoal ) end

		MyTable.MoveAlongPath( self, pPath, MyTable.flPowerWalkSpeed || MyTable.flWalkSpeed )

		local f = self:OBBMaxs()[ 1 ]
		if self:GetPos():DistToSqr( vGoal ) <= f * f then
			MyTable.SetSchedule( self, "AlertLookAround", MyTable )
		end

		local f = MyTable.flWalkSpeed * MyTable.m_flFrameTime
		if self:GetPos():DistToSqr( vLastPos ) <= f * f then
			flStuckTime = flStuckTime + MyTable.m_flFrameTime
		else
			flStuckTime = math.max( 0, flStuckTime - MyTable.m_flFrameTime )
		end
		vLastPos = self:GetPos()

		coroutine.yield()
	end

	MyTable.SetSchedule( self, "AlertLookAround", MyTable ).bShutTheHellUp = math.random( 3 ) == 1 && !pSchedule.bShutTheHellUp || !!pSchedule.bShutTheHellUp
end

local function TellAlliesTheAreaIsClear( MyTable, EIdentifier )
	MyTable.tAlertSearchedAreas[ EIdentifier ] = CurTime()

	for pAlly in pairs( MyTable:GetAlliesByClass() ) do
		if pAlly.EScheduleState == ACTOR_STATE_ALERT then
			pAlly.tAlertSearchedAreas[ EIdentifier ] = CurTime()
		end
	end
end

RegisterSchedule( "AlertFindDestination", { Execute = function( self, pSchedule, MyTable )
	local tEnemies = MyTable.tEnemies
	if !table.IsEmpty( tEnemies ) then return true end

	MyTable.EScheduleState = ACTOR_STATE_ALERT

	if !pSchedule.aInitialFacing then pSchedule.aInitialFacing = self:GetAngles() end

	if pSchedule.bShutTheHellUp == nil then pSchedule.bShutTheHellUp = math.random( 2 ) == 1 end

	if pSchedule.bShutTheHellUp then
		local fHush = MyTable.GekkoChirpControllerHush
		if fHush then fHush( self, MyTable, MyTable.m_flFrameTime ) end
	else
		local fRaise = MyTable.GekkoChirpControllerRaise
		if fRaise then fRaise( self, MyTable, MyTable.m_flFrameTime ) end
	end

	local pDestination = pSchedule.pDestination
	if !pDestination then
		if pSchedule.bSearching then return end
		pSchedule.bSearching = true

		ACTOR_QUEUE( function()
			if !IsValid( self ) || MyTable.Schedule != pSchedule then return true end

			local pIterator = MyTable.SearchAreas( self, nil, nil, MyTable )
			local vHidden

			while true do
				for i = 1, 8 do
					if !IsValid( self ) || MyTable.Schedule != pSchedule then return true end

					local pArea = pIterator()
					if pArea == nil then
						MyTable.SetSchedule( self, "AlertLookAround", MyTable )
						return true
					end
	
					if MyTable.tAlertSearchedAreas[ pArea:GetID() ] then
						coroutine.yield()
						continue
					end
	
					if pArea:IsPartiallyVisible( self:GetPos() + self:OBBCenter(), self ) then
						TellAlliesTheAreaIsClear( MyTable, pArea:GetID() )
						coroutine.yield()
						continue
					end
	
					vHidden = pArea:GetCenter()
					break
				end

				if vHidden then break end
			end

			if !IsValid( self ) || MyTable.Schedule != pSchedule then return true end

			local pIterator = MyTable.SearchAreas( self, vHidden, nil, MyTable )
			vHidden[ 3 ] = vHidden[ 3 ] + MyTable.vHullMaxs[ 3 ] * .5

			while true do
				for i = 1, 8 do
					if !IsValid( self ) || MyTable.Schedule != pSchedule then return true end

					local pArea = pIterator()
					if pArea == nil then
						MyTable.SetSchedule( self, "AlertLookAround", MyTable )
						return true
					end
	
					if MyTable.tAlertSearchedAreas[ pArea:GetID() ] then
						coroutine.yield()
						continue
					end
	
					if pArea:IsPartiallyVisible( self:GetPos() + self:OBBCenter(), self ) then
						TellAlliesTheAreaIsClear( MyTable, pArea:GetID() )
						coroutine.yield()
						continue
					elseif pArea:IsPartiallyVisible( vHidden, self ) then
						coroutine.yield()
						continue
					end
	
					TellAlliesTheAreaIsClear( MyTable, pArea:GetID() )
					pSchedule.pDestination = pArea
	
					return true
				end
			end
		end )

		return
	end

	local pCoroutine = pSchedule.m_pCoroutine

	if !pSchedule.m_pCoroutine then
		pCoroutine = coroutine.create( GoToDestination )
		pSchedule.m_pCoroutine = pCoroutine
	end

	local bNoErrors, Return = coroutine.resume( pCoroutine, self, pSchedule, MyTable )
	if !bNoErrors then return true end
end } )
