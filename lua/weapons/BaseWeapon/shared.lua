// Lots of code is taken from Buu342's Weapon Base 2
// You can find it here: https://github.com/buu342/GMod-BuuBaseRedone
// I could've just took the code because it's the best way to do it,
// and because he took the general idea and some assets from Far Cry 3,
// but his base really helped me, and I really wanted to credit him.
//
// Thank you, Buu.

local math_Clamp = math.Clamp
local util_Effect = util.Effect
local math_Rand = math.Rand
local CEntity = FindMetaTable "Entity"
local CEntity_GetOwner = CEntity.GetOwner
local CPlayer = FindMetaTable "Player"
local CPlayer_KeyDown = CPlayer.KeyDown
local CPlayer_GetRunSpeed = CPlayer.GetRunSpeed
local CEntity_GetVelocity = CEntity.GetVelocity
local CEntity_IsOnGround = CEntity.IsOnGround
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
local CEntity_GetTable = CEntity.GetTable
local min = math.min

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
	[ ACT_HL2MP_WALK_CROUCH_REVOLVER ] = ACT_HL2MP_WALK_CROUCH_PISTOL,
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
	SWEP.flCurrentRecoilForGap = 0
	SWEP.flCurrentRecoilForCrosshair = 0
	SWEP.flRecoilCameraShake = 0

	function SWEP:LastShot() self.flLastShot = CurTime() end
	function SWEP:ReloadTime( f ) self.flReloadTime = CurTime() + f end

	function SWEP:RecoilImpulseUp( f )
		local pOwner = self:GetOwner()
		if !IsValid( pOwner ) then return end
		pOwner.GAME_flRecoilImpulseUp = tonumber( f )
	end

	function SWEP:RecoilImpulseRight( f )
		local pOwner = self:GetOwner()
		if !IsValid( pOwner ) then return end
		pOwner.GAME_flRecoilImpulseRight = tonumber( f )
	end

	SWEP.m_flViewPunchLastPitch = 0
	SWEP.m_flViewPunchLastYaw = 0

	local tonumber = tonumber
	function SWEP:ViewPunchLastPitch( f ) self.m_flViewPunchLastPitch = tonumber( f ) end
	function SWEP:ViewPunchLastYaw( f ) self.m_flViewPunchLastYaw = tonumber( f ) end

	function SWEP:AddRecoil()
		local pOwner = self:GetOwner()
		if !IsValid( pOwner ) then return end
		self.flRecoilCameraShake = 1
		self.flCurrentRecoilForGap = self.flCurrentRecoilForGap + 1 * pOwner:GetNW2Float( "GAME_flRecoil", 1 )
		table.insert( self.tShootAnimations, { CurTime(), self.m_flViewPunchLastPitch, self.m_flViewPunchLastYaw } )
		self.m_flViewPunchLastPitch = 0
		self.m_flViewPunchLastYaw = 0
	end
end

function SWEP:ReloadEffects() end

function SWEP:GetReloadActivity() return ACT_VM_RELOAD end

function SWEP:GetMuzzleFlash() return "MuzzleFlashGeneric" end

local tBlockMuzzleFlashEvents = { [ 20 ] = true, [ 5001 ] = true }
function SWEP:FireAnimationEvent( pos, ang, EEvent ) return tBlockMuzzleFlashEvents[ EEvent ] end

SWEP.m_flNextMuzzleFlash = 0

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
	pEffectData:SetMagnitude( 1 / math_Clamp( flDelay * math_Rand( .75, 1.25 ), .05, .1 ) )
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

sound.Add {
	name = "BaseWeaponEmpty",
	sound = "WeaponEmpty.wav",
	channel = CHAN_ITEM,
	pitch = { 90, 110 },
	level = 60
}

SWEP.sDryFire = "BaseWeaponEmpty"

SWEP.bNoPrimaryInCover = true

function SWEP:CanPrimaryAttack( MyTable, bIgnoreAmmo )
	// Believe it or not, some people (including VALVe!) have the AUDACITY to ignore this check!
	if CurTime() <= self:GetNextPrimaryFire() then return end

	local pOwner = CEntity_GetOwner( self )
	if pOwner:GetNW2Bool "CTRL_bPredictedCantShoot" || pOwner:GetNW2Bool "CTRL_bSliding" || pOwner:GetNW2Bool "CTRL_bInCover" then return end

	if CurTime() <= ( pOwner.CTRL_flCoverDontShootTime || 0 ) then return end

	if self.bNoPrimaryInCover then if IsValid( pOwner ) && pOwner.CTRL_bInCover then return end end

	if !bIgnoreAmmo && self:Clip1() <= 0 then
		local sDryFire = self.sDryFire
		if sDryFire != "" then self:EmitSound( sDryFire ) end
		// TODO: This is a shitty HACK!
		// We don't have a way to set semi auto when out of ammo yet, so sticking with this for now.
		if self.Primary.Automatic then self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay ) end
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
	local pOwner = self:GetOwner()
	if !IsValid( pOwner ) then return end
	self:HolsterWasNotRan()
	if SERVER then self:CallOnClient "HolsterWasNotRan" end
	if !pOwner.GetViewModel then return end
	local pViewModel = self:GetOwner():GetViewModel()
	local f = pViewModel:SelectWeightedSequence( iActivity )
	pViewModel:SendViewModelMatchingSequence( f )
	local flTime = CurTime() + pViewModel:SequenceDuration( f )
	if flTime > self:GetNextPrimaryFire() then self:SetNextPrimaryFire( flTime ) end
	if flTime > self:GetNextSecondaryFire() then self:SetNextSecondaryFire( flTime ) end
end

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

SWEP.flUpwardsRecoilMin = .5
SWEP.flUpwardsRecoilMax = 1

SWEP.flSidewaysRecoilMin = -1
SWEP.flSidewaysRecoilMax = 1

function SWEP:CalculateRecoil( pOwner, MyTable )
	local flRecoil = MyTable.flRecoil
	local flMultiplier = 1
	if pOwner.GetRunSpeed then flMultiplier = flMultiplier + math_Clamp( pOwner:GetVelocity():Length() / ( pOwner:GetRunSpeed() * 1.1 ), 0, .1 ) end
	local f = pOwner.KeyDown
	if f && !f( pOwner, IN_ZOOM ) then flMultiplier = flMultiplier + .4 end
	if !pOwner:IsOnGround() then flMultiplier = flMultiplier + ( 1 / 3 ) end
	return flRecoil * flMultiplier
end

local type = type

//	SWEP.m_flFlipMyKick = 0
function SWEP:DoRecoil( MyTable )
	if CLIENT then return end
	local pOwner = self:GetOwner()
	if !IsValid( pOwner ) then return end

	MyTable = type( MyTable ) != "string" && MyTable || CEntity_GetTable( self )

	local flPitch = math_Rand( MyTable.flUpwardsRecoilMin, MyTable.flUpwardsRecoilMax )
	local flYaw = math_Rand( MyTable.flSidewaysRecoilMin, MyTable.flSidewaysRecoilMax )
	local flRecoil = MyTable.CalculateRecoil( self, pOwner, MyTable )

	local OwnerTable = CEntity_GetTable( pOwner )

	local flDivisor = min( MyTable.Primary_flDelay, .2 )
	local flRecoilTwo = 2 * flRecoil

	// TODO: Use this in Actor code
	local flRecoilImpulseUp = ( OwnerTable.GAME_flRecoilImpulseUp || 0 ) + ( flRecoilTwo * flPitch ) / flDivisor
	OwnerTable.GAME_flRecoilImpulseUp = flRecoilImpulseUp

	local flRecoilImpulseRight = ( OwnerTable.GAME_flRecoilImpulseRight || 0 ) + ( flRecoilTwo * flYaw ) / flDivisor
	OwnerTable.GAME_flRecoilImpulseRight = flRecoilImpulseRight

	// TODO: View punch recoil
	local flPitch = math_Rand( -1, 1 )
	local flYaw = math_Rand( -1, 1 )
	if pOwner:IsPlayer() then
		self:CallOnClient( "RecoilImpulseUp", flRecoilImpulseUp )
		self:CallOnClient( "RecoilImpulseRight", flRecoilImpulseRight )
		self:CallOnClient( "ViewPunchLastPitch", flPitch )
		self:CallOnClient( "ViewPunchLastYaw", flYaw )
		self:CallOnClient "AddRecoil"
	end
end

// Don't worry, this is automatically validated :)
function SWEP:GetPrimaryEmptyActivity() return ACT_VM_PRIMARYATTACK_EMPTY end
function SWEP:ShootEffects()
	self:DoRecoil()
	local pOwner = self:GetOwner()
	if !IsValid( pOwner ) then return end
	self:DoMuzzleFlashInternal( pOwner )
	if pOwner:IsPlayer() then
		local pViewModel = pOwner:GetViewModel()
		local iActivity = self:GetPrimaryEmptyActivity()
		if iActivity && IsValid( pViewModel ) && self:Clip1() <= 1 then
			local iSequence = pViewModel:SelectWeightedSequence( iActivity )
			if iSequence != -1 then
				pViewModel:SendViewModelMatchingSequence( iSequence )
			elseif !self.m_bNoNormalShootAnimation && ( self.m_bAimShootDoesntBlockNormalShoot || self.bSniper || !self.flAimShoot || !( pOwner:IsPlayer() && pOwner:KeyDown( IN_ZOOM ) && pOwner:IsOnGround() ) ) then
				self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			end
		elseif !self.m_bNoNormalShootAnimation && ( self.m_bAimShootDoesntBlockNormalShoot || self.bSniper || !self.flAimShoot || !( pOwner:IsPlayer() && pOwner:KeyDown( IN_ZOOM ) && pOwner:IsOnGround() ) ) then
			self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		end
	end
	pOwner:SetAnimation( PLAYER_ATTACK1 )
end

function SWEP:DrewWorldModelAndUsedRenderOverrides() self.flRemoveWorldModelOverrideIn = CurTime() + .1 end

AddCSLuaFile "View.lua"
AddCSLuaFile "Crosshair.lua"
if CLIENT then
	include "View.lua"
	include "Crosshair.lua"
end

sound.Add {
	name = "HumanSlideLoop",
	channel = CHAN_STATIC,
	level = 70,
	sound = "physics/flesh/flesh_scrape_rough_loop.wav"
}

weapons.Register( SWEP, "BaseWeapon" )
