// Lots of code is taken from Buu342's Weapon Base 2
// You can find it here: https://github.com/buu342/GMod-BuuBaseRedone
// I would've just took the code because it's the best way to do it,
// and because he took the general idea and some assets from Far Cry 3,
// but his base really helped me, and I should've wrote this credit sooner.
//
// Thank you, Buu.

// TODO: Rifle shooting animations. They're still not perfect.
// (Yes, even after I added springed recoil!)
// I have no idea what kinda black magic Ubisoft used,
// but my anims are nowhere near the real Far Cry 3 AK-47.
// Probably springed recoil.
// (I wrote this comment before adding it, but even now that I did,
// it's still just not that vibe that the FC3 AK-47 has!)

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
	// Don't translate attack/reload, rifles don't magically reload like shotguns when held at the hip! xD
	if EIntendedActivity >= 1011/*ACT_MP_ATTACK_STAND_PRIMARYFIRE*/ && EIntendedActivity <= 1143/*ACT_MP_ATTACK_AIRWALK_GRENADE_SECONDARY*/ then return EActivity end
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
		if self:GetHoldType() == "Normal" || self:GetHoldType() == "Melee" then return EActivity end
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
	SWEP.m_flRecoilLastPitch = 0
	SWEP.m_flRecoilLastYaw = 0
	function SWEP:RecoilLastPitch( sPitch ) self.m_flRecoilLastPitch = tonumber( sPitch ) end
	function SWEP:RecoilLastYaw( sYaw ) self.m_flRecoilLastYaw = tonumber( sYaw ) end
	function SWEP:AddRecoil()
		local pOwner = self:GetOwner()
		if !IsValid( pOwner ) then return end
		self.flCurrentRecoilForGap = self.flCurrentRecoilForGap + 1 / pOwner:GetNW2Float( "GAME_flRecoil", 1 )
		if self.flAimShoot then self.flBarrelBack = ( self.flBarrelBack || 0 ) + 1 end
		table.insert( self.tShootAnimations, { CurTime(), self.m_flRecoilLastPitch, self.m_flRecoilLastYaw } )
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

SWEP.m_flNextMuzzleFlash = 0
local math_Clamp = math.Clamp
local util_Effect = util.Effect
function SWEP:DoMuzzleFlashInternal( pOwner )
	pOwner = IsValid( pOwner ) && pOwner || self:GetOwner()
	if !IsValid( pOwner ) then return end
	local f = pOwner.GetShootPos
	if !f then return end
	// Some models have multiple animation events fired in one tick
	if CurTime() <= self.m_flNextMuzzleFlash then return end
	local flDelay = self.Primary_flDelay || .1
	self.m_flNextMuzzleFlash = CurTime() + flDelay * .5
	local pEffectData = EffectData()
	local v = f( pOwner )
	pEffectData:SetOrigin( v )
	pEffectData:SetEntity( self )
	pEffectData:SetStart( v )
	local a = pOwner:GetAimVector():Angle()
	pEffectData:SetNormal( a:Forward() )
	pEffectData:SetAngles( a )
	pEffectData:SetAttachment( 1 )
	pEffectData:SetMagnitude( 1 / math_Clamp( flDelay * .66, .02, .1 ) )
	//	local b = !self.m_bMuzzleID
	//	self.m_bMuzzleID = b
	//	pEffectData:SetFlags( b && 1 || 0 )
	util_Effect( self:GetMuzzleFlash(), pEffectData )
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

//	SWEP.m_flFlipMyKick = 0
function SWEP:DoRecoil()
	local pOwner = self:GetOwner()
	if !IsValid( pOwner ) then return end
	if game.SinglePlayer() && SERVER && pOwner:IsPlayer() then self:CallOnClient "DoRecoil" end
	local flMultiplier = pOwner.GetNW2Float && pOwner:GetNW2Float( "GAME_flRecoil", 1 ) || 1
	local flRecoil = self:CalcRecoil( pOwner ) * flMultiplier
	local aAngle = Angle( -util_SharedRandom( "BaseWeaponRecoil", self.flRecoilGrowMin, self.flRecoilGrowMax ) * flRecoil, util_SharedRandom( "BaseWeaponRecoil", self.flSideWaysRecoilMin, self.flSideWaysRecoilMax ) * flRecoil )
	local f, flPitch, flYaw = pOwner.ViewPunch
	if IsValid( pOwner ) && f then
		flPitch = util_SharedRandom( "BaseWeaponViewPunchPitch", -1, 1 )
		flYaw = util_SharedRandom( "BaseWeaponViewPunchYaw", -1, 1 )
		f( pOwner, Angle( flPitch * flRecoil, flYaw * flRecoil, 0 ) )
		//	if CurTime() <= self.m_flFlipMyKick then
		//		local b = self.m_bFlipMyKickPitch
		//		flPitch = util_SharedRandom( "BaseWeaponViewPunchPitch", 0, 1 )
		//		if b then flPitch = -flPitch end
		//		self.m_bFlipMyKickPitch = !b
		//		b = self.m_bFlipMyKickYaw
		//		flYaw = util_SharedRandom( "BaseWeaponViewPunchYaw", 0, 1 )
		//		if b then flYaw = -flYaw end
		//		self.m_bFlipMyKickYaw = !b
		//		f( pOwner, Angle( flPitch * flRecoil, flYaw * flRecoil, 0 ) )
		//	else
		//		flPitch = util_SharedRandom( "BaseWeaponViewPunchPitch", -1, 1 )
		//		self.m_bFlipMyKickPitch = flPitch > 0
		//		flYaw = util_SharedRandom( "BaseWeaponViewPunchYaw", -1, 1 )
		//		self.m_bFlipMyKickYaw = flYaw > 0
		//		f( pOwner, Angle( flPitch * flRecoil, flYaw * flRecoil, 0 ) )
		//	end
		//	self.m_flFlipMyKick = CurTime() + self.Primary_flDelay * 3
	end
	if pOwner:IsPlayer() then
		self:CallOnClient( "RecoilLastPitch", flPitch )
		self:CallOnClient( "RecoilLastYaw", flYaw )
		self:CallOnClient "AddRecoil"
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
				self:DoMuzzleFlashInternal( pOwner )
			elseif self.m_bAimShootDoesntBlockNormalShoot || self.bSniper || !self.flAimShoot || !( pOwner:IsPlayer() && pOwner:KeyDown( IN_ZOOM ) && pOwner:IsOnGround() ) then
				self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			else self:DoMuzzleFlashInternal( pOwner ) end
		elseif self.m_bAimShootDoesntBlockNormalShoot || self.bSniper || !self.flAimShoot || !( pOwner:IsPlayer() && pOwner:KeyDown( IN_ZOOM ) && pOwner:IsOnGround() ) then
			self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		else self:DoMuzzleFlashInternal( pOwner ) end
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
	local vRecoilWorldSpring, vRecoilWorldVelocity = Vector(), Vector()
	local vRecoilWorldAngleSpring, vRecoilWorldAngleVelocity = Vector(), Vector()
	local vRecoilViewSpring, vRecoilViewVelocity = Vector(), Vector()
	local vRecoilViewAngleSpring, vRecoilViewAngleVelocity = Vector(), Vector()

	local flLandTime, flJumpTime = 0, 0
	SWEP.flSwayStabilizer = .415
	SWEP.ViewModelFOV = 40
	SWEP.flViewModelX = 0
	SWEP.flViewModelY = 0
	SWEP.flViewModelZ = 0
	SWEP.vViewModelAim = false
	SWEP.vViewModelAimAngle = false
	SWEP.flSwayScale = 50
	SWEP.flSway = 4
	SWEP.SwayScale = 0
	SWEP.BobScale = 0

	SWEP.WPN_SHOOT = WPN_RIFLE

	//	local WEAPON_SPRINT_DEFAULT = Vector( 1.228, 1.358, -.94 )
	//	local WEAPON_SPRINT_DEFAULT_ANGLE = Vector( -10.554, 34.167, -20 )

	local WEAPON_SPRINT_RIFLE_DEFAULT = Vector( -2, 4, -2 )
	local WEAPON_SPRINT_RIFLE_DEFAULT_ANGLE = Vector( -10, 30, -30 )

	local WEAPON_SPRINT_RIFLEUP_DEFAULT = Vector( 0, 4, -3 )
	local WEAPON_SPRINT_RIFLEUP_DEFAULT_ANGLE = Vector( 2, 35, -10 )

	local WEAPON_SPRINT_SNIPER_DEFAULT = Vector( -2, 4, -2 )
	local WEAPON_SPRINT_SNIPER_DEFAULT_ANGLE = Vector( -10, 30, -30 )

	local WEAPON_SPRINT_PISTOL_DEFAULT = Vector( 0, 2, -4 )
	local WEAPON_SPRINT_PISTOL_DEFAULT_ANGLE = Vector( -16, 0, -22.5 )

	SWEP.flAimMultiplier = 1
	SWEP.flFoV = UNIVERSAL_FOV
	SWEP.flLastEyeYaw = 0
	SWEP.flBobScale = 1
	SWEP.flAimRoll = 45
	SWEP.flAimSway = .33
	SNIPER_AIMING_MULTIPLIER = .5
	SNIPER_AIMING_SWAY_MULTIPLIER = .5
	local SPRING_STIFFNESS_CURRENT, SPRING_DAMPING_CURRENT
	local SPRING_CAMERA_STIFFNESS_CURRENT, SPRING_CAMERA_DAMPING_CURRENT
	local math_cos = math.cos
	local math_sin = math.sin
	local math_abs = math.abs
	local math_exp = math.exp
	local math_AngleDifference = math.AngleDifference
	local math_NormalizeAngle = math.NormalizeAngle
	local CEntity_WaterLevel = CEntity.WaterLevel
	local CPlayer_GetWalkSpeed = CPlayer.GetWalkSpeed
	local CPlayer_InVehicle = CPlayer.InVehicle
	local bOnGroundLast
	local math_Remap = math.Remap
	function SWEP:AdjustMouseSensitivity()
		local MyTable = CEntity_GetTable( self )
		local f = CurTime() <= ( ( MyTable.flLastShot || 0 ) + math_min( .5, MyTable.Primary_flDelay ) + ( MyTable.Primary.Automatic && 0 || .2 ) ) && .33 || 1
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
	local util_TraceLine = util.TraceLine
	local flLastCalcViewCall = 0
	local SPRINT_ANIMATION_CAMERA = {
		[ WPN_PISTOL ] = function( f )
			SPRING_CAMERA_STIFFNESS_CURRENT = SPRING_CAMERA_STIFFNESS_CURRENT * 2
			local flBreathe = RealTime() * 18
			vTargetAngle = vTargetAngle + Vector( math_cos( flBreathe ), 0, math_cos( flBreathe * .5 ) ) * f
		end,
		[ WPN_RIFLE ] = function( f )
			SPRING_CAMERA_STIFFNESS_CURRENT = SPRING_CAMERA_STIFFNESS_CURRENT * 2
			local flBreathe = RealTime() * 18
			vTargetAngle = vTargetAngle + Vector( math_sin( flBreathe ), 0, math_sin( flBreathe * .5 ) ) * f
		end,
		[ WPN_RIFLEUP ] = function( f )
			SPRING_CAMERA_STIFFNESS_CURRENT = SPRING_CAMERA_STIFFNESS_CURRENT * 2
			local flBreathe = RealTime() * 18
			vTargetAngle = vTargetAngle + Vector( math_sin( flBreathe ), 0, math_sin( flBreathe * .5 ) ) * f
		end,
		[ WPN_SNIPER ] = function( f )
			SPRING_CAMERA_STIFFNESS_CURRENT = SPRING_CAMERA_STIFFNESS_CURRENT * 2
			local flBreathe = RealTime() * 18
			vTargetAngle = vTargetAngle + Vector( math_sin( flBreathe ), 0, math_sin( flBreathe * .5 ) ) * f
		end
	}
	function SWEP:CalcView( ply, pos, ang )
		SPRING_CAMERA_STIFFNESS_CURRENT = 225
		SPRING_CAMERA_DAMPING_CURRENT = -20
		local MyTable = CEntity_GetTable( self )
		local b
		local f = SysTime()
		local flFrameTime = f - flLastCalcViewCall
		flLastCalcViewCall = f
		vTarget, vTargetAngle = Vector(), Vector()
		vViewTargetRatherQuick, vViewTargetRatherQuickAngle = Vector(), Vector()
		if CEntity_IsOnGround( ply ) then
			if CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) then
			elseif CEntity_GetNW2Bool( ply, "CTRL_bSprinting" ) then
				local flVelocity = CEntity_GetVelocity( ply ):Length()
				if flVelocity > 10 then
					local f = flVelocity / CPlayer_GetRunSpeed( ply ) * MyTable.flBobScale * 2
					local fFunction = SPRINT_ANIMATION_CAMERA[ MyTable.WPN_SPRINT ]
					if fFunction then fFunction( f ) else SPRINT_ANIMATION_CAMERA[ WPN_RIFLE ]( f ) end
				end
			else
				local flVelocity = CEntity_GetVelocity( ply ):Length()
				if flVelocity > 10 then
					local f = flVelocity / CPlayer_GetRunSpeed( ply ) * MyTable.flBobScale
					local flBreathe = RealTime() * 12
					vTarget:Add( Vector( 0, -math_sin( flBreathe * .5 ) * .5, ( .5 - math_abs( math_cos( flBreathe * .5 ) ) ) * -1 ) * f )
					vTargetAngle:Add( Vector( math_sin( flBreathe ), 0, math_cos( flBreathe * .5 ) ) * f )
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
		local pViewModel = ply:GetViewModel()
		if IsValid( pViewModel ) then
			local t = VIEWMODEL_CAMERA_ANIMATIONS[ pViewModel:GetModel() ]
			if t then
				local f = t[ pViewModel:GetSequenceName( pViewModel:GetSequence() ) ]
				if f then
					f( pViewModel, vTarget, vTargetAngle )
				end
			end
		end
		local flOmega = 4.5 / ( 2.5 * MyTable.Primary_flDelay )
		local flStiffness = flOmega * flOmega
		local flDamping = -.8 * flOmega
		vRecoilWorldVelocity = vRecoilWorldVelocity - vRecoilWorldSpring * flStiffness * flFrameTime
		vRecoilWorldVelocity = vRecoilWorldVelocity * math_exp( flDamping * flFrameTime )
		vRecoilWorldSpring = vRecoilWorldSpring + vRecoilWorldVelocity * flFrameTime
		vRecoilWorldAngleVelocity = vRecoilWorldAngleVelocity - vRecoilWorldAngleSpring * flStiffness * flFrameTime
		vRecoilWorldAngleVelocity = vRecoilWorldAngleVelocity * math_exp( flDamping * flFrameTime )
		vRecoilWorldAngleSpring = vRecoilWorldAngleSpring + vRecoilWorldAngleVelocity * flFrameTime
		vViewTargetRatherQuick:Add( vBezier )
		vViewTargetRatherQuickAngle:Add( vBezierAngle )
		vViewFinalVel = vViewFinalVel + ( vTarget - vViewFinal ) * SPRING_CAMERA_STIFFNESS_CURRENT * flFrameTime
		vViewFinalVel = vViewFinalVel * math_exp( SPRING_CAMERA_DAMPING_CURRENT * flFrameTime )
		vViewFinal = vViewFinal + vViewFinalVel * flFrameTime
		vViewFinalAngleVel = vViewFinalAngleVel + ( vTargetAngle - vViewFinalAngle ) * SPRING_CAMERA_STIFFNESS_CURRENT * flFrameTime
		vViewFinalAngleVel = vViewFinalAngleVel * math_exp( SPRING_CAMERA_DAMPING_CURRENT * flFrameTime )
		vViewFinalAngle = vViewFinalAngle + vViewFinalAngleVel * flFrameTime
		ang:RotateAroundAxis( ang:Right(), vViewFinalAngle[ 1 ] )
		ang:RotateAroundAxis( ang:Up(), vViewFinalAngle[ 2 ] )
		ang:RotateAroundAxis( ang:Forward(), vViewFinalAngle[ 3 ] - vRecoilWorldAngleSpring[ 3 ] )
		ang:RotateAroundAxis( ang:Right(), -vRecoilWorldAngleSpring[ 1 ] )
		ang:RotateAroundAxis( ang:Up(), -vRecoilWorldAngleSpring[ 2 ] )
		pos = pos - vRecoilWorldSpring[ 1 ] * ang:Forward()
		pos = pos - vRecoilWorldSpring[ 2 ] * ang:Right()
		pos = pos - vRecoilWorldSpring[ 3 ] * ang:Up()
		pos = pos + vViewFinal[ 1 ] * ang:Forward()
		pos = pos + vViewFinal[ 2 ] * ang:Right()
		pos = pos + vViewFinal[ 3 ] * ang:Up()
		vViewFinalRatherQuickVel = vViewFinalRatherQuickVel + ( vViewTargetRatherQuick - vViewFinalRatherQuick ) * SPRING_CAMERA_STIFFNESS_CURRENT * 2 * flFrameTime
		vViewFinalRatherQuickVel = vViewFinalRatherQuickVel * math_exp( SPRING_CAMERA_DAMPING_CURRENT * flFrameTime )
		vViewFinalRatherQuick = vViewFinalRatherQuick + vViewFinalRatherQuickVel * flFrameTime
		vViewFinalRatherQuickAngleVel = vViewFinalRatherQuickAngleVel + ( vViewTargetRatherQuickAngle - vViewFinalRatherQuickAngle ) * SPRING_CAMERA_STIFFNESS_CURRENT * 2 * flFrameTime
		vViewFinalRatherQuickAngleVel = vViewFinalRatherQuickAngleVel * math_exp( SPRING_CAMERA_DAMPING_CURRENT  * flFrameTime )
		vViewFinalRatherQuickAngle = vViewFinalRatherQuickAngle + vViewFinalRatherQuickAngleVel * flFrameTime
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
	SWEP.vBlindFireLeft = Vector( -1, -7, 1 )
	SWEP.vBlindFireLeftAngle = Vector( 0, 0, -22.5 )
	SWEP.vBlindFireRight = Vector( 1, .5, 1 )
	SWEP.vBlindFireRightAngle = Vector( 0, 0, 22.5 )
	SWEP.vBlindFireUp = Vector()
	SWEP.vBlindFireUpAngle = Vector( 0, 0, -30 )
	SWEP.flAimShootTurn = .033
	SWEP.flAimSpeed = 5
	local math_Approach = math.Approach
	local flLastCalcViewModelViewCall = 0
	local SPRINT_ANIMATION_VIEWMODEL = {
		[ WPN_PISTOL ] = function( MyTable, f, flViewModelSprint )
			local flBreathe = RealTime() * 8
			vTarget:Add( MyTable.vSprint || WEAPON_SPRINT_PISTOL_DEFAULT * flViewModelSprint )
			vTargetAngle:Add( MyTable.vSprintAngle || WEAPON_SPRINT_PISTOL_DEFAULT_ANGLE * flViewModelSprint )
			vTarget:Add( Vector( math_cos( flBreathe ) * -1, 2, math_cos( flBreathe ) * -2 ) * flViewModelSprint )
			vTargetAngle:Add( Vector( math_cos( flBreathe ) * 22.5, math_cos( flBreathe ) * 11.25, 0 ) * flViewModelSprint )
		end,
		[ WPN_RIFLE ] = function( MyTable, f, flViewModelSprint )
			local flBreathe = RealTime() * 18
			vTarget = vTarget + ( ( MyTable.vSprint || WEAPON_SPRINT_RIFLE_DEFAULT ) + Vector( 0, ( ( math_cos( flBreathe * .5 ) + 1 ) * 1.25 ) * f, -math_cos( flBreathe ) * f ) ) * flViewModelSprint
			vTargetAngle = vTargetAngle + ( ( MyTable.vSprintAngle || WEAPON_SPRINT_RIFLE_DEFAULT_ANGLE ) + Vector( ( ( math_cos( flBreathe * .5 ) + 1 ) * -2.5 ) * f, ( ( math_cos( flBreathe * .5 ) + 1 ) * 7.5 ) * f ) ) * flViewModelSprint
		end,
		[ WPN_RIFLEUP ] = function( MyTable, f, flViewModelSprint )
			local flBreathe = RealTime() * 18
			vTarget = vTarget + ( ( MyTable.vSprint || WEAPON_SPRINT_RIFLEUP_DEFAULT ) + Vector( 0, ( ( math_cos( flBreathe * .5 ) + 1 ) * 1.25 ) * f, -math_cos( flBreathe ) * f ) ) * flViewModelSprint
			vTargetAngle = vTargetAngle + ( ( MyTable.vSprintAngle || WEAPON_SPRINT_RIFLEUP_DEFAULT_ANGLE ) + Vector( ( ( math_cos( flBreathe * .5 ) + 1 ) * -2.5 ) * f, ( ( math_cos( flBreathe * .5 ) + 1 ) * 7.5 ) * f ) ) * flViewModelSprint
		end,
		[ WPN_SNIPER ] = function( MyTable, f, flViewModelSprint )
			local flBreathe = RealTime() * 18
			vTarget = vTarget + ( ( MyTable.vSprint || WEAPON_SPRINT_SNIPER_DEFAULT ) + Vector( 0, ( ( math_cos( flBreathe * .5 ) + 1 ) * 1.25 ) * f, -math_cos( flBreathe ) * f ) ) * flViewModelSprint
			vTargetAngle = vTargetAngle + ( ( MyTable.vSprintAngle || WEAPON_SPRINT_SNIPER_DEFAULT_ANGLE ) + Vector( ( ( math_cos( flBreathe * .5 ) + 1 ) * -2.5 ) * f, ( ( math_cos( flBreathe * .5 ) + 1 ) * 7.5 ) * f ) ) * flViewModelSprint
		end
	}

	local COVER_CENTER = Vector( -20, 0, -8 )
	local COVER_CENTER_ANGLE = Vector( 70, 5, 10 )

	local COVER_LEFT = Vector( -20, 6.5, -8 )
	local COVER_LEFT_ANGLE = Vector( 70, 5, 25 )

	local COVER_RIGHT = Vector( -20, -8, -8 )
	local COVER_RIGHT_ANGLE = Vector( 70, 0, -10 )

	local math_max = math.max
	local math_Rand = math.Rand

	local function fApplyRecoil( MyTable, flFrameTime )
		for _, tAnimation in ipairs( MyTable.tShootAnimations ) do
			if tAnimation[ 4 ] then continue end
			tAnimation[ 4 ] = true
			vRecoilWorldVelocity[ 1 ] = vRecoilWorldVelocity[ 1 ] - 30
			vRecoilWorldVelocity[ 2 ] = vRecoilWorldVelocity[ 2 ] + tAnimation[ 2 ] * math_Rand( 3, 6 )
			vRecoilWorldVelocity[ 3 ] = vRecoilWorldVelocity[ 3 ] + tAnimation[ 3 ] * math_Rand( 2, 4 )
			vRecoilWorldAngleVelocity[ 1 ] = vRecoilWorldAngleVelocity[ 1 ] + tAnimation[ 2 ] * math_Rand( 3, 6 )
			vRecoilWorldAngleVelocity[ 2 ] = vRecoilWorldAngleVelocity[ 2 ] + tAnimation[ 3 ] * math_Rand( 2, 4 )
			vRecoilWorldAngleVelocity[ 3 ] = vRecoilWorldAngleVelocity[ 3 ] + math_Rand( -90, 90 )
			vRecoilViewAngleVelocity[ 3 ] = vRecoilViewAngleVelocity[ 3 ] + math_Rand( -90, 90 )
		end
		local flOmega = 4.5 / ( 2.5 * MyTable.Primary_flDelay )
		local flStiffness = flOmega * flOmega
		local flDamping = -.8 * flOmega
		vRecoilViewVelocity = vRecoilViewVelocity - vRecoilViewSpring * flStiffness * flFrameTime
		vRecoilViewVelocity = vRecoilViewVelocity * math_exp( flDamping * flFrameTime )
		vRecoilViewSpring = vRecoilViewSpring + vRecoilViewVelocity * flFrameTime
		vRecoilViewAngleVelocity = vRecoilViewAngleVelocity - vRecoilViewAngleSpring * flStiffness * flFrameTime
		vRecoilViewAngleVelocity = vRecoilViewAngleVelocity * math_exp( flDamping * flFrameTime )
		vRecoilViewAngleSpring = vRecoilViewAngleSpring + vRecoilViewAngleVelocity * flFrameTime
	end

	function SWEP:CalcViewModelView( _, pos, ang )
		SPRING_STIFFNESS_CURRENT = 225
		SPRING_DAMPING_CURRENT = -20
		local f = SysTime()
		local flFrameTime = f - flLastCalcViewModelViewCall
		flLastCalcViewModelViewCall = f
		local MyTable = CEntity_GetTable( self )
		local ply = LocalPlayer()
		local f = math_Clamp( ply:Health() / ply:GetMaxHealth(), 0, 1 )
		vBezier, vBezierAngle = Vector(), Vector()
		vTargetRatherQuick, vTargetRatherQuickAngle = Vector(), Vector()
		MyTable.flBobScale = math_Remap( f, 0, 1, 2, 1 )
		local bSprinting = CEntity_GetNW2Bool( ply, "CTRL_bSprinting" )
		local bSliding = CEntity_GetNW2Bool( ply, "CTRL_bSliding" )
		local bInCover = CEntity_GetNW2Bool( ply, "CTRL_bInCover" ) && !CEntity_GetNW2Bool( ply, "CTRL_bGunUsesCoverStance" )
		local bZoom = !bSprinting && !bSliding && !bInCover && CEntity_IsOnGround( ply ) && CPlayer_KeyDown( ply, IN_ZOOM )
		local flBreathe = RealTime() * 5
		local vAim vAim = MyTable.vViewModelAim
		if vAim then
			vTarget = vAim * ( 1 - MyTable.flAimMultiplier )
			local vAimAngle = MyTable.vViewModelAimAngle
			vTargetAngle = vAimAngle && ( vAimAngle * ( 1 - MyTable.flAimMultiplier ) ) || Vector()
		else bZoom = nil vTarget, vTargetAngle = Vector(), Vector() end
		vInstantTarget, vInstantTargetAngle = Vector(), Vector()
		if IsValid( ply:GetNW2Entity "GAME_pVehicle" ) then vInstantTarget = vInstantTarget - Vector( 0, 0, 999999 ) end
		vInstantTarget = vInstantTarget - Vector( MyTable.flViewModelY, 0, MyTable.flViewModelZ ) * MyTable.flViewModelSprint
		if !MyTable.bCoverNotAnimated && bInCover then
			MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 0 )
			if CurTime() > MyTable.flReloadTime then
				if MyTable.__VIEWMODEL_FULLY_MODELED__ then
					local f = CEntity_GetNW2Int( ply, "CTRL_Variants" )
					if f == COVER_VARIANTS_LEFT then
						vTarget:Add( COVER_LEFT )
						vTargetAngle:Add( COVER_LEFT_ANGLE )
					elseif f == COVER_VARIANTS_RIGHT then
						vTarget:Add( COVER_RIGHT )
						vTargetAngle:Add( COVER_RIGHT_ANGLE )
					else
						vTarget:Add( COVER_CENTER )
						vTargetAngle:Add( COVER_CENTER_ANGLE )
					end
				else
					vTargetAngle.x = vTargetAngle.x + 45
					vTarget.y = vTarget.y + ( MyTable.vViewModelAim && ( MyTable.vViewModelAim[ 1 ] * .5 ) || 2 )
					vTarget.x = vTarget.x - 10 - MyTable.flViewModelX + ( MyTable.flCoverY || 0 )
					vTarget.z = vTarget.z - 10 - MyTable.flViewModelZ
				end
			end
		else
			local p, b = CEntity_GetNW2Int( ply, "CTRL_Peek" )
			if p == COVER_FIRE_LEFT then
				//	vTargetAngle.z = vTargetAngle.z - 22.5
			elseif p == COVER_FIRE_RIGHT then
				//	vTargetAngle.z = vTargetAngle.z + 22.5
			elseif MyTable.__VIEWMODEL_FULLY_MODELED__ then
				if p == COVER_BLINDFIRE_UP then
					vTarget = vTarget + ( MyTable.vBlindFireUp || vector_origin )
					vTargetAngle = vTargetAngle + ( MyTable.vBlindFireUpAngle || vector_origin )
				elseif p == COVER_BLINDFIRE_LEFT then
					//	if CPlayer_Crouching( ply ) && !bZoom then vTarget = vTarget + Vector( -1, 1, .5 ) b = true end
					b = true
					vTarget = vTarget + ( MyTable.vBlindFireLeft || vector_origin )
					vTargetAngle = vTargetAngle + ( MyTable.vBlindFireLeftAngle || vector_origin )
				elseif p == COVER_BLINDFIRE_RIGHT then
					//	if CPlayer_Crouching( ply ) && !bZoom then vTarget = vTarget + Vector( -1, -1, .5 ) b = true end
					b = true
					vTarget = vTarget + ( MyTable.vBlindFireRight || vector_origin )
					vTargetAngle = vTargetAngle + ( MyTable.vBlindFireRightAngle || vector_origin )
				end
			elseif p == COVER_BLINDFIRE_LEFT then
				vTargetAngle.z = vTargetAngle.z - 45
			elseif p == COVER_BLINDFIRE_RIGHT then
				vTargetAngle.z = vTargetAngle.z + 45
			end
			local bOnGround, bWantsToSprint = CEntity_IsOnGround( ply )
			if IsValid( ply:GetNW2Entity "GAME_pVehicle" ) then
				MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 0 )
				bOnGroundLast = true
			elseif bOnGround then
				if !b && CPlayer_Crouching( ply ) && !bZoom then vTarget = vTarget + Vector( -1, -1, .5 ) end
				bOnGroundLast = true
				if bSliding then
				elseif bSprinting && !MyTable.bSprintNotAnimated then
					bWantsToSprint = true
					local flSprint = MyTable.flViewModelSprint
					local f = math_min( .5, CEntity_GetVelocity( ply ):Length() / CPlayer_GetRunSpeed( ply ) ) * MyTable.flBobScale
					local fFunction = SPRINT_ANIMATION_VIEWMODEL[ MyTable.WPN_SPRINT ]
					if fFunction then fFunction( MyTable, f, MyTable.flViewModelSprint ) else SPRINT_ANIMATION_VIEWMODEL[ WPN_RIFLE ]( MyTable, f, flSprint ) end
				else
					local flVelocity = CEntity_GetVelocity( ply ):Length()
					if !bZoom then
						if CPlayer_KeyDown( ply, IN_MOVELEFT ) then
							vTargetAngle[ 2 ] = vTargetAngle[ 2 ] - 4 * flVelocity / CPlayer_GetWalkSpeed( ply )
						elseif CPlayer_KeyDown( ply, IN_MOVERIGHT ) then
							vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + 7 * flVelocity / CPlayer_GetWalkSpeed( ply )
						end
					end
					//	if flVelocity > 10 then
					//		local flBreathe = RealTime() * 12
					//		local f = flVelocity / CPlayer_GetWalkSpeed( ply ) * MyTable.flAimMultiplier * MyTable.flBobScale * .5
					//		vTarget:Add( Vector( 0, -math_sin( flBreathe * .5 ) * .5, ( .5 - math_abs( math_cos( flBreathe * .5 ) ) ) * -1 ) * f )
					//		vTargetAngle:Add( Vector( math_sin( flBreathe ), 0, math_cos( flBreathe * .5 ) ) * f )
					//	end
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
					SPRING_STIFFNESS_CURRENT = SPRING_STIFFNESS_CURRENT * 1.5
					local f = .31 - ( flJumpTime - RealTime() )
					local xx = BezierY( f, 0, -4, 0 )
					local yy = 0
					local zz = BezierY( f, 0, -2, -5 )
					local pt = BezierY( f, 0, -4.36, 10 )
					local yw = xx
					local rl = BezierY( f, 0, -10.82, -5 )
					vBezier = Vector( yy, xx, zz * .5 )
					if !MyTable.bJumpingNotAnimated && CurTime() > self:GetNextPrimaryFire() + .1 && !CPlayer_KeyDown( ply, IN_ZOOM ) then
						vTargetRatherQuick:Add( vBezier * 2 )
						vTargetRatherQuickAngle:Add( Vector( pt * .2, yw, rl ) )
					end
					vBezierAngle = Vector( ( yw + 1 ) * -1, ( yw + 1 ) * 4, ( yw + 1 ) * 2 )
				elseif !bOnGround then
					SPRING_STIFFNESS_CURRENT = SPRING_STIFFNESS_CURRENT * 1.5
					local flBreathe = RealTime() * 30
					vBezier = Vector( 0, math_cos( flBreathe * .5 ) * .0625, ( math_sin( flBreathe / 3 ) * .0625 ) )
					vBezierAngle = Vector( ( math_sin( flBreathe / 3 ) * .25 ), math_cos( flBreathe * .5 ) * .25 )
					if !MyTable.bJumpingNotAnimated && CurTime() > self:GetNextPrimaryFire() + .1 && !CPlayer_KeyDown( ply, IN_ZOOM ) then
						vTargetRatherQuick:Add( Vector( 0, math_cos( flBreathe * .5 ) * .0625, -5 * .2 + ( math_sin( flBreathe / 3 ) * .0625 ) ) )
						vTargetRatherQuickAngle:Add( Vector( 10 * .2 - ( math_sin( flBreathe / 3 ) * .25 ), math_cos( flBreathe * .5 ) * .25, -5 ) )
					end
				elseif RealTime() <= flLandTime then
					SPRING_STIFFNESS_CURRENT = SPRING_STIFFNESS_CURRENT * 1.5
					if bWantsToSprint then MyTable.flViewModelSprint = Lerp( math_min( 1, 2 * flFrameTime ), MyTable.flViewModelSprint, 1 ) end
					local f = flLandTime - RealTime()
					local xx = BezierY( f, 0, -4, 0 )
					local yy = 0
					local zz = BezierY( f, 0, 2, -5 )
					local pt = BezierY( f, 0, -34.88, 10 )
					local yw = xx
					local rl = 0 // BezierY( f, 0, -10.82, -5 )
					vBezier = Vector( yy, xx, zz * .5 )
					if !MyTable.bJumpingNotAnimated && CurTime() > self:GetNextPrimaryFire() + .1 && !CPlayer_KeyDown( ply, IN_ZOOM ) then
						vTargetRatherQuick:Add( vBezier * 2 )
						vTargetRatherQuickAngle:Add( Vector( pt * .2, yw, rl ) )
					end
					vBezierAngle = Vector( ( yw + 1 ) * -1, ( yw + 1 ) * 4, ( yw + 1 ) * 2 )
				elseif bWantsToSprint then
					MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 1 )
				else
					MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 0 )
				end
			elseif bWantsToSprint then
				MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 1 )
			else
				MyTable.flViewModelSprint = Lerp( math_min( 1, 5 * flFrameTime ), MyTable.flViewModelSprint, 0 )
			end
		end
		local f
		if MyTable.Primary.Automatic then
			f = .66 / MyTable.Primary_flDelay
			MyTable.flCurrentRecoilForGap = math_max( 0, MyTable.flCurrentRecoilForGap - f * flFrameTime )
		else
			f = .66 / ( MyTable.Primary_flDelay + .1 )
			MyTable.flCurrentRecoilForGap = math_max( 0, MyTable.flCurrentRecoilForGap - f * flFrameTime )
		end
		local flRoll = MyTable.flAimRoll
		local flAimTiltTime = MyTable.flAimTiltTime
		flAimTiltTime = math_Approach( flAimTiltTime, bZoom && flRoll || 0, flRoll * MyTable.flAimSpeed * flFrameTime )
		local flTime = ( -( flAimTiltTime - ( flRoll * .5 ) ) ^ 2 + ( flRoll * .5 ) ^ 2 ) / ( flRoll * .5 )
		MyTable.flAimTiltTime = flAimTiltTime
		vTargetAngle:Add( bZoom && Vector( -flTime / ( flRoll / 3 ), 0, -flTime ) || Vector( 3 * flTime / flRoll, 0, flTime ) )
		if MyTable.aLastEyePosition == nil then MyTable.aLastEyePosition = Angle( 0, 0, 0 ) end
		local eye = ply:EyeAngles()
		MyTable.aLastEyePosition[ 1 ] = math_AngleDifference( aAim[ 1 ], eye[ 1 ] )
		MyTable.aLastEyePosition[ 3 ] = math_AngleDifference( aAim[ 3 ], eye[ 3 ] )
		aAim = LerpAngle( math_min( 1, 5 * flFrameTime ), aAim, eye )
		local flMultiplier
		if bZoom then flMultiplier = math_Approach( MyTable.flAimMultiplier, 0, MyTable.flAimSpeed * flFrameTime )
		else flMultiplier = math_Approach( MyTable.flAimMultiplier, 1, MyTable.flAimSpeed * flFrameTime ) end
		MyTable.flAimMultiplier = flMultiplier
		if MyTable.bSniper && flMultiplier <= ( MyTable.flSniperAimingMultiplier || SNIPER_AIMING_MULTIPLIER ) then
			vInstantTarget = Vector( 0, 0, 999999 )
			flMultiplier = ( MyTable.flSniperAimingSwayMultiplier || SNIPER_AIMING_SWAY_MULTIPLIER )
		end
		MyTable.flLastEyeYaw = Lerp( math_min( 1, 5 * flFrameTime ), math_Clamp( MyTable.flLastEyeYaw + math_AngleDifference( eye[ 2 ], ( MyTable.flLastTrueEyeYaw || eye[ 2 ] ) ), -MyTable.flSwayScale, MyTable.flSwayScale ), 0 )
		MyTable.flLastTrueEyeYaw = eye[ 2 ]
		MyTable.aLastEyePosition[ 2 ] = -MyTable.flLastEyeYaw
		if MyTable.__VIEWMODEL_FULLY_MODELED__ then
			flMultiplier = math_Remap( flMultiplier, 0, 1, MyTable.flAimSway, 1 )
		else
			MyTable.flAimLastEyeYaw = Lerp( math_min( 1, 5 * flFrameTime ), math_Clamp( MyTable.flAimLastEyeYaw + math_AngleDifference( eye[ 2 ], ( MyTable.flAimLastTrueEyeYaw || eye[ 2 ] ) ), -MyTable.flSwayScale * .33, MyTable.flSwayScale * .33 ), 0 )
			MyTable.flAimLastTrueEyeYaw = eye[ 2 ]
			vTargetAngle[ 3 ] = vTargetAngle[ 3 ] - MyTable.flAimLastEyeYaw / MyTable.flSwayScale * 135 * ( 1 - flMultiplier )
		end
		if bSliding then
			vTarget:Add( WEAPON_SPRINT_RIFLE_DEFAULT )
			vTargetAngle:Add( WEAPON_SPRINT_RIFLE_DEFAULT_ANGLE )
		end
		local flYawTurn, flPitchTurn = 0, 0
		fApplyRecoil( MyTable, flFrameTime )
		// Sniper support... needs to be redone lmao
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
		end
		if MyTable.WPN_SHOOT == WPN_PISTOL then
			flYawTurn = ply:GetViewPunchAngles()[ 2 ] * .03 * MyTable.flSwayScale
			local tShootAnimations = {}
			local flDelay = math_min( .2, MyTable.Primary_flDelay ) * .2
			local flDelayLong = flDelay * 8
			local flDelayLongEnd = flDelayLong + flDelay
			//	local flDelayVeryLong = flDelay * 8
			//	local flDelayVeryLongEnd = flDelayLongEnd + flDelayVeryLong
			//	local flDelayVeryVeryLong = flDelay * 8
			//	local flDelayVeryVeryLongEnd = flDelayVeryLongEnd + flDelayVeryVeryLong
			local flSwayScale = MyTable.flSwayScale
			for _, tAnimation in ipairs( MyTable.tShootAnimations ) do
				local flBegin = tAnimation[ 1 ]
				if CurTime() <= flBegin + flDelay then
					local f = ( 1 - ( flBegin + flDelay - CurTime() ) / flDelay ) ^ 1.1
					flPitchTurn = flPitchTurn + 2 * flSwayScale * f
					//	ang[ 1 ] = ang[ 1 ] - f * 5.625
					pos = pos - ang:Forward() * f * 1.5
					table.insert( tShootAnimations, tAnimation )
				elseif CurTime() <= flBegin + flDelayLongEnd then
					local f = ( ( flBegin + flDelayLongEnd - CurTime() ) / flDelayLong ) ^ 1.1
					flPitchTurn = flPitchTurn + 2 * flSwayScale * f
					//	ang[ 1 ] = ang[ 1 ] - f * 5.625
					pos = pos - ang:Forward() * f * 1.5
					table.insert( tShootAnimations, tAnimation )
				//	elseif CurTime() <= flBegin + flDelayVeryLongEnd then
				//		local f = ( ( 1 - ( flBegin + flDelayVeryLongEnd - CurTime() ) / flDelayVeryLong ) ) ^ 1.1
				//		ang[ 1 ] = ang[ 1 ] - f * .5
				//		pos = pos - ang:Up() * f * .5
				//		table.insert( tShootAnimations, flBegin )
				//	elseif CurTime() <= flBegin + flDelayVeryVeryLongEnd then
				//		local f = ( ( flBegin + flDelayVeryVeryLongEnd - CurTime() ) / flDelayVeryVeryLong ) ^ 1.1
				//		ang[ 1 ] = ang[ 1 ] - f * .5
				//		pos = pos - ang:Up() * f * .5
				//		table.insert( tShootAnimations, flBegin )
				end
			end
			MyTable.tShootAnimations = tShootAnimations
		elseif MyTable.WPN_SHOOT == WPN_SHOTGUN then
			flYawTurn = ply:GetViewPunchAngles()[ 2 ] * 1.5
			local tShootAnimations = {}
			local flDelay = math_min( .2, MyTable.Primary_flDelay ) * .2
			local flDelayLong = flDelay * 8
			local flDelayLongEnd = flDelayLong + flDelay
			local flSwayScale = MyTable.flSwayScale
			for _, tAnimation in ipairs( MyTable.tShootAnimations ) do
				local flBegin = tAnimation[ 1 ]
				if CurTime() <= flBegin + flDelay then
					local f = ( 1 - ( flBegin + flDelay - CurTime() ) / flDelay ) ^ 1.1
					flPitchTurn = flPitchTurn + .5 * flSwayScale * f
					pos = pos - ang:Forward() * f * 3
					table.insert( tShootAnimations, tAnimation )
				elseif CurTime() <= flBegin + flDelayLongEnd then
					local f = ( ( flBegin + flDelayLongEnd - CurTime() ) / flDelayLong ) ^ 1.1
					flPitchTurn = flPitchTurn + .5 * flSwayScale * f
					pos = pos - ang:Forward() * f * 3
					table.insert( tShootAnimations, tAnimation )
				end
			end
			MyTable.tShootAnimations = tShootAnimations
		else MyTable.tShootAnimations = {} end
		vInstantTarget:Add( Vector( MyTable.flViewModelX, MyTable.flViewModelY, MyTable.flViewModelZ ) )
		vFinalVel = vFinalVel + ( vTarget - vFinal ) * SPRING_STIFFNESS_CURRENT * flFrameTime
		vFinalVel = vFinalVel * math_exp( SPRING_DAMPING_CURRENT * flFrameTime )
		vFinal = vFinal + vFinalVel * flFrameTime
		vFinalAngleVel = vFinalAngleVel + ( vTargetAngle - vFinalAngle ) * SPRING_STIFFNESS_CURRENT * flFrameTime
		vFinalAngleVel = vFinalAngleVel * math_exp( SPRING_DAMPING_CURRENT * flFrameTime )
		vFinalAngle = vFinalAngle + vFinalAngleVel * flFrameTime
		ang:RotateAroundAxis( ang:Right(), vFinalAngle[ 1 ] + vRecoilViewAngleSpring[ 1 ] )
		ang:RotateAroundAxis( ang:Up(), vFinalAngle[ 2 ] + vRecoilViewAngleSpring[ 2 ] )
		ang:RotateAroundAxis( ang:Forward(), vFinalAngle[ 3 ] + vRecoilViewAngleSpring[ 3 ] )
		ang:RotateAroundAxis( ang:Right(), vInstantTargetAngle[ 1 ] )
		ang:RotateAroundAxis( ang:Up(), vInstantTargetAngle[ 2 ] )
		ang:RotateAroundAxis( ang:Forward(), vInstantTargetAngle[ 3 ] )
		vFinalRatherQuickVel = vFinalRatherQuickVel + ( vTargetRatherQuick - vFinalRatherQuick ) * SPRING_STIFFNESS_CURRENT * flFrameTime
		vFinalRatherQuickVel = vFinalRatherQuickVel * math_exp( SPRING_DAMPING_CURRENT * flFrameTime )
		vFinalRatherQuick = vFinalRatherQuick + vFinalRatherQuickVel * flFrameTime
		vFinalRatherQuickAngleVel = vFinalRatherQuickAngleVel + ( vTargetRatherQuickAngle - vFinalRatherQuickAngle ) * SPRING_STIFFNESS_CURRENT * flFrameTime
		vFinalRatherQuickAngleVel = vFinalRatherQuickAngleVel * math_exp( SPRING_DAMPING_CURRENT * flFrameTime )
		vFinalRatherQuickAngle = vFinalRatherQuickAngle + vFinalRatherQuickAngleVel * flFrameTime
		ang:RotateAroundAxis( ang:Right(), vFinalRatherQuickAngle[ 1 ] )
		ang:RotateAroundAxis( ang:Up(), vFinalRatherQuickAngle[ 2 ] )
		ang:RotateAroundAxis( ang:Forward(), vFinalRatherQuickAngle[ 3 ] )
		pos = pos + ( vFinal[ 1 ] + vRecoilViewSpring[ 1 ] ) * ang:Forward()
		pos = pos + ( vFinal[ 2 ] + vRecoilViewSpring[ 2 ] ) * ang:Right()
		pos = pos + ( vFinal[ 3 ] + vRecoilViewSpring[ 3 ] ) * ang:Up()
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
		ang:RotateAroundAxis( ang:Up(), flSwayNeg * ( MyTable.aLastEyePosition[ 2 ] * flMultiplier + flYawTurn ) / MyTable.flSwayScale )
		pos = pos + ( flSwayVectorNeg * ( MyTable.aLastEyePosition[ 2 ] * flMultiplier + flYawTurn ) / MyTable.flSwayScale ) * ang:Right()
		MyTable.aLastEyePosition[ 1 ] = math_Clamp( MyTable.aLastEyePosition[ 1 ], -MyTable.flSwayScale, MyTable.flSwayScale )
		ang:RotateAroundAxis( ang:Right(), flSway * ( MyTable.aLastEyePosition[ 1 ] * flMultiplier + flPitchTurn ) / MyTable.flSwayScale )
		pos = pos + ( flSwayVectorNeg * ( MyTable.aLastEyePosition[ 1 ] * flMultiplier + flPitchTurn ) / MyTable.flSwayScale ) * ang:Up()
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