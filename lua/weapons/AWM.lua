DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Sniper Rifles"
SWEP.PrintName = "#AWM"
SWEP.Instructions = "Primary to shoot, secondary + mouse forward/backward to zoom in/out."
SWEP.Purpose = "Accuracy International Arctic Warfare Magnum."
SWEP.ViewModel = Model "models/weapons/cstrike/c_snip_awp.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_snip_awp.mdl"
SWEP.Primary.ClipSize = 5
SWEP.Primary.DefaultClip = 5
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "357"
SWEP.Primary_flSpreadX = .00009259259
SWEP.Primary_flSpreadY = .00009259259
SWEP.Primary_flDamage = 128
SWEP.Primary_flDelay = 1.4
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 3
SWEP.DrawAmmo = true
SWEP.bDontDrawCrosshairDuringZoom = false
SWEP.flZoomFoVMin = 8.25
SWEP.flZoomFoVMax = 1.98
SWEP.flCustomZoomFoV = SWEP.flZoomFoVMin
SWEP.vViewModelAim = Vector( -13.5, -7.45, 2.3 )
SWEP.vSprintArm = Vector( -3.228, 1.358, -0.94 )
SWEP.bSniper = true

function SWEP:FreezeMovement()
	local owner = self:GetOwner()
	if owner:KeyDown( IN_ZOOM ) && ( owner:KeyDown( IN_ATTACK2 ) || owner:KeyReleased( IN_ATTACK2 ) ) then return true end
end

function SWEP:SetCustomZoomFoV( v ) self.flCustomZoomFoV = tonumber( v ) end

function SWEP:Tick()
	local owner = self:GetOwner()
	if CLIENT && owner != LocalPlayer() then return end
	local cmd = owner:GetCurrentCommand()
	if !cmd:KeyDown( IN_ATTACK2 ) || !cmd:KeyDown( IN_ZOOM ) then return end
	self.flCustomZoomFoV = math.Clamp( self.flCustomZoomFoV + cmd:GetMouseY() * FrameTime() * 6.6, self.flZoomFoVMax, self.flZoomFoVMin )
	self:CallOnClient( "SetCustomZoomFoV", self.flCustomZoomFoV )
end

sound.Add {
	name = "AWM_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^AWMShot.wav"
}

function SWEP:Initialize() self:SetHoldType "AR2" end

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	local owner = self:GetOwner()
	self:FireBullets {
		Attacker = owner,
		Src = owner:GetShootPos(),
		Dir = self:GetAimVector(),
		Tracer = 1,
		Spread = Vector( self.Primary_flSpreadX, self.Primary_flSpreadY ),
		Damage = self.Primary_flDamage
	}
	self:ShootEffects()
	owner:SetAnimation( PLAYER_ATTACK1 )
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( 1 )
	ed:SetFlags( 1 )
	util.Effect( "MuzzleFlash", ed )
	self:EmitSound "AWM_Shot"
	self:TakePrimaryAmmo( 1 )
	// self:SetNextPrimaryFire( CurTime() + self:SequenceDuration() ) // Bolt-action
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end

list.Add( "NPCUsableWeapons", { class = "AWM", title = "#AWM", category = SWEP.Category } )
