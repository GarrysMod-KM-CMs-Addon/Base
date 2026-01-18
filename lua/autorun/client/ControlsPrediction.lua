local CEntity = FindMetaTable "Entity"
local CEntity_IsOnGround = CEntity.IsOnGround
local CEntity_WaterLevel = CEntity.WaterLevel
local CPlayer_GetRunSpeed = FindMetaTable( "Player" ).GetRunSpeed
local function BloodlossStuff( ply, cmd )
	local flBlood = ply:GetNW2Float( "GAME_flBlood", 1 )
	if flBlood <= .8 then
		cmd:RemoveKey( IN_SPEED )
		ply.CTRL_bSprintBlockUnTilUnPressed = true
		ply.CTRL_bHeldSprint = nil
	end
	if flBlood <= .6 then cmd:AddKey( IN_DUCK ) cmd:AddKey( IN_WALK ) end // Crawling (no proper animation, but that's what I'm trying to simulate)
end
local cWalkNotRun
hook.Add( "StartCommand", "GameImprovements", function( ply, cmd )
	if !ply:Alive() then return end

	local veh = ply.GAME_pVehicle
	if IsValid( veh ) then
		if !ply.GAME_sRestoreGun then
			local w = ply:GetActiveWeapon()
			if IsValid( w ) then ply.GAME_sRestoreGun = w:GetClass() end
		end
		if veh.bDriverHoldingUse then
			if !cmd:KeyDown( IN_USE ) then
				veh.bDriverHoldingUse = nil
			end
		else
			if ply:KeyDown( IN_USE ) && veh:ExitVehicle( ply ) then return end
		end
		veh:PlayerControls( ply, cmd )
		cmd:AddKey( IN_DUCK )
		local p = ply:GetWeapon "Hands"
		// if !IsValid( p ) then p = ply:Give "Hands" end
		if IsValid( p ) then cmd:SelectWeapon( p ) end
		local p = ply:GetWeapon "HandsSwimInternal"
		if IsValid( p ) then p:Remove() end
		return
	end

	local c = ply:GetModel()
	local v = __PLAYER_MODEL__[ c ]
	if v then
		v = v.StartCommand
		if v && v( ply, cmd ) then return end
	end

	BloodlossStuff( ply, cmd )

	ply:SetLadderClimbSpeed( ply:IsSprinting() && ply:GetRunSpeed() || ply:IsWalking() && ply:GetSlowWalkSpeed() || ply:GetWalkSpeed() )

	local bGround = CEntity_IsOnGround( ply )
	if !bGround && CEntity_WaterLevel( ply ) > 0 then
		if !ply.GAME_sRestoreGun then
			local w = ply:GetActiveWeapon()
			if IsValid( w ) then ply.GAME_sRestoreGun = w:GetClass() end
		end
		// local p = ply:GetWeapon "Hands"
		// if IsValid( p ) then p:Remove() end
		local p = ply:GetWeapon "HandsSwimInternal"
		// if !IsValid( p ) then p = ply:Give "HandsSwimInternal" end
		if IsValid( p ) then cmd:SelectWeapon( p ) end
		ply:SetNW2Bool( "CTRL_bSliding", false )
		return
	else
		local p = ply:GetWeapon "Hands"
		if !IsValid( p ) then
			local sRestoreGun = ply.GAME_sRestoreGun
			// p = ply:Give "Hands"
			ply.GAME_sRestoreGun = sRestoreGun
		end
		if IsValid( p ) && !IsValid( ply:GetActiveWeapon() ) then
			local sRestoreGun = ply.GAME_sRestoreGun
			cmd:SelectWeapon( p )
			ply.GAME_sRestoreGun = sRestoreGun
		end
		// local p = ply:GetWeapon "HandsSwimInternal"
		// if IsValid( p ) then p:Remove() end
	end

	local s = ply.GAME_sRestoreGun
	if s then
		local w = ply:GetWeapon( s )
		if IsValid( w ) then cmd:SelectWeapon( w ) end
		ply.GAME_sRestoreGun = nil
	end

	if ply:GetNW2Bool "CTRL_bSliding" then cmd:RemoveKey( IN_ATTACK ) cmd:RemoveKey( IN_ATTACK2 ) end

	if ply.CTRL_bSprintBlockUnTilUnPressed then
		if !cmd:KeyDown( IN_SPEED ) then ply.CTRL_bSprintBlockUnTilUnPressed = nil end
		cmd:RemoveKey( IN_SPEED )
	end

	if !cWalkNotRun then cWalkNotRun = GetConVar "bWalkNotRun" end
	if cmd:KeyDown( IN_ZOOM ) then cmd:AddKey( IN_WALK )
	elseif cWalkNotRun:GetBool() then
		local b = cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 )
		if b then cmd:AddKey( IN_WALK )
		else
			local p = ply:GetActiveWeapon()
			if IsValid( p ) && ( CurTime() <= p:GetNextPrimaryFire() || CurTime() <= p:GetNextSecondaryFire() ) then cmd:AddKey( IN_WALK ) end
		end
	end

	local v = __PLAYER_MODEL__[ ply:GetModel() ]
	local bAllDirectionalSprint = Either( v, v && v.bAllDirectionalSprint, ply.CTRL_bAllDirectionalSprint ) || ( ( Either( ply.CTRL_bCantSlide == nil, __PLAYER_MODEL__[ ply:GetModel() ] && __PLAYER_MODEL__[ ply:GetModel() ].bCantSlide, ply.CTRL_bCantSlide ) && GetVelocity( ply ):Length() >= ply:GetRunSpeed() ) || ply:Crouching() )
	if bAllDirectionalSprint then
		ply:SetNW2Bool( "CTRL_bSprinting", false )
		ply:SetCrouchedWalkSpeed( 1 )
	else
		local bGroundCrouchingAndNotSliding = ply:Crouching() && !ply:GetNW2Bool "CTRL_bSliding"
		if bGroundCrouchingAndNotSliding || cmd:KeyDown( IN_ZOOM ) || !( cmd:KeyDown( IN_FORWARD ) || cmd:KeyDown( IN_BACK ) || cmd:KeyDown( IN_MOVELEFT ) || cmd:KeyDown( IN_MOVERIGHT ) ) then ply.CTRL_bHeldSprint = nil cmd:RemoveKey( IN_SPEED ) end
		if !bGroundCrouchingAndNotSliding && cmd:KeyDown( IN_SPEED ) || ply.CTRL_bHeldSprint then
			ply.CTRL_bHeldSprint = true
			cmd:AddKey( IN_SPEED )
			local p = ply:GetActiveWeapon()
			if cmd:GetForwardMove() <= 0 || IsValid( p ) && ( CurTime() <= p:GetNextPrimaryFire() || CurTime() <= p:GetNextSecondaryFire() ) then
				// ply.CTRL_bSprintBlockUnTilUnPressed = true
				if bGround then ply.CTRL_bHeldSprint = nil end
				cmd:RemoveKey( IN_SPEED )
				ply:SetNW2Bool( "CTRL_bSprinting", false )
			else
				cmd:SetForwardMove( CPlayer_GetRunSpeed( ply ) )
				cmd:SetSideMove( math.Clamp( cmd:GetSideMove(), -cmd:GetForwardMove(), cmd:GetForwardMove() ) )
				local b = ply:GetVelocity():Length() > ply:GetWalkSpeed()
				ply:SetNW2Bool( "CTRL_bSprinting", b )
				if b then
					if cmd:KeyDown( IN_ATTACK ) || cmd:KeyDown( IN_ATTACK2 ) || cmd:KeyDown( IN_ZOOM ) then
						ply.CTRL_bSprintBlockUnTilUnPressed = true
						ply.CTRL_bHeldSprint = nil
						cmd:RemoveKey( IN_SPEED )
						ply:SetNW2Bool( "CTRL_bSprinting", false )
					end
				end
			end
		else
			ply:SetNW2Bool( "CTRL_bSprinting", false )
		end
	end
	BloodlossStuff( ply, cmd ) // Run it twice so that we neutralize RemoveKey( IN_DUCK )
end )
