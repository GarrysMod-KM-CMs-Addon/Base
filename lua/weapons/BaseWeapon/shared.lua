// Lots of code is taken from Buu342's Weapon Base 2
// You can find it here: https://github.com/buu342/GMod-BuuBaseRedone
// I would've just took the code because it's the best way to do it,
// and because he took the general idea and some assets from Far Cry 3,
// but his base really helped me, and I should've wrote this credit sooner.
//
// Thank you, Buu.

DEFINE_BASECLASS "weapon_base"

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

SWEP.flReloadTime = 0
SWEP.flLastShot = 0

SWEP.sAnimationSet = "Rifle"

local NOT_SPRINTING_OVERRIDES = {
	[ ACT_HL2MP_IDLE_PISTOL ] = ACT_HL2MP_IDLE_REVOLVER,
	[ ACT_HL2MP_IDLE_CROUCH_REVOLVER ] = ACT_HL2MP_IDLE_CROUCH_PISTOL,
	[ ACT_HL2MP_WALK_PISTOL ] = ACT_HL2MP_WALK_REVOLVER,
	[ ACT_HL2MP_RUN_PISTOL ] = ACT_HL2MP_RUN_REVOLVER
}

local PISTOL_REVOLVER_ETC = { Pistol = true, Revolver = true, Melee = true, Slam = true }

// A note for the future: ACT_HL2MP_IDLE_CROUCH_PASSIVE
// is not crouching, but a more alert ACT_HL2MP_IDLE

// DONE FOR ACTORS, BUT NOT FOR PLAYERS:
// Also might add "stupid" firing for low ranking units:
// high ranking units with shotguns always use the AR2 hold type,
// even when hipfiring (meaning hipfire is from the shoulder), but
// Far Cry 3 Pirates hipfire from the hip (normal Shotgun hold type), 'cause they stupid
// Oh, and also make low ranking units use the Shotgun hold type for rifles too

function SWEP:TranslateActivity( EIntendedActivity )
	local EActivity = BaseClass.TranslateActivity( self, EIntendedActivity )
	local pOwner = self:GetOwner()
	if IsValid( pOwner ) then
		if pOwner:GetNW2Bool "CTRL_bSprinting" && GetVelocity( pOwner ):Length() > 10 then
			if pOwner:IsOnGround() then
				if EIntendedActivity == ACT_MP_WALK then
					return ACT_HL2MP_RUN_FAST
				elseif EIntendedActivity == ACT_MP_RUN then
					return ACT_HL2MP_RUN_FAST
				end
			end
		end
		if pOwner:IsPlayer() then
			if pOwner:KeyDown( IN_ZOOM ) then
				if self:GetHoldType() == "Shotgun" then
					self:SetWeaponHoldType "AR2"
					EActivity = BaseClass.TranslateActivity( self, EIntendedActivity )
					self:SetWeaponHoldType "Shotgun"
					return EActivity
				end
			elseif CurTime() > self.flLastShot + 1 then
				if EIntendedActivity == ACT_MP_WALK then
					return PISTOL_REVOLVER_ETC[ self:GetHoldType() ] && ACT_HL2MP_WALK || ACT_HL2MP_WALK_PASSIVE
				elseif EIntendedActivity == ACT_MP_RUN then
					return PISTOL_REVOLVER_ETC[ self:GetHoldType() ] && ACT_HL2MP_RUN || ACT_HL2MP_RUN_PASSIVE
				elseif EIntendedActivity == ACT_MP_STAND_IDLE then
					return PISTOL_REVOLVER_ETC[ self:GetHoldType() ] && ACT_HL2MP_IDLE || ACT_HL2MP_IDLE_PASSIVE
				elseif EIntendedActivity == ACT_MP_CROUCH_IDLE then
					return ACT_HL2MP_IDLE_CROUCH
				elseif EIntendedActivity == ACT_MP_CROUCHWALK then
					// ACT_HL2MP_WALK_CROUCH_PASSIVE just sucks ass lmao
					return ACT_HL2MP_WALK_CROUCH
				end
			end
		elseif pOwner.__ACTOR__ then
			local WEAPON_STANCE = pOwner:GetNW2Int( "WEAPON_STANCE", WEAPON_STANCE_DEFAULT )
			if WEAPON_STANCE == WEAPON_STANCE_PASSIVE then
				if EIntendedActivity == ACT_MP_WALK then
					return PISTOL_REVOLVER_ETC[ self:GetHoldType() ] && ACT_HL2MP_WALK || ACT_HL2MP_WALK_PASSIVE
				elseif EIntendedActivity == ACT_MP_RUN then
					return PISTOL_REVOLVER_ETC[ self:GetHoldType() ] && ACT_HL2MP_RUN || ACT_HL2MP_RUN_PASSIVE
				elseif EIntendedActivity == ACT_MP_STAND_IDLE then
					return PISTOL_REVOLVER_ETC[ self:GetHoldType() ] && ACT_HL2MP_IDLE || ACT_HL2MP_IDLE_PASSIVE
				elseif EIntendedActivity == ACT_MP_CROUCH_IDLE then
					return ACT_HL2MP_IDLE_CROUCH
				elseif EIntendedActivity == ACT_MP_CROUCHWALK then
					return ACT_HL2MP_WALK_CROUCH
				end
			elseif WEAPON_STANCE == WEAPON_STANCE_DEFAULT then // Nothing lol
			elseif WEAPON_STANCE == WEAPON_STANCE_AIMING then
				if self:GetHoldType() == "Shotgun" then
					self:SetWeaponHoldType "AR2"
					EActivity = BaseClass.TranslateActivity( self, EIntendedActivity )
					self:SetWeaponHoldType "Shotgun"
					return EActivity
				end
			elseif WEAPON_STANCE == WEAPON_STANCE_HIP then
				local sHoldType = self:GetHoldType()
				if !PISTOL_REVOLVER_ETC[ sHoldType ] then
					self:SetWeaponHoldType "Shotgun"
					EActivity = BaseClass.TranslateActivity( self, EIntendedActivity )
					self:SetWeaponHoldType( sHoldType )
					return EActivity
				end
			elseif WEAPON_STANCE == WEAPON_STANCE_SHOULDER then
				local sHoldType = self:GetHoldType()
				if !PISTOL_REVOLVER_ETC[ sHoldType ] && sHoldType != "SMG" then
					self:SetWeaponHoldType "AR2"
					EActivity = BaseClass.TranslateActivity( self, EIntendedActivity )
					self:SetWeaponHoldType( sHoldType )
					return EActivity
				end
			end
		end
		local v = NOT_SPRINTING_OVERRIDES[ EActivity ]
		if v then return v end
	end
	return EActivity
end

SWEP.flAimShoot = 2
if CLIENT then
	SWEP.tShootAnimations = {}
	SWEP.flCrosshairAlpha = 255
	SWEP.flCurrentRecoilForGap = 0
	function SWEP:LastShot() self.flLastShot = CurTime() end
	function SWEP:AddRecoil( flRecoil )
		local pOwner = self:GetOwner()
		if !IsValid( pOwner ) then return end
		self.flCurrentRecoilForGap = self.flCurrentRecoilForGap + 1 / pOwner:GetNW2Float( "GAME_flRecoil", 1 )
		if self.flAimShoot then self.flBarrelBack = ( self.flBarrelBack || 0 ) + 1 end
		SHOOTING_MOTION_BLUR = SHOOTING_MOTION_BLUR + self.Primary_flDelay / math.min( 1 / 2, self:GetMaxClip1() / 60 )
		table.insert( self.tShootAnimations, CurTime() )
	end
	function SWEP:ReloadTime( f ) self.flReloadTime = CurTime() + f end
end

function SWEP:ReloadEffects() end

function SWEP:GetReloadActivity() return ACT_VM_RELOAD end

function SWEP:GetMuzzleFlash() return "MuzzleNew" end
local tMuzzleEvents = { [ 20 ] = true, [ 21 ] = true, [ 22 ] = true, [ 5001 ] = true, [ 6001 ] = true }
function SWEP:FireAnimationEvent( pos, ang, EEvent )
	if !tMuzzleEvents[ EEvent ] then return end
	local pOwner = self:GetOwner()
	if !IsValid( pOwner ) then return end
	if pOwner:IsPlayer() && Either( CLIENT, CLIENT && pOwner:ShouldDrawLocalPlayer(), true ) && !game.SinglePlayer() then return true end
	self:DoMuzzleFlashInternal( pOwner )
	return true
end

function SWEP:DoMuzzleFlashInternal( pOwner )
	pOwner = pOwner || self:GetOwner()
	if !IsValid( pOwner ) then return end
	local f = pOwner.GetShootPos
	if !f then return end
	local pEffectData = EffectData()
	local v = f( pOwner )
	pEffectData:SetOrigin( v )
	pEffectData:SetEntity( self )
	pEffectData:SetStart( v )
	local a = pOwner:GetAimVector():Angle()
	pEffectData:SetNormal( a:Forward() )
	pEffectData:SetAngles( a )
	pEffectData:SetAttachment( 1 )
	util.Effect( self:GetMuzzleFlash(), pEffectData )
end

SWEP.m_bAllowOneInTheChamber = true
function SWEP:Reload()
	if !self.bAllowReloadingDuringPrimaryFire && CurTime() <= self:GetNextPrimaryFire() then return end
	local pReloadOwner = self:GetOwner()
	local f = self:Clip1()
	if SERVER && f >= self:GetMaxClip1() && pReloadOwner:IsPlayer() then Achievement_Miscellaneous( pReloadOwner, "WeaponReloadFull" ) end
	self:SetClip1( 0 )
	local bOneInTheChamber = self.m_bAllowOneInTheChamber && f > 0
	local ACT = self:GetReloadActivity( bOneInTheChamber )
	if bOneInTheChamber then
		if !self.m_bOneInTheChamber then
			self.Primary.ClipSize = self.Primary.ClipSize + 1
			self.m_bOneInTheChamber = true
		end
	else
		if self.m_bOneInTheChamber then
			self.Primary.ClipSize = self.Primary.ClipSize - 1
			self.m_bOneInTheChamber = nil
		end
	end
	if self:DefaultReload( ACT, bOneInTheChamber ) then
		self:ReloadEffects( ACT )
		if !pReloadOwner:IsPlayer() then return end
		f = pReloadOwner:GetViewModel()
		f = f:SequenceDuration( f:SelectWeightedSequence( ACT ) )
		self.flReloadTime = f
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

function SWEP:GetDrawActivity() return ACT_VM_DRAW end
function SWEP:Deploy() self:BaseWeaponDraw( self:GetDrawActivity() ) end

function SWEP:Equip( pOwner ) self.m_pLastOwner = pOwner end

function SWEP:Holster()
	// This is just frustarting!
	// if CurTime() <= self:GetNextPrimaryFire() || CurTime() <= self:GetNextSecondaryFire() then return end
	if CurTime() <= ( self.flReloadTime || 0 ) then return end
	self:HolsterWasRan()
	if SERVER then self:CallOnClient "HolsterWasRan" end
	return true
end

if CLIENT then
	function BASE_WEAPON_ON_DROP()
		local pLocalPlayer = LocalPlayer()
		if !IsValid( pLocalPlayer ) then return end
		local pViewModel = pLocalPlayer:GetViewModel()
		if IsValid( pViewModel ) then pViewModel:SetColor( color_white ) end
	end
end

function SWEP:OnDrop()
	local pOwner = self.m_pLastOwner
	if !IsValid( pOwner ) || !pOwner:IsPlayer() then return end
	pOwner:SendLua "BASE_WEAPON_ON_DROP()"
end

function SWEP:HolsterWasRan()
	self.m_bHolsterWasRan = true
	local pOwner = self:GetOwner()
	local pViewModel = pOwner.GetViewModel
	if pViewModel then
		pViewModel = pViewModel( pOwner )
		if IsValid( pViewModel ) then pViewModel:SetColor( color_white ) end
	end
end

function SWEP:Think()
	if !self.m_bHolsterWasRan then
		local pViewModel = self:GetOwner():GetViewModel()
		pViewModel:SetColor( self:GetColor() )
	end
	local f = self.flRemoveWorldModelOverrideIn
	if f && CurTime() > f then self:SetRenderOrigin( nil ) self:SetRenderAngles( nil ) self.flRemoveWorldModelOverrideIn = nil end
end

function SWEP:HolsterWasNotRan() self.m_bHolsterWasRan = nil end

function SWEP:BaseWeaponDraw( iActivity )
	local owner = self:GetOwner()
	if !IsValid( owner ) then return end
	self:HolsterWasNotRan()
	if SERVER then self:CallOnClient "HolsterWasNotRan" end
	if !owner.GetViewModel then return end
	local vm = self:GetOwner():GetViewModel()
	local s = vm:SelectWeightedSequence( iActivity )
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

SWEP.flRecoil = 1
SWEP.flSideWaysRecoilMin = -.33
SWEP.flSideWaysRecoilMax = .33
SWEP.flRecoilGrowMin = .5
SWEP.flRecoilGrowMax = 1
DEFINE_BASECLASS "weapon_base"
local util_SharedRandom = util.SharedRandom
function SWEP:CalcRecoil( pOwner )
	local flRecoil = self.flRecoil
	if pOwner.GetRunSpeed then flRecoil = flRecoil * math.Clamp( 1 + pOwner:GetVelocity():Length() / ( pOwner:GetRunSpeed() * 1.5 ), 1, 1.5 ) end
	local f = pOwner.KeyDown
	if f && !f( pOwner, IN_ZOOM ) then flRecoil = flRecoil * 1.1 end
	if !pOwner:IsOnGround() then flRecoil = flRecoil * 1.1 end
	return flRecoil
end

// These are only used on the client, but, you know, Lua is Lua,
// so we can't define 'em in an if, 'cause we have multiple CLIENT ifs
local aAim, aViewAim = Angle(), Angle()

SWEP.m_flFlipMyKick = 0
function SWEP:DoRecoil()
	local pOwner = self:GetOwner()
	if !IsValid( pOwner ) then return end
	if game.SinglePlayer() && SERVER && pOwner:IsPlayer() then self:CallOnClient "DoRecoil" end
	local flMultiplier = pOwner.GetNW2Float && pOwner:GetNW2Float( "GAME_flRecoil", 1 ) || 1
	local flRecoil = self:CalcRecoil( pOwner ) * flMultiplier
	local aAngle = Angle( -util_SharedRandom( "BaseWeaponRecoil", self.flRecoilGrowMin, self.flRecoilGrowMax ) * flRecoil, util_SharedRandom( "BaseWeaponRecoil", self.flSideWaysRecoilMin, self.flSideWaysRecoilMax ) * flRecoil, 0 )
	if pOwner:IsPlayer() then self:CallOnClient( "AddRecoil", flRecoil ) end
	local f = pOwner.ViewPunch
	if IsValid( pOwner ) && f then
		if CurTime() <= self.m_flFlipMyKick then
			local b = self.m_bFlipMyKickPitch
			local flPitch = util_SharedRandom( "BaseWeaponViewPunchPitch", 0, 1 )
			if b then flPitch = -flPitch end
			self.m_bFlipMyKickPitch = !b
			b = self.m_bFlipMyKickYaw
			local flYaw = util_SharedRandom( "BaseWeaponViewPunchYaw", 0, 1 )
			if b then flYaw = -flYaw end
			self.m_bFlipMyKickYaw = !b
			f( pOwner, Angle( flPitch * flRecoil, flYaw * flRecoil, 0 ) )
		else
			local flPitch = util_SharedRandom( "BaseWeaponViewPunchPitch", -1, 1 )
			self.m_bFlipMyKickPitch = flPitch > 0
			local flYaw = util_SharedRandom( "BaseWeaponViewPunchYaw", -1, 1 )
			self.m_bFlipMyKickYaw = flYaw > 0
			f( pOwner, Angle( flPitch * flRecoil, flYaw * flRecoil, 0 ) )
		end
		self.m_flFlipMyKick = CurTime() + self.Primary_flDelay * 1.1
	end
	f = pOwner.SetEyeAngles
	local f2 = pOwner.EyeAngles
	if f && f2 then
		f( pOwner, f2( pOwner ) + aAngle )
		if CLIENT then
			aAim[ 1 ] = aAim[ 1 ] + aAngle[ 1 ]
			aAim[ 2 ] = aAim[ 2 ] + aAngle[ 2 ]
			ApplyRecoilToThirdPerson( aAngle )
		end
	end
end

local IN_ZOOM = IN_ZOOM
local ACT_VM_PRIMARYATTACK = ACT_VM_PRIMARYATTACK
local ACT_VM_PRIMARYATTACK_EMPTY = ACT_VM_PRIMARYATTACK_EMPTY
// Don't worry, this is automatically validated :)
function SWEP:GetPrimaryEmptyActivity() return ACT_VM_PRIMARYATTACK_EMPTY end
local PLAYER_ATTACK1 = PLAYER_ATTACK1
function SWEP:ShootEffects()
	self:DoRecoil()
	local pOwner = self:GetOwner()
	if !IsValid( pOwner ) then return end
	if pOwner:IsPlayer() then
		local pViewModel = pOwner:GetViewModel()
		local iActivity = self:GetPrimaryEmptyActivity()
		if iActivity && IsValid( pViewModel ) && self:Clip1() <= 1 then
			local iSequence = pViewModel:SelectWeightedSequence( iActivity )
			if iSequence != -1 then
				pViewModel:SendViewModelMatchingSequence( iSequence )
			elseif self.m_bAimShootDoesntBlockNormalShoot || !self.flAimShoot || !( pOwner:IsPlayer() && pOwner:KeyDown( IN_ZOOM ) && pOwner:IsOnGround() ) then
				self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			else self:DoMuzzleFlashInternal() end
		elseif self.m_bAimShootDoesntBlockNormalShoot || !self.flAimShoot || !( pOwner:IsPlayer() && pOwner:KeyDown( IN_ZOOM ) && pOwner:IsOnGround() ) then
			self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		else self:DoMuzzleFlashInternal() end
	end
	pOwner:SetAnimation( PLAYER_ATTACK1 )
end

local math = math
local math_min = math.min

AddCSLuaFile "Crosshair.lua"

function SWEP:DrewWorldModelAndUsedRenderOverrides() self.flRemoveWorldModelOverrideIn = CurTime() + .1 end

if CLIENT then
	local vFinal, vFinalVel = Vector(), Vector()
	local vFinalAngle, vFinalAngleVel = Vector(), Vector()
	local vTarget = Vector()
	local vTargetAngle = Vector()
	local vViewFinal, vViewFinalVel = Vector(), Vector()
	local vViewFinalAngle, vViewFinalAngleVel = Vector(), Vector()
	local vBezier = Vector()
	local vBezierAngle = Vector()
	local vInstantTarget, vInstantTargetAngle = Vector(), Vector()
	local vFinalRatherQuick, vFinalRatherQuickAngle = Vector(), Vector()
	local vFinalRatherQuickVel, vFinalRatherQuickAngleVel = Vector(), Vector()
	local vTargetRatherQuick, vTargetRatherQuickAngle = Vector(), Vector()
	local vViewFinalRatherQuick, vViewFinalRatherQuickVel = Vector(), Vector()
	local vViewFinalRatherQuickAngle, vViewFinalRatherQuickAngleVel = Vector(), Vector()
	local vViewTargetRatherQuick, vViewTargetRatherQuickAngle = Vector(), Vector()
	local flLandTime, flJumpTime = 0, 0
	SWEP.flSwayStabilizer = .415
	SWEP.ViewModelFOV = 40
	SWEP.flViewModelX = 0
	SWEP.flViewModelY = 0
	SWEP.flViewModelZ = 0
	SWEP.vViewModelAim = false
	SWEP.vViewModelAimAngle = false
	SWEP.flSwayScale = 40
	SWEP.flSway = 6
	SWEP.SwayScale = 0
	SWEP.BobScale = 0

	local WEAPON_SPRINT_DEFAULT = Vector( 1.228, 1.358, -.94 )
	local WEAPON_SPRINT_DEFAULT_ANGLE = Vector( -10.554, 34.167, -20 )

	local WEAPON_SPRINT_AK_DEFAULT = Vector( -2, 4, -2 )
	local WEAPON_SPRINT_AK_DEFAULT_ANGLE = Vector( -10, 30, -30 )

	local WEAPON_SPRINT_UPRUN_DEFAULT = Vector( 0, 4, -3 )
	local WEAPON_SPRINT_UPRUN_DEFAULT_ANGLE = Vector( 2, 35, -10 )

	SWEP.vPistolSprint = Vector( 0, 4, -2 )
	SWEP.vPistolSprintAngle = Vector( -16, 0, 0 )
	SWEP.flAimMultiplier = 1
	SWEP.flFoV = UNIVERSAL_FOV
	SWEP.flLastEyeYaw = 0
	SWEP.flBobScale = 1
	SWEP.flAimRoll = 45
	SNIPER_AIMING_MULTIPLIER = .5
	SNIPER_AIMING_SWAY_MULTIPLIER = .5
	local SPRING_STIFFNESS, SPRING_DAMPING = 3, -15
	local SPRING_STIFFNESS_CURRENT, SPRING_DAMPING_CURRENT = SPRING_STIFFNESS, SPRING_DAMPING
	local SPRING_FORCE = 50
	local SPRING_FORCE_CURRENT = SPRING_FORCE
	local SPRING_CAMERA_STIFFNESS, SPRING_CAMERA_DAMPING = 3, -15
	local SPRING_CAMERA_STIFFNESS_CURRENT, SPRING_CAMERA_DAMPING_CURRENT = SPRING_CAMERA_STIFFNESS, SPRING_CAMERA_DAMPING
	local SPRING_CAMERA_FORCE = 50
	local SPRING_CAMERA_FORCE_CURRENT = SPRING_CAMERA_FORCE
	local math_cos = math.cos
	local math_sin = math.sin
	local math_abs = math.abs
	local math_exp = math.exp
	local math_Clamp = math.Clamp
	local math_AngleDifference = math.AngleDifference
	local math_NormalizeAngle = math.NormalizeAngle
	local CEntity_WaterLevel = CEntity.WaterLevel
	local CPlayer_GetWalkSpeed = CPlayer.GetWalkSpeed
	local CPlayer_InVehicle = CPlayer.InVehicle
	local bOnGroundLast
	local math_Remap = math.Remap
	function SWEP:AdjustMouseSensitivity()
		local MyTable = CEntity_GetTable( self )
		local f = CurTime() <= ( ( MyTable.flLastShot || 0 ) + math.min( .5, MyTable.Primary_flDelay ) + ( MyTable.Primary.Automatic && 0 || .5 ) ) && .5 || 1
		local v = MyTable.flFoV
		if v then return v / LocalPlayer():GetInfoNum( "fov_desired", UNIVERSAL_FOV ) * f end
		return f
	end
	local CPlayer_IsSprinting = CPlayer.IsSprinting
	local CPlayer_Crouching = CPlayer.Crouching
	local CEntity_GetNW2Int = CEntity.GetNW2Int
	local function BezierY( f, a, b, c )
		f = f * 3.2258
		return ( 1 - f ) ^ 2 * a + 2 * ( 1 - f ) * f * b + ( f ^ 2 ) * c
	end
	local SLIDE_ANGLE = -45
	local util_TraceLine = util.TraceLine
	local flLastCalcViewCall = 0
	local SPRINT_ANIMATION_CAMERA = {
		Pistol = function( f )
			SPRING_CAMERA_STIFFNESS_CURRENT = SPRING_CAMERA_STIFFNESS * 2
			SPRING_CAMERA_DAMPING_CURRENT = SPRING_CAMERA_DAMPING * 2
			SPRING_CAMERA_FORCE_CURRENT = SPRING_CAMERA_FORCE * 4
			local flBreathe = RealTime() * 18
			vTargetAngle = vTargetAngle + Vector( math_cos( flBreathe ), 0, math_cos( flBreathe * .5 ) ) * f
		end,
		Rifle = function( f )
			SPRING_CAMERA_STIFFNESS_CURRENT = SPRING_CAMERA_STIFFNESS * 2
			SPRING_CAMERA_DAMPING_CURRENT = SPRING_CAMERA_DAMPING * 2
			SPRING_CAMERA_FORCE_CURRENT = SPRING_CAMERA_FORCE * 2
			local flBreathe = RealTime() * 18
			vTargetAngle = vTargetAngle + Vector( math_sin( flBreathe ), 0, math_sin( flBreathe * .5 ) ) * f
		end,
		UpRun = function( f )
			SPRING_CAMERA_STIFFNESS_CURRENT = SPRING_CAMERA_STIFFNESS * 2
			SPRING_CAMERA_DAMPING_CURRENT = SPRING_CAMERA_DAMPING * 2
			SPRING_CAMERA_FORCE_CURRENT = SPRING_CAMERA_FORCE * 2
			local flBreathe = RealTime() * 18
			vTargetAngle = vTargetAngle + Vector( math_sin( flBreathe ), 0, math_sin( flBreathe * .5 ) ) * f
		end
	}
	function SWEP:CalcView( ply, pos, ang )
		SPRING_CAMERA_STIFFNESS_CURRENT = SPRING_CAMERA_STIFFNESS
		SPRING_CAMERA_DAMPING_CURRENT = SPRING_CAMERA_DAMPING
		SPRING_CAMERA_FORCE_CURRENT = SPRING_CAMERA_FORCE
		local MyTable = CEntity_GetTable( self )
		local b
		local f = SysTime()
		local flFrameTime = f - flLastCalcViewCall
		flLastCalcViewCall = f
		vTarget, vTargetAngle = Vector(), Vector()
		vViewTargetRatherQuick, vViewTargetRatherQuickAngle = Vector(), Vector()
		if CEntity_IsOnGround( ply ) then
			if CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) then
				vTargetAngle[ 1 ] = math_AngleDifference( ang[ 1 ], SLIDE_ANGLE )
			elseif CEntity_GetNW2Bool( ply, "CTRL_bSprinting" ) then
				local flVelocity = CEntity_GetVelocity( ply ):Length()
				if flVelocity > 10 then
					local f = flVelocity / CPlayer_GetRunSpeed( ply ) * MyTable.flBobScale * 2
					local fFunction = SPRINT_ANIMATION_CAMERA[ MyTable.sAnimationSet ]
					if fFunction then fFunction( f ) else SPRINT_ANIMATION_CAMERA.Rifle( f ) end
				end
			else
				local flVelocity = CEntity_GetVelocity( ply ):Length()
				if flVelocity > 10 then
					local f = flVelocity / CPlayer_GetRunSpeed( ply ) * ( MyTable.flBobScale * 1.5 )
					local flBreathe = RealTime() * 9
					vTargetAngle = vTargetAngle + Vector( math_sin( flBreathe ), 0, math_cos( flBreathe * .5 ) ) * f
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
		elseif CEntity_GetNW2Bool( ply, "CTRL_bInCover" ) then
			local p = CEntity_GetNW2Int( ply, "CTRL_Variants" )
			if p == COVER_VARIANTS_LEFT then
				vTargetAngle[ 3 ] = vTargetAngle[ 3 ] - 2
				vTarget[ 2 ] = vTarget[ 2 ] - self:OBBMaxs()[ 2 ] * .5
			elseif p == COVER_VARIANTS_RIGHT then
				vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + 2 
				vTarget[ 2 ] = vTarget[ 2 ] + self:OBBMaxs()[ 2 ] * .5
			end
		end
		if CurTime() > self:GetNextPrimaryFire() + .1 && !CPlayer_KeyDown( ply, IN_ZOOM ) then
			vViewTargetRatherQuick = vViewTargetRatherQuick + vBezier
			vViewTargetRatherQuickAngle = vViewTargetRatherQuickAngle + vBezierAngle
		end
		vViewFinalVel = vViewFinalVel + ( vTarget - vViewFinal ) * SPRING_CAMERA_STIFFNESS_CURRENT * flFrameTime
		vViewFinalVel = vViewFinalVel * math_exp( SPRING_CAMERA_DAMPING_CURRENT * flFrameTime )
		vViewFinal = vViewFinal + vViewFinalVel * SPRING_CAMERA_FORCE_CURRENT * flFrameTime
		vViewFinalAngleVel = vViewFinalAngleVel + ( vTargetAngle - vViewFinalAngle ) * SPRING_CAMERA_STIFFNESS_CURRENT * flFrameTime
		vViewFinalAngleVel = vViewFinalAngleVel * math_exp( SPRING_CAMERA_DAMPING_CURRENT * flFrameTime )
		vViewFinalAngle = vViewFinalAngle + vViewFinalAngleVel * SPRING_CAMERA_FORCE_CURRENT * flFrameTime
		ang:RotateAroundAxis( ang:Right(), vViewFinalAngle.x )
		ang:RotateAroundAxis( ang:Up(), vViewFinalAngle.y )
		ang:RotateAroundAxis( ang:Forward(), vViewFinalAngle.z )
		pos = pos + vViewFinal[ 1 ] * ang:Forward()
		pos = pos + vViewFinal[ 2 ] * ang:Right()
		pos = pos + vViewFinal[ 3 ] * ang:Up()
		vViewFinalRatherQuickVel = vViewFinalRatherQuickVel + ( vViewTargetRatherQuick - vViewFinalRatherQuick ) * SPRING_CAMERA_STIFFNESS_CURRENT * 2 * flFrameTime
		vViewFinalRatherQuickVel = vViewFinalRatherQuickVel * math_exp( SPRING_CAMERA_DAMPING_CURRENT * flFrameTime )
		vViewFinalRatherQuick = vViewFinalRatherQuick + vViewFinalRatherQuickVel * SPRING_CAMERA_FORCE_CURRENT * flFrameTime
		vViewFinalRatherQuickAngleVel = vViewFinalRatherQuickAngleVel + ( vViewTargetRatherQuickAngle - vViewFinalRatherQuickAngle ) * SPRING_CAMERA_STIFFNESS_CURRENT * 2 * flFrameTime
		vViewFinalRatherQuickAngleVel = vViewFinalRatherQuickAngleVel * math_exp( SPRING_CAMERA_DAMPING_CURRENT  * flFrameTime )
		vViewFinalRatherQuickAngle = vViewFinalRatherQuickAngle + vViewFinalRatherQuickAngleVel * SPRING_CAMERA_FORCE_CURRENT * flFrameTime
		ang:RotateAroundAxis( ang:Right(), vViewFinalRatherQuickAngle.x )
		ang:RotateAroundAxis( ang:Up(), vViewFinalRatherQuickAngle.y )
		ang:RotateAroundAxis( ang:Forward(), vViewFinalRatherQuickAngle.z )
		pos = pos + vViewFinalRatherQuick[ 1 ] * ang:Forward()
		pos = pos + vViewFinalRatherQuick[ 2 ] * ang:Right()
		pos = pos + vViewFinalRatherQuick[ 3 ] * ang:Up()
		local flMultiplier = MyTable.flAimMultiplier || 0
		if MyTable.bSniper && flMultiplier <= ( MyTable.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) && !MyTable.bSniperNoSway then
			flMultiplier = ( MyTable.flSniperAimingSwayMultiplier || SNIPER_AIMING_SWAY_MULTIPLIER )
		else flMultiplier = 0 end
		local flSway = MyTable.flSway * flMultiplier
		local flSwayNeg = -flSway
		if MyTable.aLastEyePosition == nil then MyTable.aLastEyePosition = Angle( 0, 0, 0 ) end
		ang:RotateAroundAxis( ang:Right(), -math_Clamp( flSway * MyTable.aLastEyePosition.p / MyTable.flSwayScale, flSwayNeg, flSway ) )
		ang:RotateAroundAxis( ang:Up(), -math_Clamp( flSwayNeg * MyTable.aLastEyePosition.y / MyTable.flSwayScale, flSwayNeg, flSway ) )
		local flSwayVector = flSway * MyTable.flSwayStabilizer
		local flSwayVectorNeg = -flSwayVector
		pos = pos - math_Clamp( ( flSwayVectorNeg * MyTable.aLastEyePosition.p / MyTable.flSwayScale ), flSwayVectorNeg, flSwayVector ) * ang:Up()
		pos = pos - math_Clamp( ( flSwayVectorNeg * MyTable.aLastEyePosition.y / MyTable.flSwayScale ), flSwayVectorNeg, flSwayVector ) * ang:Right()
		local v = MyTable.flCustomZoomFoV
		if v then
			if MyTable.bSniper then
				local f = MyTable.flAimMultiplier <= ( MyTable.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) && v || ply:GetInfoNum( "fov_desired", UNIVERSAL_FOV )
				MyTable.flFoV = f
				ang = ang - ply:GetViewPunchAngles() * .1
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
	local cThirdPerson = GetConVar "bThirdPerson"
	function SWEP:GatherCrosshairPosition( MyTable )
		if cThirdPerson:GetBool() then return ScrW() * .5, ScrH() * .5 end
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
	SWEP.vBlindFireLeft = Vector( -1, -6, 2.5 )
	SWEP.vBlindFireLeftAngle = Vector( 0, 0, -22.5 )
	SWEP.vBlindFireRight = Vector( 1, .5, 1 )
	SWEP.vBlindFireRightAngle = Vector( 0, 0, 0 )
	SWEP.vBlindFireUp = Vector()
	SWEP.vBlindFireUpAngle = Vector( 0, 0, -30 )
	local flLastCalcViewModelViewCall = 0
	local SPRINT_ANIMATION_VIEWMODEL = {
		Pistol = function( MyTable, f, flViewModelSprint )
			SPRING_STIFFNESS_CURRENT = SPRING_STIFFNESS * 2
			SPRING_DAMPING_CURRENT = SPRING_DAMPING * 2
			SPRING_FORCE_CURRENT = SPRING_FORCE * 4
			local flBreathe = RealTime() * 9
			vTarget = vTarget + ( MyTable.vPistolSprint + Vector( 0, 0, math_cos( flBreathe ) * -2 ) ) * flViewModelSprint
			vTargetAngle = vTargetAngle + ( MyTable.vPistolSprintAngle + Vector( math_cos( flBreathe ) * 22.5, 0, 0 ) ) * flViewModelSprint
		end,
		Rifle = function( MyTable, f, flViewModelSprint )
			SPRING_STIFFNESS_CURRENT = SPRING_STIFFNESS * 2
			SPRING_DAMPING_CURRENT = SPRING_DAMPING * 2
			SPRING_FORCE_CURRENT = SPRING_FORCE * 2
			local flBreathe = RealTime() * 18
			vTarget = vTarget + ( ( MyTable.vSprint || WEAPON_SPRINT_AK_DEFAULT ) + Vector( 0, ( ( math_cos( flBreathe * .5 ) + 1 ) * 1.25 ) * f, -math_cos( flBreathe ) * f ) ) * flViewModelSprint
			vTargetAngle = vTargetAngle + ( ( MyTable.vSprint || WEAPON_SPRINT_AK_DEFAULT_ANGLE ) + Vector( ( ( math_cos( flBreathe * .5 ) + 1 ) * -2.5 ) * f, ( ( math_cos( flBreathe * .5 ) + 1 ) * 7.5 ) * f ) ) * flViewModelSprint
		end,
		UpRun = function( MyTable, f, flViewModelSprint )
			SPRING_STIFFNESS_CURRENT = SPRING_STIFFNESS * 2
			SPRING_DAMPING_CURRENT = SPRING_DAMPING * 2
			SPRING_FORCE_CURRENT = SPRING_FORCE * 2
			local flBreathe = RealTime() * 18
			vTarget = vTarget + ( ( MyTable.vSprint || WEAPON_SPRINT_UPRUN_DEFAULT ) + Vector( 0, ( ( math_cos( flBreathe * .5 ) + 1 ) * 1.25 ) * f, -math_cos( flBreathe ) * f ) ) * flViewModelSprint
			vTargetAngle = vTargetAngle + ( ( MyTable.vSprint || WEAPON_SPRINT_UPRUN_DEFAULT_ANGLE ) + Vector( ( ( math_cos( flBreathe * .5 ) + 1 ) * -2.5 ) * f, ( ( math_cos( flBreathe * .5 ) + 1 ) * 7.5 ) * f ) ) * flViewModelSprint
		end
	}
	function SWEP:CalcViewModelView( _, pos, ang )
		SPRING_STIFFNESS_CURRENT = SPRING_STIFFNESS
		SPRING_DAMPING_CURRENT = SPRING_DAMPING
		SPRING_FORCE_CURRENT = SPRING_FORCE
		local f = SysTime()
		local flFrameTime = f - flLastCalcViewModelViewCall
		flLastCalcViewModelViewCall = f
		local MyTable = CEntity_GetTable( self )
		local ply = LocalPlayer()
		local f = math_Clamp( ply:Health() / ply:GetMaxHealth(), 0, 1 )
		vBezier, vBezierAngle = Vector(), Vector()
		vTargetRatherQuick, vTargetRatherQuickAngle = Vector(), Vector()
		MyTable.flBobScale = math.Remap( f, 0, 1, 2, 1 )
		local bSprinting = CEntity_GetNW2Bool( ply, "CTRL_bSprinting" )
		local bSliding = CEntity_GetNW2Bool( ply, "CTRL_bSliding" )
		local bInCover = CEntity_GetNW2Bool( ply, "CTRL_bInCover" ) && !CEntity_GetNW2Bool( ply, "CTRL_bGunUsesCoverStance" )
		local bZoom = !bSprinting && !bSliding && !bInCover && CEntity_IsOnGround( ply ) && CPlayer_KeyDown( ply, IN_ZOOM )
		local flBreathe = RealTime() * 5
		local vAim
		if bZoom then vAim = MyTable.vViewModelAim end
		if bZoom then
			if vAim then
				vTarget = Vector( vAim )
				local vAimAngle = MyTable.vViewModelAimAngle
				vTargetAngle = vAimAngle && Vector( vAimAngle ) || Vector()
			else bZoom = nil end
		else
			if CurTime() > self:GetNextPrimaryFire() then
				vTarget = Vector( 0, math_cos( flBreathe * .5 ) * .0625, math_sin( flBreathe / 3 ) * .0625 )
				vTargetAngle = Vector( math_sin( flBreathe / 3 ) * .25, math_cos( flBreathe * .5 ) * .25 )
			end
		end
		vInstantTarget, vInstantTargetAngle = Vector(), Vector()
		if IsValid( ply:GetNW2Entity "GAME_pVehicle" ) then vInstantTarget = vInstantTarget - Vector( 0, 0, 999999 ) end
		vInstantTarget = vInstantTarget - Vector( MyTable.flViewModelY, 0, MyTable.flViewModelZ ) * MyTable.flViewModelSprint
		if !MyTable.bCoverNotAnimated && bInCover then
			MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 0 )
			if MyTable.__VIEWMODEL_FULLY_MODELED__ then
				local f = CEntity_GetNW2Int( ply, "CTRL_Variants" )
				if f == COVER_VARIANTS_LEFT then
					vTargetAngle.x = vTargetAngle.x + 45
					vTarget.z = vTarget.z - 10 - MyTable.flViewModelZ
					vTarget.x = vTarget.x - 10 - MyTable.flViewModelX + ( MyTable.flCoverX || 0 )
					vTarget.y = vTarget.y + ( MyTable.vViewModelAim && MyTable.vViewModelAim[ 2 ] || 2 ) - self:OBBMaxs()[ 2 ] * .5 + 6
				elseif f == COVER_VARIANTS_RIGHT then
					vTargetAngle.x = vTargetAngle.x + 45
					vTarget.z = vTarget.z - 10 - MyTable.flViewModelZ
					vTarget.x = vTarget.x - 10 - MyTable.flViewModelX + ( MyTable.flCoverX || 0 )
					vTarget.y = vTarget.y + ( MyTable.vViewModelAim && MyTable.vViewModelAim[ 2 ] || 2 ) + self:OBBMaxs()[ 2 ] * .5 - 6
				else
					vTargetAngle.x = vTargetAngle.x + 45
					vTarget.y = vTarget.y + ( MyTable.vViewModelAim && MyTable.vViewModelAim[ 2 ] || 2 )
					vTarget.x = vTarget.x - 10 - MyTable.flViewModelX + ( MyTable.flCoverX || 0 )
					vTarget.z = vTarget.z - 10 - MyTable.flViewModelZ
				end
			else
				vTargetAngle.x = vTargetAngle.x + 45
				vTarget.y = vTarget.y + ( MyTable.vViewModelAim && ( MyTable.vViewModelAim[ 1 ] * .5 ) || 2 )
				vTarget.x = vTarget.x - 10 - MyTable.flViewModelX + ( MyTable.flCoverY || 0 )
				vTarget.z = vTarget.z - 10 - MyTable.flViewModelZ
			end
		else
			local p, b = CEntity_GetNW2Int( ply, "CTRL_Peek" )
			if p == COVER_FIRE_LEFT then
				vTargetAngle.z = vTargetAngle.z - 22.5
			elseif p == COVER_FIRE_RIGHT then
				vTargetAngle.z = vTargetAngle.z + 22.5
			elseif MyTable.__VIEWMODEL_FULLY_MODELED__ then
				if p == COVER_BLINDFIRE_UP then
					vTarget = vTarget + ( MyTable.vBlindFireUp || vector_origin )
					vTargetAngle = vTargetAngle + ( MyTable.vBlindFireUpAngle || vector_origin )
				elseif p == COVER_BLINDFIRE_LEFT then
					//	if CPlayer_Crouching( ply ) && !bZoom then vTarget = vTarget + Vector( -1, 1, .5 ) b = true end
					vTarget = vTarget + ( MyTable.vBlindFireLeft || vector_origin )
					vTargetAngle = vTargetAngle + ( MyTable.vBlindFireLeftAngle || vector_origin )
				elseif p == COVER_BLINDFIRE_RIGHT then
					//	if CPlayer_Crouching( ply ) && !bZoom then vTarget = vTarget + Vector( -1, -1, .5 ) b = true end
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
				MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 0 )
				bOnGroundLast = true
			elseif bOnGround then
				if !b && CPlayer_Crouching( ply ) && !bZoom then vTarget = vTarget + Vector( -1, -1, .5 ) end
				bOnGroundLast = true
				if !bSliding && bSprinting && !MyTable.bSprintNotAnimated then
					MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 1 )
					local flSprint = MyTable.flViewModelSprint
					local f = math_min( .5, CEntity_GetVelocity( ply ):Length() / CPlayer_GetRunSpeed( ply ) ) * MyTable.flBobScale
					local fFunction = SPRINT_ANIMATION_VIEWMODEL[ MyTable.sAnimationSet ]
					if fFunction then fFunction( MyTable, f, MyTable.flViewModelSprint ) else SPRINT_ANIMATION_VIEWMODEL.Rifle( MyTable, f, MyTable.flViewModelSprint ) end
				else
					MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 0 )
					local flVelocity = CEntity_GetVelocity( ply ):Length()
					if !bZoom then
						if CPlayer_KeyDown( ply, IN_MOVELEFT ) then
							vTargetAngle[ 2 ] = vTargetAngle[ 2 ] - 4 * flVelocity / CPlayer_GetWalkSpeed( ply )
						elseif CPlayer_KeyDown( ply, IN_MOVERIGHT ) then
							vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + 7 * flVelocity / CPlayer_GetWalkSpeed( ply )
						end
					end
					if flVelocity > 10 then
						local flBreathe = RealTime() * 9
						local f = flVelocity / CPlayer_GetWalkSpeed( ply ) * MyTable.flAimMultiplier * MyTable.flBobScale * .5
						vTarget = vTarget + Vector( 0, -math_sin( flBreathe * .5 ), .5 - math_abs( math_cos( flBreathe * .5 ) ) ) * f
					end
				end
			else
				MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 0 )
				flLandTime = RealTime() + .31
				if bOnGroundLast then
					flJumpTime = RealTime() + .31
					flLandTime = 0
					bOnGroundLast = nil
				end
			end
			if CEntity_WaterLevel( ply ) < 1 then
				if RealTime() <= flJumpTime then
					SPRING_FORCE_CURRENT = SPRING_FORCE * 1.5
					local f = .31 - ( flJumpTime - RealTime() )
					local xx = BezierY( f, 0, -4, 0 )
					local yy = 0
					local zz = BezierY( f, 0, -2, -5 )
					local pt = BezierY( f, 0, -4.36, 10 )
					local yw = xx
					local rl = BezierY( f, 0, -10.82, -5 )
					vBezier = Vector( yy, xx, zz )
					vBezierAngle = Vector( pt, yw )
					if !MyTable.bJumpingNotAnimated && CurTime() > self:GetNextPrimaryFire() + .1 && !CPlayer_KeyDown( ply, IN_ZOOM ) then
						vTargetRatherQuick:Add( vBezier * 2 )
						vTargetRatherQuickAngle:Add( vBezierAngle )
						vTargetRatherQuickAngle:Add( Vector( pt, yw, rl ) )
					end
					vBezierAngle = Vector( pt, ( yw + 1 ) * 4, ( yw + 1 ) * 2 )
				elseif !bOnGround then
					SPRING_FORCE_CURRENT = SPRING_FORCE * 1.5
					local flBreathe = RealTime() * 30
					vBezier = Vector( 0, math_cos( flBreathe * .5 ) * .0625, -5 + ( math_sin( flBreathe / 3 ) * .0625 ) )
					vBezierAngle = Vector( 10 - ( math_sin( flBreathe / 3 ) * .25 ), math_cos( flBreathe * .5 ) * .25 )
					if !MyTable.bJumpingNotAnimated && CurTime() > self:GetNextPrimaryFire() + .1 && !CPlayer_KeyDown( ply, IN_ZOOM ) then
						vTargetRatherQuick:Add( vBezier * 2 )
						vTargetRatherQuickAngle:Add( vBezierAngle )
						vTargetRatherQuickAngle:Add( Vector( 10 - ( math_sin( flBreathe / 3 ) * .25 ), math_cos( flBreathe * .5 ) * .25, -5 ) )
					end
				elseif RealTime() <= flLandTime then
					SPRING_FORCE_CURRENT = SPRING_FORCE * 1.5
					local f = flLandTime - RealTime()
					local xx = BezierY( f, 0, -4, 0 )
					local yy = 0
					local zz = BezierY( f, 0, -2, -5 )
					local pt = BezierY( f, 0, -4.36, 10 )
					local yw = xx
					local rl = BezierY( f, 0, -10.82, -5 )
					vBezier = Vector( yy, xx, zz )
					vBezierAngle = Vector( pt, yw )
					if !MyTable.bJumpingNotAnimated && CurTime() > self:GetNextPrimaryFire() + .1 && !CPlayer_KeyDown( ply, IN_ZOOM ) then
						vTargetRatherQuick:Add( vBezier * 2 )
						vTargetRatherQuickAngle:Add( vBezierAngle )
						vTargetRatherQuickAngle:Add( Vector( pt, yw, rl ) )
					end
					vBezierAngle = Vector( pt, ( yw + 1 ) * 4, ( yw + 1 ) * 2 )
				end
			end
		end
		local f
		if MyTable.Primary.Automatic then
			f = .66 / MyTable.Primary_flDelay
			MyTable.flCurrentRecoilForGap = math.max( 0, MyTable.flCurrentRecoilForGap - f * flFrameTime )
		else
			f =.66 / ( MyTable.Primary_flDelay + .1 )
			MyTable.flCurrentRecoilForGap = math.max( 0, MyTable.flCurrentRecoilForGap - f * flFrameTime )
		end
		local flRoll = MyTable.flAimRoll
		local flAimTiltTime = MyTable.flAimTiltTime
		flAimTiltTime = Lerp( math_min( 1, 10 * flFrameTime ), flAimTiltTime, bZoom && flRoll || 0 )
		local flTime = ( -( flAimTiltTime - ( flRoll * .5 ) ) ^ 2 + ( flRoll * .5 ) ^ 2 ) / ( flRoll * .5 )
		MyTable.flAimTiltTime = flAimTiltTime
		vTargetAngle = vTargetAngle + ( bZoom && Vector( -flTime / ( flRoll / 3 ), 0, -flTime ) || Vector( 3 * flTime / flRoll, 0, flTime ) )
		if MyTable.aLastEyePosition == nil then MyTable.aLastEyePosition = Angle( 0, 0, 0 ) end
		local eye = ply:EyeAngles()
		MyTable.aLastEyePosition[ 1 ] = math_AngleDifference( aAim[ 1 ], eye[ 1 ] )
		MyTable.aLastEyePosition[ 3 ] = math_AngleDifference( aAim[ 3 ], eye[ 3 ] )
		aAim = LerpAngle( math_min( 1, 5 * flFrameTime ), aAim, eye )
		local flMultiplier
		if bZoom then flMultiplier = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flAimMultiplier, 0 )
		else flMultiplier = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flAimMultiplier, 1 ) end
		MyTable.flAimMultiplier = flMultiplier
		if MyTable.bSniper && flMultiplier <= ( MyTable.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) then
			vInstantTarget = Vector( 0, 0, 999999 )
			flMultiplier = ( MyTable.flSniperAimingSwayMultiplier || SNIPER_AIMING_SWAY_MULTIPLIER )
		end
		MyTable.flLastEyeYaw = Lerp( math_min( 1, 5 * flFrameTime ), math_Clamp( MyTable.flLastEyeYaw + math_AngleDifference( eye[ 2 ], ( MyTable.flLastTrueEyeYaw || eye[ 2 ] ) ), -MyTable.flSwayScale, MyTable.flSwayScale ), 0 )
		MyTable.flLastTrueEyeYaw = eye[ 2 ]
		MyTable.aLastEyePosition[ 2 ] = -MyTable.flLastEyeYaw
		if MyTable.__VIEWMODEL_FULLY_MODELED__ then
			flMultiplier = 1
		else
			MyTable.flAimLastEyeYaw = Lerp( math_min( 1, 5 * flFrameTime ), math_Clamp( MyTable.flAimLastEyeYaw + math_AngleDifference( eye[ 2 ], ( MyTable.flAimLastTrueEyeYaw || eye[ 2 ] ) ), -MyTable.flSwayScale * .33, MyTable.flSwayScale * .33 ), 0 )
			MyTable.flAimLastTrueEyeYaw = eye[ 2 ]
			vTargetAngle[ 3 ] = vTargetAngle[ 3 ] - MyTable.flAimLastEyeYaw / MyTable.flSwayScale * 135 * ( 1 - flMultiplier )
		end
		if bSliding then
			vTarget = vTarget + ( MyTable.vSprint || WEAPON_SPRINT_DEFAULT )
			vTarget[ 3 ] = vTarget[ 3 ] - 3
			vTargetAngle = Vector( MyTable.vSprintAngle || WEAPON_SPRINT_DEFAULT_ANGLE )
			vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + math_AngleDifference( ang[ 1 ], SLIDE_ANGLE )
		end
		local flYawTurn, flPitchTurn = 0, 0
		if MyTable.sAnimationSet == "Pistol" then
			local tShootAnimations = {}
			local flDelay = math_min( .1, MyTable.Primary_flDelay )
			local flDelayLong = flDelay
			local flDelayLongEnd = flDelay + flDelayLong
			local flDelayVeryLong = flDelay
			local flDelayVeryLongEnd = flDelayLongEnd + flDelayVeryLong
			local flDelayVeryVeryLong = flDelay
			local flDelayVeryVeryLongEnd = flDelayVeryLongEnd + flDelayVeryVeryLong
			for _, flBegin in ipairs( MyTable.tShootAnimations ) do
				if CurTime() <= flBegin + flDelay then
					local f = ( 1 - ( flBegin + flDelay - CurTime() ) / flDelay )
					ang[ 1 ] = ang[ 1 ] - f * 5.625
					pos = pos - ang:Forward() * f * 2
					table.insert( tShootAnimations, flBegin )
				elseif CurTime() <= flBegin + flDelayLongEnd then
					local f = ( flBegin + flDelayLongEnd - CurTime() ) / flDelayLong
					ang[ 1 ] = ang[ 1 ] - f * 5.625
					pos = pos - ang:Forward() * f * 2
					table.insert( tShootAnimations, flBegin )
				elseif CurTime() <= flBegin + flDelayVeryLongEnd then
					local f = ( 1 - ( flBegin + flDelayVeryLongEnd - CurTime() ) / flDelayVeryLong )
					ang[ 1 ] = ang[ 1 ] - f * .5
					pos = pos - ang:Up() * f * .5
					table.insert( tShootAnimations, flBegin )
				elseif CurTime() <= flBegin + flDelayVeryVeryLongEnd then
					local f = ( flBegin + flDelayVeryVeryLongEnd - CurTime() ) / flDelayVeryVeryLong
					ang[ 1 ] = ang[ 1 ] - f * .5
					pos = pos - ang:Up() * f * .5
					table.insert( tShootAnimations, flBegin )
				end
			end
			MyTable.tShootAnimations = tShootAnimations
		else
			// TODO: Better rifle shoot animation
			MyTable.tShootAnimations = {}
			local a = ply:GetViewPunchAngles()
			flYawTurn, flPitchTurn = a[ 2 ] * .5, a[ 1 ] * .5
			local flAimShoot = MyTable.flAimShoot
			if flAimShoot then
				local flDelay = math_Clamp( MyTable.Primary_flDelay, 0, .2 )
				local f = MyTable.flBarrelBack || 0
				if f > 1 then
					MyTable.flBarrelBack = Lerp( math_min( 1, .5 / flDelay * f * flFrameTime ), f, 0 )
				else
					if CurTime() > self:GetNextPrimaryFire() + .1 then
						MyTable.flBarrelBack = Lerp( math_min( 1, 2 / flDelay * f * flFrameTime ), f, 0 )
					else
						MyTable.flBarrelBack = math.max( 0, f - .2 / flDelay * flFrameTime )
					end
				end
				f = MyTable.flBarrelBackCurrent || 0
				f = Lerp( math_min( 1, 1.5 / flDelay * flFrameTime ), f, MyTable.flBarrelBack * ( bZoom && 1 || .25 ) )
				MyTable.flBarrelBackCurrent = f
				pos = pos - ang:Forward() * f * flAimShoot
			end
		end
		vInstantTarget = vInstantTarget + Vector( MyTable.flViewModelX, MyTable.flViewModelY, MyTable.flViewModelZ )
		vFinalVel = vFinalVel + ( vTarget - vFinal ) * SPRING_STIFFNESS_CURRENT * flFrameTime
		vFinalVel = vFinalVel * math_exp( SPRING_DAMPING_CURRENT * flFrameTime )
		vFinal = vFinal + vFinalVel * SPRING_FORCE_CURRENT * flFrameTime
		vFinalAngleVel = vFinalAngleVel + ( vTargetAngle - vFinalAngle ) * SPRING_STIFFNESS_CURRENT * flFrameTime
		vFinalAngleVel = vFinalAngleVel * math_exp( SPRING_DAMPING_CURRENT * flFrameTime )
		vFinalAngle = vFinalAngle + vFinalAngleVel * SPRING_FORCE_CURRENT * flFrameTime
		ang:RotateAroundAxis( ang:Right(), vFinalAngle.x )
		ang:RotateAroundAxis( ang:Up(), vFinalAngle.y )
		ang:RotateAroundAxis( ang:Forward(), vFinalAngle.z )
		ang:RotateAroundAxis( ang:Right(), vInstantTargetAngle.x )
		ang:RotateAroundAxis( ang:Up(), vInstantTargetAngle.y )
		ang:RotateAroundAxis( ang:Forward(), vInstantTargetAngle.z )
		vFinalRatherQuickVel = vFinalRatherQuickVel + ( vTargetRatherQuick - vFinalRatherQuick ) * SPRING_STIFFNESS_CURRENT * flFrameTime
		vFinalRatherQuickVel = vFinalRatherQuickVel * math_exp( SPRING_DAMPING_CURRENT * flFrameTime )
		vFinalRatherQuick = vFinalRatherQuick + vFinalRatherQuickVel * SPRING_FORCE_CURRENT * flFrameTime
		vFinalRatherQuickAngleVel = vFinalRatherQuickAngleVel + ( vTargetRatherQuickAngle - vFinalRatherQuickAngle ) * SPRING_STIFFNESS_CURRENT * flFrameTime
		vFinalRatherQuickAngleVel = vFinalRatherQuickAngleVel * math_exp( SPRING_DAMPING_CURRENT * flFrameTime )
		vFinalRatherQuickAngle = vFinalRatherQuickAngle + vFinalRatherQuickAngleVel * SPRING_FORCE_CURRENT * flFrameTime
		ang:RotateAroundAxis( ang:Right(), vFinalRatherQuickAngle.x )
		ang:RotateAroundAxis( ang:Up(), vFinalRatherQuickAngle.y )
		ang:RotateAroundAxis( ang:Forward(), vFinalRatherQuickAngle.z )
		pos = pos + vFinal[ 1 ] * ang:Forward()
		pos = pos + vFinal[ 2 ] * ang:Right()
		pos = pos + vFinal[ 3 ] * ang:Up()
		pos = pos + vInstantTarget[ 1 ] * ang:Forward()
		pos = pos + vInstantTarget[ 2 ] * ang:Right()
		pos = pos + vInstantTarget[ 3 ] * ang:Up()
		pos = pos + vFinalRatherQuick[ 1 ] * ang:Forward()
		pos = pos + vFinalRatherQuick[ 2 ] * ang:Right()
		pos = pos + vFinalRatherQuick[ 3 ] * ang:Up()
		local flSway = MyTable.flSway
		local flSwayNeg = -flSway
		local flSwayVector = flSway * MyTable.flSwayStabilizer
		local flSwayVectorNeg = -flSwayVector
		if MyTable.__VIEWMODEL_FULLY_MODELED__ then flMultiplier = MyTable.flAimMultiplier end
		ang:RotateAroundAxis( ang:Up(), flSwayNeg * ( MyTable.aLastEyePosition[ 2 ] * Either( MyTable.__VIEWMODEL_FULLY_MODELED__, 1 - flMultiplier, flMultiplier ) + flYawTurn ) / MyTable.flSwayScale )
		pos = pos + ( flSwayVectorNeg * ( MyTable.aLastEyePosition[ 2 ] * Either( MyTable.__VIEWMODEL_FULLY_MODELED__, 1 - flMultiplier, flMultiplier ) + flYawTurn ) / MyTable.flSwayScale ) * ang:Right()
		ang:RotateAroundAxis( ang:Forward(), flSway * MyTable.aLastEyePosition.y / MyTable.flSwayScale * 2 * flMultiplier )
		pos = pos + math_Clamp( ( flSwayVector * MyTable.aLastEyePosition.y / MyTable.flSwayScale ), flSwayVectorNeg, flSwayVector ) * ang:Up() * .4 * flMultiplier
		MyTable.aLastEyePosition[ 1 ] = math_Clamp( MyTable.aLastEyePosition[ 1 ], -MyTable.flSwayScale, MyTable.flSwayScale )
		ang:RotateAroundAxis( ang:Right(), flSway * ( MyTable.aLastEyePosition[ 1 ] * Either( MyTable.__VIEWMODEL_FULLY_MODELED__, 1, flMultiplier ) + flPitchTurn ) / MyTable.flSwayScale )
		pos = pos + ( flSwayVectorNeg * ( MyTable.aLastEyePosition[ 1 ] * Either( MyTable.__VIEWMODEL_FULLY_MODELED__, 1, flMultiplier ) + flPitchTurn ) / MyTable.flSwayScale ) * ang:Up()
		pos = pos + ( flSwayVector * MyTable.aLastEyePosition[ 2 ] / MyTable.flSwayScale ) * ang:Right() * flMultiplier
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