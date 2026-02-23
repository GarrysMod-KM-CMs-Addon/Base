DEFINE_BASECLASS "BaseWeapon"

SWEP.PrintName = "#weapon_medkit"
SWEP.Instructions = "Primary to heal, secondary to heal other."
// This hint is WAY too good to actually be in the game!
//	SWEP.Instructions = [[
//	Primary to heal, secondary to heal other.
//	
//	TIP: Medical kits heal both, your direct wounds and your blood loss.
//	But they do NOT give you blood. Heal while you can, because
//	the organism may not be able to make enough blood for you to live
//	after there's not enough to carry oxygen.]]
SWEP.Slot = 5
SWEP.SlotPos = 3
SWEP.Spawnable = true
SWEP.ViewModel = Model "models/weapons/c_medkit.mdl"
SWEP.WorldModel = Model "models/weapons/w_medkit.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true
SWEP.Primary.ClipSize = 400
SWEP.Primary.DefaultClip = SWEP.Primary.ClipSize
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = ""
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = ""
SWEP.flSuccessDelay = .5
SWEP.flFailDelay = .5
SWEP.flHeal = SWEP.Primary.ClipSize
SWEP.flReFillRate = .05
SWEP.flReFillAmount = 1
SWEP.bPistolSprint = true
SWEP.Crosshair = ""

local CurTime = CurTime
function SWEP:Initialize()
	self:SetHoldType "slam"
	self:SetLastAmmoRegen( CurTime() )
end

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

function SWEP:Deploy()
	local MyTable = CEntity_GetTable( self )
	MyTable.Regen( self, false, MyTable )
	return true
end

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 0, "LastAmmoRegen" )
	self:NetworkVar( "Float", 1, "NextIdle" )
end

function SWEP:PrimaryAttack() local MyTable = CEntity_GetTable( self ) MyTable.DoHeal( self, self:GetOwner(), MyTable ) end

if SERVER then
	local util_TraceLine = util.TraceLine
	function SWEP:SecondaryAttack()
		local owner = self:GetOwner()
		owner:LagCompensation( true )
		local vShoot = owner:GetShootPos()
		local tr = util_TraceLine {
			start = vShoot,
			endpos = vShoot + owner:GetAimVector() * ( owner.GAME_flReach || 64 ),
			filter = owner
		}
		owner:LagCompensation( false )
		self:DoHeal( tr.Entity )
	end
else
	local util_TraceLine = util.TraceLine
	function SWEP:SecondaryAttack()
		local owner = self:GetOwner()
		local vShoot = owner:GetShootPos()
		self:DoHeal( util_TraceLine( {
			start = vShoot,
			endpos = vShoot + owner:GetAimVector() * ( owner.GAME_flReach || 64 ),
			filter = owner
		} ).Entity )
	end
end

function SWEP:Reload() end

function SWEP:CanHeal( ent )
	if !IsValid( ent ) then return end
	local v = ent:GetInternalVariable "m_takedamage"
	return v == nil || v == 2
end

local math = math
local math_min = math.min
local math_floor = math.floor
local math_ceil = math.ceil
local math_max = math.max

function SWEP:DoHeal( ent, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	if !MyTable.CanHeal( self, ent ) then MyTable.HealFail( self, ent, MyTable ) return false end
	local flHealth, flMaxHealth, flBleeding = ent:Health(), ent:GetMaxHealth(), ent:GetNW2Float( "GAME_flBleeding", 0 )
	if flHealth >= flMaxHealth && flBleeding <= 0 then MyTable.HealFail( self, ent, MyTable ) return false end
	MyTable.Regen( self, true, MyTable )
	local flHeal = MyTable.flHeal
	if flHeal > 0 then
		local flAmmo = self:Clip1()
		if flAmmo <= 0 then MyTable.HealFail( self, ent, MyTable ) return false end
		local flBleedingAsHealth = FairlyTranslateBleedingToHealth( flBleeding, flMaxHealth )
		local flDelta = flMaxHealth - flHealth
		flHeal = math_min( flHeal, flAmmo, flDelta + flBleedingAsHealth )
		self:SetClip1( flAmmo - flHeal )
		local flBleedHeal = math_min( flBleedingAsHealth, flHeal )
		local f = flHeal * .5
		if flBleedHeal > f then flBleedHeal = f end
		// NOTE: SetHealth only accepts integers, so heal the bleeding
		// with the part of the blunt we can't include
		local flBlunt = flHeal - flBleedHeal
		local flBluntWhole = math_min( flDelta, math_floor( flBlunt ) )
		ent:SetHealth( flHealth + flBluntWhole )
		ent:SetNW2Float( "GAME_flBleeding", math_max( 0, flBleeding - FairlyTranslateHealthToBleeding( flBlunt - flBluntWhole, flMaxHealth ) - FairlyTranslateHealthToBleeding( flBleedHeal, flMaxHealth ) ) )
	else flHeal = 0 end
	MyTable.HealSuccess( self, ent, MyTable )
	return true
end

function SWEP:HealSuccess( ent, MyTable )
	self:EmitSound "HealthKit.Touch"
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	local owner = self:GetOwner()
	if owner:IsValid() then owner:SetAnimation( PLAYER_ATTACK1 ) end
	local flTime = CurTime()
	self:SetLastAmmoRegen( flTime )
	local flEnd = flTime + self:SequenceDuration()
	self:SetNextIdle( flEnd )
	flEnd = flEnd + ( MyTable || CEntity_GetTable( self ) ).flSuccessDelay
	self:SetNextPrimaryFire( flEnd )
	self:SetNextSecondaryFire( flEnd )
end

function SWEP:HealFail( ent )
	self:EmitSound "WallHealth.Deny"
	local flEnd = CurTime() + ( MyTable || CEntity_GetTable( self ) ).flFailDelay
	self:SetNextPrimaryFire( flEnd )
	self:SetNextSecondaryFire( flEnd )
end

function SWEP:Think()
	local MyTable = CEntity_GetTable( self )
	MyTable.Regen( self, true, MyTable )
	local flTime = CurTime()
	if flTime < self:GetNextIdle() then return end
	self:SendWeaponAnim( ACT_VM_IDLE )
	self:SetNextIdle( flTime + self:SequenceDuration() )
end

function SWEP:Regen( bKeepAligned, MyTable )
	local flTime = CurTime()
	local flPassed = flTime - self:GetLastAmmoRegen()
	MyTable = MyTable || CEntity_GetTable( self )
	local flRate = MyTable.flReFillRate
	if flPassed < flRate then return end
	local flAmmo = self:Clip1()
	local flMax = MyTable.Primary.ClipSize
	if flAmmo >= flMax then return end
	if flRate > 0 then
		self:SetClip1( math_min( flAmmo + math_floor( flPassed / flRate ) * MyTable.flReFillAmount, flMax ) )
		self:SetLastAmmoRegen( bKeepAligned == true && flTime + flPassed % flRate || flTime )
	else
		self:SetClip1( flMax )
		self:SetLastAmmoRegen( flTime )
	end
end
