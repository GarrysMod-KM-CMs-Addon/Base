// Viewmodel and worldmodel from here: https://steamcommunity.com/sharedfiles/filedetails/?id=3401113154
// Inspired by StrawWagen's Hunter's Glee, but no code taken from there

DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Medium Machine Guns"
SWEP.PrintName = "#OSIEW"
SWEP.Purpose = "Overwatch Standard Issue Emplacement Weapon."

if SERVER then ACHIEVEMENT_ACQUIRE "osiew" ACHIEVEMENT_MISCELLANEOUS "OSIEW_ReloadClick" end

SWEP.Spawnable = true

SWEP.ViewModel = "models/AR3_VM.mdl"
SWEP.WorldModel = "models/AR3.mdl"

SWEP.Primary.ClipSize = 256
SWEP.Primary.DefaultClip = 256
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "AR2"
SWEP.Primary_flSpreadX = .0088
SWEP.Primary_flSpreadY = .0088
SWEP.Primary_flDamage = 256
SWEP.Primary_flDelay = .08
SWEP.Primary_sTracer = "HelicopterTracer"

SWEP.flRecoil = 4

SWEP.Slot = 2
SWEP.ViewModelFOV = 62
SWEP.Crosshair = "Rifle"
SWEP.sHoldType = "AR2"

SWEP.__VIEWMODEL_FULLY_MODELED__ = true

sound.Add {
	name = "OSIEW_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 100 },
	sound = "weapons/ar2/fire1.wav"
}
SWEP.sSound = "OSIEW_Shot"

sound.Add {
	name = "OSIEW_ReloadClick",
	channel = CHAN_WEAPON,
	level = 80,
	pitch = { 90, 100 },
	sound = "weapons/shotgun/shotgun_cock.wav"
}

SWEP.vViewModelAim = Vector( -10, -3.37, 3.55 )
SWEP.vViewModelAimAngle = Vector( 0, 0, 14 )

function SWEP:Reload()
	local pReloadOwner = self:GetOwner()
	local f = self:Clip1()
	if f >= self:GetMaxClip1() && pReloadOwner:IsPlayer() then Achievement_Miscellaneous( pReloadOwner, "WeaponReloadFull" ) end
	self:SetClip1( 0 )
	if self:DefaultReload( ACT_INVALID ) then
		local pViewModel = pReloadOwner:GetViewModel()
		if IsValid( pViewModel ) then pViewModel:SendViewModelMatchingSequence( 11 ) end
		self:SetNextPrimaryFire( CurTime() + 3.1 )
		timer.Simple( 1.3, function()
			if IsValid( self ) then
				local pOwner = self:GetOwner()
				if IsValid( pOwner ) && pOwner == pReloadOwner then
					if SERVER && pOwner:IsPlayer() then Achievement_Miscellaneous( pOwner, "OSIEW_ReloadClick" ) end
					self:EmitSound "OSIEW_ReloadClick"
				end
			end
		end )
	else self:SetClip1( f ) end
end

local EffectData = EffectData
local util_Effect = util.Effect
function SWEP:DoImpactEffect( tr, dt )
	if tr.HitSky then return end
	local p = EffectData()
	local d = tr.HitNormal
	p:SetOrigin( tr.HitPos + d )
	p:SetNormal( d )
	util_Effect( "AR2Impact", p ) 
end

function SWEP:DoMuzzleFlash()
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( 1 )
	ed:SetFlags( 5 )
	util_Effect( "MuzzleFlash", ed )
end
