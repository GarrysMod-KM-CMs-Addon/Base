// Lots of code is taken from Buu342's Weapon Base 2
// You can find it here: https://github.com/buu342/GMod-BuuBaseRedone
// I would've just took the code because it's the best way to do it,
// and because he took the general idea and some assets from Far Cry 3,
// but his base really helped me, and I should've wrote this credit sooner.
//
// Thank you, Buu.

function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = ""

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""

SWEP.UseHands = true

SWEP.__WEAPON__ = true

if CLIENT then
	SWEP.flCrosshairAlpha = 255
	SWEP.flCurrentRecoil = 0
	function SWEP:AddRecoil( flRecoil )
		self.flCurrentRecoil = self.flCurrentRecoil + flRecoil
		if self.flAimShoot then self.flBarrelBack = ( self.flBarrelBack || 0 ) + flRecoil end
	end
	SWEP.flReloadTime = 0
	function SWEP:ReloadTime( f ) self.flReloadTime = CurTime() + f end
end

function SWEP:Reload()
	local pReloadOwner = self:GetOwner()
	local f = self:Clip1()
	if SERVER && f >= self:GetMaxClip1() && pReloadOwner:IsPlayer() then Achievement_Miscellaneous( pReloadOwner, "WeaponReloadFull" ) end
	self:SetClip1( 0 )
	if self:DefaultReload( ACT_VM_RELOAD ) then
		if !pReloadOwner:IsPlayer() then return end
		f = pReloadOwner:GetViewModel()
		f = f:SequenceDuration( f:SelectWeightedSequence( ACT_VM_RELOAD ) )
		self:CallOnClient( "ReloadTime", f )
	else self:SetClip1( f ) end
end

function SWEP:AllowsAutoSwitchFrom() return false end
function SWEP:AllowsAutoSwitchTo() return false end

SWEP.sDryFire = "Weapon_Pistol.Empty"

local CEntity = FindMetaTable "Entity"
local CEntity_GetOwner = CEntity.GetOwner
SWEP.bDisAllowPrimaryInCover = true
function SWEP:CanPrimaryAttack( MyTable, bIgnoreAmmo )
	// Believe it or not, some people (including VALVe!) have the AUDACITY to ignore this check!
	if CurTime() <= self:GetNextPrimaryFire() then return end
	local owner = CEntity_GetOwner( self )
	if owner:GetNW2Bool "CTRL_bPredictedCantShoot" || owner:GetNW2Bool "CTRL_bSliding" || owner:GetNW2Bool "CTRL_bInCover" then return end
	if CurTime() <= ( owner.CTRL_flCoverDontShootTime || 0 ) then return end
	if self.bDisAllowPrimaryInCover then
		if IsValid( owner ) && owner.CTRL_bInCover then return end
	end
	if !bIgnoreAmmo && self:Clip1() <= 0 then
		local sDryFire = self.sDryFire
		if sDryFire != "" then self:EmitSound( sDryFire ) end
		self:SetNextPrimaryFire( CurTime() + .2 )
		return
	end
	return true
end

function SWEP:TakeAmmo( sAmmo, flAmount )
	local pOwner = self:GetOwner()
	if !IsValid( pOwner ) then return end
	local f = pOwner.GetAmmoCount
	flAmount = flAmount || 1
	if f && f( pOwner, sAmmo ) < flAmount then return end
	local f = pOwner.RemoveAmmo
	if f then f( pOwner, flAmount, sAmmo ) end
	return true
end

function SWEP:GetNPCBulletSpread() return 0 end
function SWEP:GetNPCBurstSettings() return 0, self:Clip1(), self.Primary.Automatic && 0 || math.Rand( .2, .8 ) end

function SWEP:Deploy() self:BaseWeaponDraw( self.flDrawActivity || ACT_VM_DRAW ) end

function SWEP:BaseWeaponDraw( act )
	local owner = self:GetOwner()
	if !IsValid( owner ) || !owner.GetViewModel then return end
	local vm = self:GetOwner():GetViewModel()
	local s = vm:SelectWeightedSequence( act )
	vm:SendViewModelMatchingSequence( s )
	local t = CurTime() + vm:SequenceDuration( s )
	if t > self:GetNextPrimaryFire() then self:SetNextPrimaryFire( t ) end
	if t > self:GetNextSecondaryFire() then self:SetNextSecondaryFire( t ) end
end

local CPlayer = FindMetaTable "Player"
local CPlayer_KeyDown = CPlayer.KeyDown
local CPlayer_GetRunSpeed = CPlayer.GetRunSpeed
local CEntity_GetVelocity = CEntity.GetVelocity
local CEntity_IsOnGround = CEntity.IsOnGround
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
local CEntity_GetTable = CEntity.GetTable

function SWEP:GetAimVector()
	local pOwner = self:GetOwner()
	if !IsValid( pOwner ) then return self:GetForward() end
	local v = pOwner:GetAimVector()
	local f = pOwner.GetViewPunchAngles
	if f then
		v = v:Angle()
		v = v + f( pOwner )
		v = v:Forward()
	end
	return v
end

SWEP.flRecoil = 2 // With the data below, this is degrees
SWEP.flSideWaysRecoilMin = -.33
SWEP.flSideWaysRecoilMax = .33
SWEP.flRecoilGrowMin = -.5
SWEP.flRecoilGrowMax = -1
DEFINE_BASECLASS "weapon_base"
local util_SharedRandom = util.SharedRandom
function SWEP:CalcRecoil( pOwner )
	local flRecoil = self.flRecoil * math.Clamp( 1 + pOwner:GetVelocity():Length() / ( pOwner:GetRunSpeed() * 1.5 ), 1, 1.5 )
	if !pOwner:KeyDown( IN_ZOOM ) then flRecoil = flRecoil * 1.5 end
	if !pOwner:IsOnGround() then flRecoil = flRecoil * 1.5 end
	return flRecoil
end
function SWEP:DoRecoil()
	local pOwner = self:GetOwner()
	if IsValid( pOwner ) && pOwner.ViewPunch && pOwner.GetRunSpeed then
		local flRecoil = self:CalcRecoil( pOwner )
		self:CallOnClient( "AddRecoil", flRecoil )
		pOwner:ViewPunch( Angle( util_SharedRandom( "BaseWeapon_ViewPunch", self.flRecoilGrowMin, self.flRecoilGrowMax ) * flRecoil, util_SharedRandom( "BaseWeapon_ViewPunch", self.flSideWaysRecoilMin, self.flSideWaysRecoilMax ) * flRecoil, 0 ) * ( pOwner.GetNW2Float && pOwner:GetNW2Float( "GAME_flRecoil", 1 ) || 1 ) )
	end
end
function SWEP:ShootEffects()
	self:DoRecoil()
	local pOwner = self:GetOwner()
	if !( pOwner:IsPlayer() && pOwner:KeyDown( IN_ZOOM ) ) || !self.flAimShoot then
		self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	end
	self:GetOwner():SetAnimation( PLAYER_ATTACK1 )
end

local math = math
local math_min = math.min

AddCSLuaFile "Crosshair.lua"

if CLIENT then
	function SWEP:Think()
		local pViewModel = self:GetOwner():GetViewModel()
		pViewModel:SetColor( self:GetColor() )
	end
	local Vector = Vector
	local vFinal = Vector( 0, 0, 0 )
	local vFinalAngle = Vector( 0, 0, 0 )
	local vTarget = Vector( 0, 0, 0 )
	local vTargetAngle = Vector( 0, 0, 0 )
	local vViewFinal = Vector( 0, 0, 0 )
	local vViewFinalAngle = Vector( 0, 0, 0 )
	local vBezier = Vector( 0, 0, 0 )
	local vBezierAngle = Vector( 0, 0, 0 )
	local bBezierAllowOff
	local aAim, aViewAim = Angle( 0, 0, 0 ), Angle( 0, 0, 0 )
	local vInstantTarget, vInstantTargetAngle = Vector( 0, 0, 0 ), Vector( 0, 0, 0 )
	local vFinalRatherQuick, vFinalRatherQuickAngle = Vector( 0, 0, 0 ), Vector( 0, 0, 0 )
	local vTargetRatherQuick, vTargetRatherQuickAngle = Vector( 0, 0, 0 ), Vector( 0, 0, 0 )
	local vViewFinalRatherQuick, vViewFinalRatherQuickAngle = Vector( 0, 0, 0 ), Vector( 0, 0, 0 )
	local vViewTargetRatherQuick, vViewTargetRatherQuickAngle = Vector( 0, 0, 0 ), Vector( 0, 0, 0 )
	local flLandTime, flJumpTime = 0, 0
	SWEP.ViewModelFOV = 62
	SWEP.flViewModelX = 0
	SWEP.flViewModelY = 0
	SWEP.flViewModelZ = 0
	SWEP.vViewModelAim = false
	SWEP.vViewModelAimAngle = false
	SWEP.flSwayScale = 60
	SWEP.flSwayAngle = 4
	SWEP.flSwayVector = SWEP.flSwayAngle * .415
	SWEP.SwayScale = 0
	SWEP.BobScale = 0
	SWEP.vSprintArm = Vector( 1.358, 1.228, -.94 )
	SWEP.vSprintArmAngle = Vector( -10.554, 34.167, -20 )
	SWEP.vPistolSprint = Vector( 0, -10, -10 )
	SWEP.vPistolSprintAngle = Vector( 45, 0, 0 )
	SWEP.flAimMultiplier = 1
	SWEP.flFoV = UNIVERSAL_FOV
	SWEP.flLastEyeYaw = 0
	SWEP.flBobScale = 1
	SWEP.flAimRoll = 45
	SNIPER_AIMING_MULTIPLIER = .5
	SNIPER_AIMING_SWAY_MULTIPLIER = .5
	local math_cos = math.cos
	local math_sin = math.sin
	local math_Clamp = math.Clamp
	local math_AngleDifference = math.AngleDifference
	local math_NormalizeAngle = math.NormalizeAngle
	local CEntity_WaterLevel = CEntity.WaterLevel
	local CPlayer_GetWalkSpeed = CPlayer.GetWalkSpeed
	local CPlayer_InVehicle = CPlayer.InVehicle
	local bOnGroundLast
	local math_Remap = math.Remap
	function SWEP:AdjustMouseSensitivity() local v = CEntity_GetTable( self ).flFoV if v then return v / LocalPlayer():GetInfoNum( "fov_desired", UNIVERSAL_FOV ) end end
	local CPlayer_IsSprinting = CPlayer.IsSprinting
	local CPlayer_Crouching = CPlayer.Crouching
	local CEntity_GetNW2Int = CEntity.GetNW2Int
	local function BezierY( f, a, b, c )
		f = f * 3.2258
		return ( 1 - f ) ^ 2 * a + 2 * ( 1 - f ) * f * b + ( f ^ 2 ) * c
	end
	local SLIDE_ANGLE = -45
	local util_TraceLine = util.TraceLine
	function SWEP:CalcView( ply, pos, ang )
		local MyTable = CEntity_GetTable( self )
		vTarget, vTargetAngle = Vector( 0, 0, 0 ), Vector( 0, 0, 0 )
		vViewTargetRatherQuick, vViewTargetRatherQuickAngle = Vector( 0, 0, 0 ), Vector( 0, 0, 0 )
		if CEntity_IsOnGround( ply ) then
			if CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) then
				vTargetAngle[ 1 ] = math_AngleDifference( ang[ 1 ], SLIDE_ANGLE )
			elseif CEntity_GetNW2Bool( ply, "CTRL_bSprinting" ) then
				local flVelocity = CEntity_GetVelocity( ply ):Length()
				if flVelocity > 10 then
					local f = flVelocity / CPlayer_GetRunSpeed( ply ) * ( MyTable.flBobScale * 4 )
					local flBreathe = RealTime() * 18
					local v = Vector( ( -math_cos( flBreathe * .5 ) / 5 ) * f, 0, 0 )
					vTarget = vTarget - v
					local v = Vector( ( math_Clamp( math_cos( flBreathe ), -.3, .3 ) * 1.2 ) * f, ( -math_cos( flBreathe * .5 ) * 1.2 ) * f, 0 )
					vTargetAngle = vTargetAngle - v
				end
			else
				local flVelocity = CEntity_GetVelocity( ply ):Length()
				if flVelocity > 10 then
					local flBreathe = RealTime() * 16
					local f = flVelocity / CPlayer_GetWalkSpeed( ply ) * MyTable.flAimMultiplier * ( MyTable.flBobScale * 4 )
					vTargetAngle = vTargetAngle + Vector( ( math_Clamp( math_cos( flBreathe ), -.3, .3 ) * 1.2 ) * f, 0 )
				end
			end
		end
		local p = CEntity_GetNW2Int( ply, "CTRL_Peek" )
		if p == COVER_FIRE_LEFT then
			vTargetAngle.z = vTargetAngle.z - 11.25
		elseif p == COVER_FIRE_RIGHT then
			vTargetAngle.z = vTargetAngle.z + 11.25
		elseif p == COVER_BLINDFIRE_LEFT then
			vTargetAngle.z = vTargetAngle.z - 22.5
		elseif p == COVER_BLINDFIRE_RIGHT then
			vTargetAngle.z = vTargetAngle.z + 22.5
		end
		vViewTargetRatherQuick = vViewTargetRatherQuick + vBezier
		vViewTargetRatherQuickAngle = vViewTargetRatherQuickAngle + vBezierAngle
		if bBezierAllowOff && ( CurTime() <= self:GetNextPrimaryFire() + .1 || CPlayer_KeyDown( ply, IN_ZOOM ) ) then
			vTarget = vTarget - vBezier
			vTargetAngle = vTargetAngle - vBezierAngle
		end
		vViewFinal = LerpVector( math_min( 1, 5 * FrameTime() ), vViewFinal, vTarget )
		vViewFinalAngle = LerpVector( math_min( 1, 5 * FrameTime() ), vViewFinalAngle, vTargetAngle )
		ang:RotateAroundAxis( ang:Right(), vViewFinalAngle.x )
		ang:RotateAroundAxis( ang:Up(), vViewFinalAngle.y )
		ang:RotateAroundAxis( ang:Forward(), vViewFinalAngle.z )
		pos = pos + vViewFinal.z * ang:Up()
		pos = pos + vViewFinal.y * ang:Forward()
		pos = pos + vViewFinal.x * ang:Right()
		vViewFinalRatherQuick = LerpVector( math_min( 1, 20 * FrameTime() ), vViewFinalRatherQuick, vViewTargetRatherQuick )
		vViewFinalRatherQuickAngle = LerpVector( math_min( 1, 20 * FrameTime() ), vViewFinalRatherQuickAngle, vViewTargetRatherQuickAngle )
		ang:RotateAroundAxis( ang:Right(), vViewFinalRatherQuickAngle.x )
		ang:RotateAroundAxis( ang:Up(), vViewFinalRatherQuickAngle.y )
		ang:RotateAroundAxis( ang:Forward(), vViewFinalRatherQuickAngle.z )
		pos = pos + vViewFinalRatherQuick.z * ang:Up()
		pos = pos + vViewFinalRatherQuick.y * ang:Forward()
		pos = pos + vViewFinalRatherQuick.x * ang:Right()
		MyTable.aLastViewEyePosition = aViewAim - ply:EyeAngles()
		local flMultiplier = MyTable.flAimMultiplier || 0
		if MyTable.bSniper && flMultiplier <= ( MyTable.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) then flMultiplier = ( MyTable.flSniperAimingSwayMultiplier || SNIPER_AIMING_SWAY_MULTIPLIER ) end
		local flSwayAngle = MyTable.flSwayAngle * flMultiplier
		local flSwayAngleNeg = -flSwayAngle
		local eye = ply:EyeAngles()
		MyTable.flLastEyeYaw = Lerp( math_min( 1, 5 * FrameTime() ), math_Clamp( MyTable.flLastEyeYaw + math_AngleDifference( eye[ 2 ], ( MyTable.flLastTrueEyeYaw || eye[ 2 ] ) ), -MyTable.flSwayScale, MyTable.flSwayScale ), 0 )
		MyTable.flLastTrueEyeYaw = eye[ 2 ]
		MyTable.aLastViewEyePosition[ 2 ] = -MyTable.flLastEyeYaw
		ang:RotateAroundAxis( ang:Right(), -math_Clamp( flSwayAngle * MyTable.aLastViewEyePosition.p / MyTable.flSwayScale, flSwayAngleNeg, flSwayAngle ) )
		ang:RotateAroundAxis( ang:Up(), -math_Clamp( flSwayAngleNeg * MyTable.aLastViewEyePosition.y / MyTable.flSwayScale, flSwayAngleNeg, flSwayAngle ) )
		local flSwayVector = MyTable.flSwayVector * flMultiplier
		local flSwayVectorNeg = -flSwayVector
		pos = pos - math_Clamp( ( flSwayVectorNeg * MyTable.aLastViewEyePosition.p / MyTable.flSwayScale ), flSwayVectorNeg, flSwayVector ) * ang:Up()
		pos = pos - math_Clamp( ( flSwayVectorNeg * MyTable.aLastViewEyePosition.y / MyTable.flSwayScale ), flSwayVectorNeg, flSwayVector ) * ang:Right()
		local v = MyTable.flCustomZoomFoV
		if v then
			if MyTable.bSniper then
				local b = MyTable.flAimMultiplier <= ( MyTable.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER )
				local f = b && v || ply:GetInfoNum( "fov_desired", UNIVERSAL_FOV )
				MyTable.flFoV = f
				if b then ang = ang - ply:GetViewPunchAngles() * .5 end
				return pos, ang, f
			else
				local f = math_Remap( MyTable.flAimMultiplier, 1, 0, ply:GetInfoNum( "fov_desired", UNIVERSAL_FOV ), v )
				MyTable.flFoV = f
				return pos, ang, f
			end
		else MyTable.flFoV = ply:GetInfoNum( "fov_desired", UNIVERSAL_FOV ) end
		return pos, ang, ply:GetInfoNum( "fov_desired", UNIVERSAL_FOV )
	end
	local util_TraceLine = util.TraceLine
	function SWEP:GatherCrosshairPosition( MyTable )
		local v = LocalPlayer():GetNW2Entity "GAME_pVehicle"
		local tr = util_TraceLine {
			start = LocalPlayer():GetShootPos(),
			endpos = LocalPlayer():GetShootPos() + self:GetAimVector() * 999999,
			mask = MASK_SOLID,
			filter = IsValid( v ) && { LocalPlayer(), v } || LocalPlayer()
		}
		local t = tr.HitPos:ToScreen()
		return t.x, t.y
	end
	SWEP.flAimTiltTime = 0
	SWEP.flAimLastEyeYaw = 0
	SWEP.flViewModelSprint = 0
	SWEP.vBlindFireLeft = Vector( -8, 0, 2 )
	SWEP.vBlindFireLeftAngle = Vector( 0, 0, -22.5 )
	SWEP.vBlindFireRight = Vector( 2, 0, 1 )
	SWEP.vBlindFireRightAngle = Vector( 0, 0, 22.5 )
	SWEP.vBlindFireUp = Vector( 3, 0, 0 )
	SWEP.vBlindFireUpAngle = Vector( 0, 0, -110 )
	function SWEP:CalcViewModelView( _, pos, ang )
		local MyTable = CEntity_GetTable( self )
		local ply = LocalPlayer()
		local f = math_Clamp( ply:Health() / ply:GetMaxHealth(), 0, 1 )
		vBezier, vBezierAngle = Vector( 0, 0, 0 ), Vector( 0, 0, 0 )
		vTargetRatherQuick, vTargetRatherQuickAngle = Vector( 0, 0, 0 ), Vector( 0, 0, 0 )
		MyTable.flBobScale = math.Remap( f, 0, 1, 2, 1 )
		local bSprinting = CEntity_GetNW2Bool( ply, "CTRL_bSprinting" )
		local bSliding = CEntity_GetNW2Bool( ply, "CTRL_bSliding" )
		local bInCover = CEntity_GetNW2Bool( ply, "CTRL_bInCover" ) && !CEntity_GetNW2Bool( ply, "CTRL_bGunUsesCoverStance" )
		local bZoom = !bSprinting && !bSliding && !bInCover && CEntity_IsOnGround( ply ) && CPlayer_KeyDown( ply, IN_ZOOM )
		bBezierAllowOff = nil
		local flBreathe = RealTime() * 5
		local vAim
		if bZoom then vAim = MyTable.vViewModelAim end
		if bZoom && vAim then
			vTarget = Vector( vAim )
			local vAimAngle = MyTable.vViewModelAimAngle
			vTargetAngle = vAimAngle && Vector( vAimAngle ) || Vector( 0, 0, 0 )
		else
			vTarget = Vector( math_cos( flBreathe * .5 ) * .0625, 0, ( math_sin( flBreathe / 3 ) * .0625 ) )
			vTargetAngle = Vector( ( math_sin( flBreathe / 3 ) * .25 ), math_cos( flBreathe * .5 ) * .25 )
		end
		vInstantTarget, vInstantTargetAngle = Vector( 0, 0, 0 ), Vector( 0, 0, 0 )
		if IsValid( ply:GetNW2Entity "GAME_pVehicle" ) then vInstantTarget = vInstantTarget - Vector( 0, 0, 999999 ) end
		if MyTable.flAimShoot then
			local f = ( MyTable.flInAimShoot || 0 ) * ( MyTable.flBarrelBack || 0 ) * MyTable.flAimShoot
			if ( MyTable.flBarrelBackCurrent || 0 ) > f then
				MyTable.flBarrelBackCurrent = f
			else
				f = Lerp( math_min( 1, 15 * FrameTime() ), MyTable.flBarrelBackCurrent || 0, f )
				MyTable.flBarrelBackCurrent = f
			end
			MyTable.flBarrelBackCurrent = f
			vInstantTarget[ 2 ] = vInstantTarget[ 2 ] - f
			MyTable.flInAimShoot = Lerp( math_min( 1, 10 * FrameTime() ), MyTable.flInAimShoot || 0, bZoom && 1 || 0 )
		end
		if MyTable.flBarrelBack then MyTable.flBarrelBack = Lerp( math_min( 1, 10 * FrameTime() ), MyTable.flBarrelBack, 0 ) end
		local flSprint = MyTable.flViewModelSprint
		local f = math_min( .5, CEntity_GetVelocity( ply ):Length() / CPlayer_GetRunSpeed( ply ) * .5 ) * MyTable.flBobScale
		local flBreathe = RealTime() * 18
		if MyTable.bPistolSprint then
			vInstantTarget = vInstantTarget + ( MyTable.vPistolSprint - Vector( math_cos( flBreathe * .5 ) * f, -math_cos( flBreathe ) * f, 0 ) ) * flSprint
			vInstantTargetAngle = vInstantTargetAngle + ( MyTable.vPistolSprintAngle - Vector( math_cos( flBreathe * .5 ) * f, 0, 0 ) ) * flSprint
		else
			vInstantTarget = vInstantTarget + ( MyTable.vSprintArm - Vector( ( ( math_cos( flBreathe * .5 ) + 1 ) * 1.25 ) * f, 0, math_cos( flBreathe ) * f ) ) * flSprint
			vInstantTargetAngle = vInstantTargetAngle + ( MyTable.vSprintArmAngle - Vector( ( ( math_cos( flBreathe * .5 ) + 1 ) * -2.5 ) * f, ( ( math_cos( flBreathe * .5 ) + 1 ) * 7.5 ) * f, 0 ) ) * flSprint
		end
		vInstantTarget = vInstantTarget - Vector( MyTable.flViewModelY, 0, MyTable.flViewModelZ ) * flSprint
		vTarget = vTarget + Vector( MyTable.flViewModelY, MyTable.flViewModelX, MyTable.flViewModelZ )
		if !MyTable.bCoverNotAnimated && bInCover then
			MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * FrameTime() ), flSprint, 0 )
			if MyTable.__VIEWMODEL_FULLY_MODELED__ then
				local f = CEntity_GetNW2Int( ply, "CTRL_Variants" )
				if f == COVER_VARIANTS_RIGHT then
					vTargetAngle.x = vTargetAngle.x + 45
					vTarget.z = vTarget.z - 10 - MyTable.flViewModelZ
					vTarget.y = vTarget.y - 10 - MyTable.flViewModelX
					vTarget.x = vTarget.x - 10 - MyTable.flViewModelY
				elseif f == COVER_VARIANTS_LEFT then
					vTargetAngle.x = vTargetAngle.x + 45
					vTarget.z = vTarget.z - 10 - MyTable.flViewModelZ
					vTarget.y = vTarget.y - 10 - MyTable.flViewModelX
					vTarget.x = vTarget.x + ( MyTable.flCoverLeftX || -3.5 ) - MyTable.flViewModelY
				else
					vTargetAngle.x = vTargetAngle.x + 45
					vTarget.x = vTarget.x + ( MyTable.vViewModelAim && MyTable.vViewModelAim[ 1 ] || 2 )
					vTarget.y = vTarget.y - 10 - MyTable.flViewModelX
					vTarget.z = vTarget.z - 10 - MyTable.flViewModelZ
				end
			else
				vTargetAngle.x = vTargetAngle.x + 45
				vTarget.x = vTarget.x + ( MyTable.vViewModelAim && ( MyTable.vViewModelAim[ 1 ] * .5 ) || 2 )
				vTarget.y = vTarget.y - 10 - MyTable.flViewModelX + ( MyTable.flCoverY || 0 )
				vTarget.z = vTarget.z - 10 - MyTable.flViewModelZ
			end
		else
			local p = CEntity_GetNW2Int( ply, "CTRL_Peek" )
			if p == COVER_FIRE_LEFT then
				vTargetAngle.z = vTargetAngle.z - 22.5
			elseif p == COVER_FIRE_RIGHT then
				vTargetAngle.z = vTargetAngle.z + 22.5
			elseif MyTable.__VIEWMODEL_FULLY_MODELED__ then
				if p == COVER_BLINDFIRE_UP then
					vTarget = vTarget + ( MyTable.vBlindFireUp || vector_origin )
					vTargetAngle = vTargetAngle + ( MyTable.vBlindFireUpAngle || vector_origin )
				elseif p == COVER_BLINDFIRE_LEFT then
					vTarget = vTarget + ( MyTable.vBlindFireLeft || vector_origin )
					vTargetAngle = vTargetAngle + ( MyTable.vBlindFireLeftAngle || vector_origin )
				elseif p == COVER_BLINDFIRE_RIGHT then
					vTarget = vTarget + ( MyTable.vBlindFireRight || vector_origin )
					vTargetAngle = vTargetAngle + ( MyTable.vBlindFireRightAngle || vector_origin )
				end
			elseif p == COVER_BLINDFIRE_LEFT then
				vTargetAngle.z = vTargetAngle.z - 45
			elseif p == COVER_BLINDFIRE_RIGHT then
				vTargetAngle.z = vTargetAngle.z + 45
			end
			local bOnGround = CEntity_IsOnGround( ply )
			if IsValid( ply:GetNW2Entity "GAME_pVehicle" ) then
				MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * FrameTime() ), flSprint, 0 )
				bOnGroundLast = true
			elseif bOnGround then
				bOnGroundLast = true
				if !bSliding && bSprinting && !MyTable.bSprintNotAnimated then
					MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * FrameTime() ), flSprint, 1 )
				else
					if CPlayer_Crouching( ply ) && !bZoom then vTarget = vTarget + Vector( -1, -1, .5 ) end
					MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * FrameTime() ), flSprint, 0 )
					local flVelocity = CEntity_GetVelocity( ply ):Length()
					if !bZoom then
						if CPlayer_KeyDown( ply, IN_MOVELEFT ) then
							vTargetAngle[ 2 ] = vTargetAngle[ 2 ] - 4 * flVelocity / CPlayer_GetWalkSpeed( ply )
						elseif CPlayer_KeyDown( ply, IN_MOVERIGHT ) then
							vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + 7 * flVelocity / CPlayer_GetWalkSpeed( ply )
						end
					end
					if flVelocity > 10 then
						local flBreathe = RealTime() * 16
						local f = flVelocity / CPlayer_GetWalkSpeed( ply ) * MyTable.flAimMultiplier * MyTable.flBobScale
						vTarget = vTarget - Vector( ( -math_cos( flBreathe * .5 ) / 5 ) * f, 0, 0 )
						vTargetAngle = vTargetAngle - Vector( ( math_Clamp( math_cos( flBreathe ), -.3, .3 ) * 1.2 ) * f, ( -math_cos( flBreathe * .5 ) * 1.2 ) * f, 0 )
					end
				end
			else
				MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * FrameTime() ), flSprint, 0 )
				flLandTime = RealTime() + .31
				if bOnGroundLast then
					flJumpTime = RealTime() + .31
					flLandTime = 0
					bOnGroundLast = nil
				end
			end
			if CEntity_WaterLevel( ply ) < 1 then
				if RealTime() <= flJumpTime then
					local f = .31 - ( flJumpTime - RealTime() )
					local xx = BezierY( f, 0, -4, 0 )
					local yy = 0
					local zz = BezierY( f, 0, -2, -5 )
					local pt = BezierY( f, 0, -4.36, 10 )
					local yw = xx
					local rl = BezierY( f, 0, -10.82, -5 )
					vBezier = Vector( xx, yy, zz )
					vBezierAngle = Vector( pt, yw )
					if !MyTable.bJumpingNotAnimated && CurTime() > self:GetNextPrimaryFire() + .1 && !CPlayer_KeyDown( ply, IN_ZOOM ) then
						vTargetRatherQuick = vTargetRatherQuick + vBezier * 2
						vTargetRatherQuickAngle = vTargetRatherQuickAngle + vBezierAngle + Vector( pt, yw, rl )
					else vTargetRatherQuick = vTargetRatherQuick + vBezier vTargetRatherQuickAngle = vTargetRatherQuickAngle + vBezierAngle end
				elseif !bOnGround then
					bBezierAllowOff = true
					local flBreathe = RealTime() * 30
					vBezier = Vector( math_cos( flBreathe * .5 ) * .0625, 0, -5 + ( math_sin( flBreathe / 3 ) * .0625 ) )
					vBezierAngle = Vector( 10 - ( math_sin( flBreathe / 3 ) * .25 ), math_cos( flBreathe * .5 ) * .25 )
					if !MyTable.bJumpingNotAnimated && CurTime() > self:GetNextPrimaryFire() + .1 && !CPlayer_KeyDown( ply, IN_ZOOM ) then
						vTargetRatherQuick = vTargetRatherQuick + vBezier * 2
						vTargetRatherQuickAngle = vTargetRatherQuickAngle + vBezierAngle + Vector( 10 - ( math_sin( flBreathe / 3 ) * .25 ), math_cos( flBreathe * .5 ) * .25, -5 )
					end
				elseif RealTime() <= flLandTime then
					local f = flLandTime - RealTime()
					local xx = BezierY( f, 0, -4, 0 )
					local yy = 0
					local zz = BezierY( f, 0, -2, -5 )
					local pt = BezierY( f, 0, -4.36, 10 )
					local yw = xx
					local rl = BezierY( f, 0, -10.82, -5 )
					vBezier = Vector( xx, yy, zz )
					vBezierAngle = Vector( pt, yw )
					if !MyTable.bJumpingNotAnimated && CurTime() > self:GetNextPrimaryFire() + .1 && !CPlayer_KeyDown( ply, IN_ZOOM ) then
						vTargetRatherQuick = vTargetRatherQuick + vBezier * 2
						vTargetRatherQuickAngle = vTargetRatherQuickAngle + vBezierAngle + Vector( pt, yw, rl )
					else vTargetRatherQuick = vTargetRatherQuick + vBezier vTargetRatherQuickAngle = vTargetRatherQuickAngle + vBezierAngle end
				end
			end
		end
		local flRecoil, f = MyTable.CalcRecoil( self, ply )
		if MyTable.Primary.Automatic then
			f = flRecoil * ( .75 / MyTable.Primary_flDelay )
			MyTable.flCurrentRecoil = math.max( 0, MyTable.flCurrentRecoil - f * FrameTime() )
		else
			f = flRecoil * ( .75 / ( MyTable.Primary_flDelay + .1 ) )
			MyTable.flCurrentRecoil = math.max( 0, MyTable.flCurrentRecoil - f * FrameTime() )
		end
		f = f + flRecoil / MyTable.flRecoilMultiplierThingy
		if MyTable.flCurrentRecoil > f then MyTable.flCurrentRecoil = f end
		local flRoll = MyTable.flAimRoll
		local flAimTiltTime = MyTable.flAimTiltTime
		flAimTiltTime = Lerp( math_min( 1, 10 * FrameTime() ), flAimTiltTime, bZoom && flRoll || 0 )
		local flTime = ( -( flAimTiltTime - ( flRoll * .5 ) ) ^ 2 + ( flRoll * .5 ) ^ 2 ) / ( flRoll * .5 )
		MyTable.flAimTiltTime = flAimTiltTime
		vTargetAngle = vTargetAngle + ( bZoom && Vector( -flTime / ( flRoll / 3 ), 0, -flTime ) || Vector( 3 * flTime / flRoll, 0, flTime ) )
		if MyTable.aLastEyePosition == nil then MyTable.aLastEyePosition = Angle( 0, 0, 0 ) end
		local eye = ply:EyeAngles()
		MyTable.aLastEyePosition[ 1 ] = math_AngleDifference( aAim[ 1 ], eye[ 1 ] )
		MyTable.aLastEyePosition[ 3 ] = math_AngleDifference( aAim[ 3 ], eye[ 3 ] )
		aAim = LerpAngle( math_min( 1, 5 * FrameTime() ), aAim, eye )
		local flMultiplier
		if bZoom then flMultiplier = Lerp( math_min( 1, 5 * FrameTime() ), MyTable.flAimMultiplier, 0 )
		else flMultiplier = Lerp( math_min( 1, 5 * FrameTime() ), MyTable.flAimMultiplier, 1 ) end
		MyTable.flAimMultiplier = flMultiplier
		if MyTable.bSniper && flMultiplier <= ( MyTable.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) then
			vInstantTarget = Vector( 0, 0, 999999 )
			flMultiplier = ( MyTable.flSniperAimingSwayMultiplier || SNIPER_AIMING_SWAY_MULTIPLIER )
		end
		MyTable.flLastEyeYaw = Lerp( math_min( 1, 5 * FrameTime() ), math_Clamp( MyTable.flLastEyeYaw + math_AngleDifference( eye[ 2 ], ( MyTable.flLastTrueEyeYaw || eye[ 2 ] ) ), -MyTable.flSwayScale, MyTable.flSwayScale ), 0 )
		MyTable.flLastTrueEyeYaw = eye[ 2 ]
		MyTable.aLastEyePosition[ 2 ] = -MyTable.flLastEyeYaw
		if MyTable.__VIEWMODEL_FULLY_MODELED__ then
			flMultiplier = 1
		else
			MyTable.flAimLastEyeYaw = Lerp( math_min( 1, 5 * FrameTime() ), math_Clamp( MyTable.flAimLastEyeYaw + math_AngleDifference( eye[ 2 ], ( MyTable.flAimLastTrueEyeYaw || eye[ 2 ] ) ), -MyTable.flSwayScale * .33, MyTable.flSwayScale * .33 ), 0 )
			MyTable.flAimLastTrueEyeYaw = eye[ 2 ]
			vTargetAngle[ 3 ] = vTargetAngle[ 3 ] - MyTable.flAimLastEyeYaw / MyTable.flSwayScale * 3 * 45 * ( 1 - flMultiplier )
		end
		if bSliding then
			vTarget = vTarget + MyTable.vSprintArm
			vTarget[ 3 ] = vTarget[ 3 ] - 3
			vTargetAngle = Vector( MyTable.vSprintArmAngle )
		end
		vFinal = LerpVector( 5 * FrameTime(), vFinal, vTarget )
		vFinalAngle = LerpVector( 5 * FrameTime(), vFinalAngle, vTargetAngle )
		ang:RotateAroundAxis( ang:Right(), vFinalAngle.x )
		ang:RotateAroundAxis( ang:Up(), vFinalAngle.y )
		ang:RotateAroundAxis( ang:Forward(), vFinalAngle.z )
		pos = pos + vFinal.z * ang:Up()
		pos = pos + vFinal.y * ang:Forward()
		pos = pos + vFinal.x * ang:Right()
		ang:RotateAroundAxis( ang:Right(), vInstantTargetAngle.x )
		ang:RotateAroundAxis( ang:Up(), vInstantTargetAngle.y )
		ang:RotateAroundAxis( ang:Forward(), vInstantTargetAngle.z )
		pos = pos + vInstantTarget.z * ang:Up()
		pos = pos + vInstantTarget.y * ang:Forward()
		pos = pos + vInstantTarget.x * ang:Right()
		vFinalRatherQuick = LerpVector( math_min( 1, 10 * FrameTime() ), vFinalRatherQuick, vTargetRatherQuick )
		vFinalRatherQuickAngle = LerpVector( math_min( 1, 10 * FrameTime() ), vFinalRatherQuickAngle, vTargetRatherQuickAngle )
		ang:RotateAroundAxis( ang:Right(), vFinalRatherQuickAngle.x )
		ang:RotateAroundAxis( ang:Up(), vFinalRatherQuickAngle.y )
		ang:RotateAroundAxis( ang:Forward(), vFinalRatherQuickAngle.z )
		pos = pos + vFinalRatherQuick.z * ang:Up()
		pos = pos + vFinalRatherQuick.y * ang:Forward()
		pos = pos + vFinalRatherQuick.x * ang:Right()
		local flSwayAngle = MyTable.flSwayAngle * flMultiplier
		local flSwayAngleNeg = -flSwayAngle
		ang:RotateAroundAxis( ang:Right(), math_Clamp( flSwayAngle * MyTable.aLastEyePosition.p / MyTable.flSwayScale, flSwayAngleNeg, flSwayAngle ) )
		ang:RotateAroundAxis( ang:Up(), math_Clamp( flSwayAngleNeg * MyTable.aLastEyePosition.y / MyTable.flSwayScale, flSwayAngleNeg, flSwayAngle ) )
		local flSwayVector = MyTable.flSwayVector * flMultiplier
		local flSwayVectorNeg = -flSwayVector
		pos = pos + math_Clamp( ( flSwayVectorNeg * MyTable.aLastEyePosition.p / MyTable.flSwayScale ), flSwayVectorNeg, flSwayVector ) * ang:Up()
		pos = pos + math_Clamp( ( flSwayVectorNeg * MyTable.aLastEyePosition.y / MyTable.flSwayScale ), flSwayVectorNeg, flSwayVector ) * ang:Right()
		return pos, ang
	end
	include "Crosshair.lua"
end

sound.Add {
	name = "HumanSlideLoop",
	channel = CHAN_STATIC,
	level = 70,
	sound = "physics/flesh/flesh_scrape_rough_loop.wav"
}

weapons.Register( SWEP, "BaseWeapon" )