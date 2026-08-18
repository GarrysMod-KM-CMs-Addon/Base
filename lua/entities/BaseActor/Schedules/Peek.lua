local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

local __SCHEDULE__ = __SCHEDULE__

local CurTime = CurTime

function ENT:GAME_SomeoneIsPeekingMe( pAttacker )
	local MyTable = CEntity_GetTable( self )
	local pSchedule = MyTable.Schedule
	if pSchedule then
		local sClassName = pSchedule.m_sName || ""
		local pScheduleClass = __SCHEDULE__[ sClassName ]
		if pScheduleClass then
			local fSomeoneIsPeekingMe = pScheduleClass.SomeoneIsPeekingMe
			if fSomeoneIsPeekingMe then fSomeoneIsPeekingMe( self, pSchedule, MyTable ) end
		end
	end
end

function ENT:PeekInHorizontal()
	return function( self, MyTable, pSchedule, flStand, vPeek )
		local pPath = pSchedule.pPath
		if !pPath then
			pPath = Path "Follow"
			pSchedule.pPath = pPath
		end

		MyTable.ComputePath( self, pPath, vPeek )

		local f = MyTable.vHullMaxs[ 2 ] * .25
		pPath:SetGoalTolerance( f )

		MyTable.MoveAlongPath( self, pPath, MyTable.flWalkSpeed, flStand )

		if self:GetPos():DistToSqr( vPeek ) <= ( f * f ) then return true end
	end
end

function ENT:PeekOutHorizontal()
	return function( self, MyTable, pSchedule, flStand, vCover )
		local pPath = pSchedule.pPath
		if !pPath then
			pPath = Path "Follow"
			pSchedule.pPath = pPath
		end

		MyTable.ComputePath( self, pPath, vCover )

		local f = MyTable.vHullMaxs[ 2 ] * .25
		pPath:SetGoalTolerance( f )

		MyTable.MoveAlongPath( self, pPath, MyTable.flWalkSpeed, flStand )

		if self:GetPos():DistToSqr( vCover ) <= ( f * f ) then return true end
	end
end

function ENT:PeekInVertical( MyTable, pSchedule )
	local flPeekTime = CurTime() + .25

	return function( self, MyTable, pSchedule )
		MyTable.Stand( self, 1 )

		return CurTime() >= flPeekTime
	end
end

function ENT:PeekOutVertical( MyTable, pSchedule )
	local flPeekTime = CurTime() + .25

	return function( self, MyTable, pSchedule )
		MyTable.Stand( self, 0 )

		return CurTime() >= flPeekTime
	end
end

function ENT:PeekPose( MyTable, vCover, vPeek, flStand ) MyTable.Stand( self, flStand ) end
function ENT:PeekVerticalPose( MyTable ) MyTable.Stand( self, 1 ) end

function ENT:GetMaxLateralPeekDistSqr( MyTable )
	local f = self:OBBMaxs()[ 2 ] * 5
	return f * f
end

function ENT:VolleySuppressingSettings( MyTable )
	MyTable.flWeaponPrimaryVolleyTimeMin = 0
	MyTable.flWeaponPrimaryVolleyTimeMax = 3

	MyTable.flWeaponPrimaryVolleyBreakMin = 0
	MyTable.flWeaponPrimaryVolleyBreakMax = .5

	MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMin = 0
	MyTable.flWeaponPrimaryVolleyNonAutomaticDelayMax = .2

	return true
end

RegisterSchedule( "PeekIn", {
	Execute = function( self, pSchedule, MyTable )
		local pEnemy = MyTable.Enemy
		if !IsValid( pEnemy ) then return true end
		local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )

		if !pSchedule.bHasWarned then
			pSchedule.bHasWarned = true

			if pEnemy != pTrueEnemy then
				local fSomeoneIsPeekingMe = pTrueEnemy.GAME_SomeoneIsPeekingMe
				if fSomeoneIsPeekingMe then fSomeoneIsPeekingMe( pTrueEnemy, self ) end
			end
		end

		MyTable.vActualCover = MyTable.vCover

		local tCover = MyTable.tCover

		local dBodyTarget = ( tCover.vEnd - tCover.vStart ):Angle():Right()
		if tCover.bRight then dBodyTarget:Negate() end
		MyTable.vaAimTargetBody = dBodyTarget:Angle()

		if pSchedule.bAtThem then
			local v = pEnemy:GetPos()
			v:Add( pEnemy:OBBCenter() )
			MyTable.vaAimTargetPose = v
		else MyTable.vaAimTargetPose = pSchedule.vSuppress end

		if pSchedule.bVertical then
			MyTable.vActualTarget = MyTable.vCover

			local fFunction = pSchedule.fFunction
			if !fFunction then
				fFunction = MyTable.PeekInVertical( self, MyTable )
				pSchedule.fFunction = fFunction
			end

			if fFunction( self, MyTable, pSchedule ) then
				local pPeek = MyTable.SetSchedule( self, "Peek", MyTable )
				pPeek.bVertical = true
				pPeek.bAtThem = pSchedule.bAtThem
				pPeek.vSuppress = pSchedule.vSuppress
				pPeek.vPeek = self:GetPos()
			end

			return
		end

		local flStand = pSchedule.bDuck && 0 || 1

		local fFunction = pSchedule.fFunction
		if !fFunction then
			fFunction = MyTable.PeekInHorizontal( self, MyTable, pSchedule, flStand, pSchedule.vPeek, MyTable.vCover )
			pSchedule.fFunction = fFunction
		end

		local vPeek = pSchedule.vPeek

		MyTable.vActualTarget = vPeek

		if fFunction( self, MyTable, pSchedule, flStand, vPeek, MyTable.vCover ) then
			local pPeek = MyTable.SetSchedule( self, "Peek", MyTable )
			pPeek.bAtThem = pSchedule.bAtThem
			pPeek.vSuppress = pSchedule.vSuppress
			pPeek.vPeek = vPeek
			pPeek.bDuck = pSchedule.bDuck
		end
	end
} )

RegisterSchedule( "PeekOut", {
	Execute = function( self, pSchedule, MyTable )
		local tCover = MyTable.tCover

		local dBodyTarget = ( tCover.vEnd - tCover.vStart ):Angle():Right()
		if tCover.bRight then dBodyTarget:Negate() end
		MyTable.vaAimTargetBody = dBodyTarget:Angle()

		if pSchedule.bAtThem then
			local v = pEnemy:GetPos()
			v:Add( pEnemy:OBBCenter() )
			MyTable.vaAimTargetPose = v
		else MyTable.vaAimTargetPose = pSchedule.vSuppress end

		MyTable.vActualCover = MyTable.vCover

		if pSchedule.bVertical then
			local fFunction = pSchedule.fFunction
			if !fFunction then
				fFunction = MyTable.PeekOutVertical( self, MyTable )
				pSchedule.fFunction = fFunction
			end

			if fFunction( self, MyTable, pSchedule ) then
				MyTable.SetSchedule( self, "Cover", MyTable )
			end

			return
		end

		local flStand = pSchedule.bDuck && 0 || 1

		local fFunction = pSchedule.fFunction
		if !fFunction then
			fFunction = MyTable.PeekOutHorizontal( self, MyTable, pSchedule, flStand, MyTable.vCover, pSchedule.vPeek )
			pSchedule.fFunction = fFunction
		end

		if fFunction( self, MyTable, pSchedule, flStand, MyTable.vCover, pSchedule.vPeek ) then
			MyTable.SetSchedule( self, "Cover", MyTable )
		end
	end
} )

/*
Quite a mouthful.

Basically, what this does is:

we were suppressing/firing at someone,
and someone else began peeking out to shoot us.
We are taking cover because of them.

This is NOT a suppressed "SHIT SHIT SHIT SHIT!",
nor is it a "HELP!! I'M GETTIN' HOLES HERE!".

If you've played Splinter Cell: Blacklist,
this is more of a Navy SEAL going "COVER! COVER!!",
or an American accented hostile "WATCH IT!"
*/
function ENT:DLG_PeekLeavePreShotAt() end

RegisterSchedule( "Peek", {
	Execute = function( self, pSchedule, MyTable )
		local pEnemy = MyTable.Enemy
		if !IsValid( pEnemy ) then return true end
		local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )

		MyTable.vActualCover = MyTable.vCover

		if !MyTable.bHoldFire && CurTime() > ( MyTable.flLastEnemy + MyTable.flHoldFireTime ) then MyTable.DLG_HoldFire( self, MyTable ) end

		local tCover = MyTable.tCover

		local dBodyTarget = ( tCover.vEnd - tCover.vStart ):Angle():Right()
		if tCover.bRight then dBodyTarget:Negate() end
		MyTable.vaAimTargetBody = dBodyTarget:Angle()

		if MyTable.GAME_flSuppression > self:Health() then
			local pPeek = MyTable.SetSchedule( self, "PeekOut", MyTable )
			pPeek.vPeek = pSchedule.vPeek
			pPeek.bDuck = pSchedule.bDuck
			pPeek.bVertical = pSchedule.bVertical
			return
		end

		if pSchedule.bVertical then
			MyTable.PeekVerticalPose( self, MyTable )

			local vEnemy = pEnemy:GetPos()
			vEnemy:Add( pEnemy:OBBCenter() )
	
			local tr = util.TraceLine {
				start = self:GetShootPos(),
				endpos = vEnemy,
				filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy ),
				mask = MASK_SHOT_HULL
			}

			if !tr.Hit then pSchedule.bAtThem = true end

			if pSchedule.bAtThem then
				if tr.Hit then
					pSchedule.bAtThem = nil
					return
				end

				local flDirectTime = pSchedule.flDirectTime
				if !flDirectTime then
					flDirectTime = CurTime() + math.Rand( 0, 8 )
					pSchedule.flDirectTime = flDirectTime
				end

				local iClip = MyTable.GetWeaponClipPrimary( self, MyTable )
				if iClip != -1 && iClip <= 0 then
					MyTable.WeaponReload( self, MyTable )
					flDirectTime = flDirectTime + MyTable.flWeaponReloadTime - CurTime()
					pSchedule.flDirectTime = flDirectTime
				end
	
				if MyTable.CanAttackHelper( self, vEnemy, MyTable ) then
					MyTable.VolleySuppressingSettings( self, MyTable )
					MyTable.RangeAttack( self, MyTable )
				end
	
				if CurTime() > flDirectTime then
					local pPeek = MyTable.SetSchedule( self, "PeekOut", MyTable )
					pPeek.vPeek = pSchedule.vPeek
					pPeek.bVertical = true
				end

				pSchedule.flSuppressTime = nil
				pSchedule.vSuppress = vEnemy

				MyTable.vaAimTargetPose = vEnemy
				if MyTable.CanAttackHelper( self, pEnemy, MyTable ) then MyTable.RangeAttack( self, MyTable ) end
	
				return
			end

			pSchedule.flDirectTime = nil

			local vSuppress = pSchedule.vSuppress

			local flSuppressTime = pSchedule.flSuppressTime
			if !flSuppressTime then
				flSuppressTime = CurTime() + math.Rand( 0, 8 )
				pSchedule.flSuppressTime = flSuppressTime
			end

			local iClip = MyTable.GetWeaponClipPrimary( self, MyTable )
			if iClip != -1 && iClip <= 0 then
				MyTable.WeaponReload( self, MyTable )
				flSuppressTime = flSuppressTime + MyTable.flWeaponReloadTime - CurTime()
				pSchedule.flSuppressTime = flSuppressTime
			end

			MyTable.vaAimTargetPose = vSuppress
			if MyTable.CanAttackHelper( self, vSuppress, MyTable ) then
				MyTable.VolleySuppressingSettings( self, MyTable )
				MyTable.RangeAttack( self, MyTable )
			end

			if CurTime() > flSuppressTime then
				local pPeek = MyTable.SetSchedule( self, "PeekOut", MyTable )
				pPeek.vPeek = pSchedule.vPeek
				pPeek.bVertical = true
			end

			return
		end

		MyTable.PeekPose( self, MyTable, MyTable.vCover, pSchedule.vPeek, pSchedule.bDuck && 0 || 1 )

		MyTable.vActualTarget = pSchedule.vPeek

		local vEnemy = pEnemy:GetPos()
		vEnemy:Add( pEnemy:OBBCenter() )

		local tr = util.TraceLine {
			start = self:GetShootPos(),
			endpos = vEnemy,
			filter = SimpleRelatedFilterTripleDouble( self, pEnemy, pTrueEnemy ),
			mask = MASK_SHOT_HULL
		}

		if !tr.Hit then pSchedule.bAtThem = true end

		if pSchedule.bAtThem then
			if tr.Hit then
				pSchedule.bAtThem = nil
				return
			end

			local flDirectTime = pSchedule.flDirectTime
			if !flDirectTime then
				flDirectTime = CurTime() + math.Rand( 0, 8 )
				pSchedule.flDirectTime = flDirectTime
			end

			local iClip = MyTable.GetWeaponClipPrimary( self, MyTable )
			if iClip != -1 && iClip <= 0 then
				MyTable.WeaponReload( self, MyTable )
				flDirectTime = flDirectTime + MyTable.flWeaponReloadTime - CurTime()
				pSchedule.flDirectTime = flDirectTime
			end

			if MyTable.CanAttackHelper( self, vEnemy, MyTable ) then
				MyTable.VolleySuppressingSettings( self, MyTable )
				MyTable.RangeAttack( self, MyTable )
			end

			if CurTime() > flDirectTime then
				local pPeek = MyTable.SetSchedule( self, "PeekOut", MyTable )
				pPeek.vPeek = pSchedule.vPeek
				pPeek.bVertical = true
			end

			pSchedule.flSuppressTime = nil
			pSchedule.vSuppress = vEnemy

			MyTable.vaAimTargetPose = vEnemy
			if MyTable.CanAttackHelper( self, pEnemy, MyTable ) then MyTable.RangeAttack( self, MyTable ) end

			return
		end

		pSchedule.flDirectTime = nil

		local vSuppress = pSchedule.vSuppress

		local flSuppressTime = pSchedule.flSuppressTime
		if !flSuppressTime then
			flSuppressTime = CurTime() + math.Rand( 0, 8 )
			pSchedule.flSuppressTime = flSuppressTime
		end

		local iClip = MyTable.GetWeaponClipPrimary( self, MyTable )
		if iClip != -1 && iClip <= 0 then
			MyTable.WeaponReload( self, MyTable )
			flSuppressTime = flSuppressTime + MyTable.flWeaponReloadTime - CurTime()
			pSchedule.flSuppressTime = flSuppressTime
		end

		MyTable.vaAimTargetPose = vSuppress
		if MyTable.CanAttackHelper( self, vSuppress, MyTable ) then
			MyTable.VolleySuppressingSettings( self, MyTable )
			MyTable.RangeAttack( self, MyTable )
		end

		if CurTime() > flSuppressTime then
			local pPeek = MyTable.SetSchedule( self, "PeekOut", MyTable )
			pPeek.vPeek = pSchedule.vPeek
			pPeek.bVertical = true
		end
	end,

	SomeoneIsPeekingMe = function( self, pSchedule, MyTable )
		MyTable.DLG_PeekLeavePreShotAt( self, MyTable )
		local pPeek = MyTable.SetSchedule( self, "PeekOut", MyTable )
		pPeek.vPeek = pSchedule.vPeek
		pPeek.bDuck = pSchedule.bDuck
		pPeek.bVertical = pSchedule.bVertical
	end
} )
