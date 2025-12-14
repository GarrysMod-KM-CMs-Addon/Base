DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Special"
SWEP.PrintName = "#weapon_flaregun"

SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Shoots signal flares."
SWEP.ViewModel = Model "models/weapons/c_pistol.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_pistol.mdl"
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 1
SWEP.HANDLE = { FlareGun = true }
SWEP.vViewModelAim = Vector( -5.51, -12, 3.145 )

sound.Add {
	name = "FlareShot",
	channel = CHAN_WEAPON,
	level = 120,
	pitch = { 90, 110 },
	sound = "weapons/flaregun/fire.wav"
}

function SWEP:Initialize() self:SetHoldType "Pistol" end

local PI2 = math.pi * 2
function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	local owner = self:GetOwner()
	if SERVER then
		local f = ents.Create "Flare"
		f:SetPos( owner:GetShootPos() )
		f:SetAngles( owner:GetAimVector():Angle() )
		f:SetOwner( owner )
		f:Spawn()
		f:Fire "Start"
		f:Fire "Launch"
	end
	self:ShootEffects()
	owner:SetAnimation( PLAYER_ATTACK1 )
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( 1 )
	ed:SetFlags( 1 )
	util.Effect( "MuzzleFlash", ed )
	self:EmitSound "FlareShot"
	self:TakePrimaryAmmo( 1 )
	// self:SetNextPrimaryFire( CurTime() + .5 )
end

function SWEP:SecondaryAttack() end

function SWEP:Reload()
	if CurTime() <= self:GetNextPrimaryFire() then return end
	self:SetClip1( 1 )
	local vm = self:GetOwner():GetViewModel()
	local s = vm:SelectWeightedSequence( ACT_VM_RELOAD )
	vm:SendViewModelMatchingSequence( s )
	self:SetNextPrimaryFire( CurTime() + vm:SequenceDuration( s ) )
end

list.Add( "NPCUsableWeapons", { class = "weapon_flaregun", title = "#weapon_flaregun", category = SWEP.Category } )
