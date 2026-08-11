// This whole file is a TODO!

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

local __SCHEDULE__ = __SCHEDULE__

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

		MyTable.tActualCover = MyTable.vCover

		local tCover = MyTable.tCover

		local dBodyTarget = ( tCover.vEnd - tCover.vStart ):Angle():Right()
		if !tCover.bRight then dBodyTarget:Negate() end
		MyTable.vaAimTargetBody = dBodyTarget:Angle()

		if pSchedule.bAtThem then
			local v = pEnemy:GetPos()
			v:Add( pEnemy:OBBCenter() )
			MyTable.vaAimTargetPose = v
		else
		end

		if pSchedule.bUnDuckPeek then
			return
		end
	end
} )

RegisterSchedule( "PeekOut", {
	Execute = function( self, pSchedule, MyTable )
		MyTable.tActualCover = MyTable.vCover
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
function ENT:DLG_PeekLeaveSomeoneIsPeekingMe() end

RegisterSchedule( "Peek", {
	Execute = function( self, pSchedule, MyTable )
		local pEnemy = MyTable.Enemy
		if !IsValid( pEnemy ) then return true end
		local pEnemy, pTrueEnemy = MyTable.SetupEnemy( self, pEnemy, MyTable )

		MyTable.tActualCover = MyTable.vCover
	end,

	SomeoneIsPeekingMe = function( self, pSchedule, MyTable )
		MyTable.DLG_PeekLeaveSomeoneIsPeekingMe( self, MyTable )
		MyTable.SetSchedule( self, "PeekOut", MyTable )
	end
} )
