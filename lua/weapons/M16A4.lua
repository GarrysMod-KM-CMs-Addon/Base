DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Assault Rifles"
SWEP.PrintName = "#M16A4"
SWEP.Instructions = "Primary to shoot, secondary to attach or detach the silencer."
SWEP.Purpose = "An M16A4, with a silencer."
SWEP.ViewModel = Model "models/weapons/cstrike/c_rif_m4a1.mdl"
SWEP.UseHands = true
local WORLDMODEL = Model "models/weapons/w_rif_m4a1.mdl"
local WORLDMODEL_SILENCED = Model "models/weapons/w_rif_m4a1_silencer.mdl"
SWEP.WorldModel = WORLDMODEL
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary_flSpreadX = .0047
SWEP.Primary_flSpreadY = .0047
SWEP.Primary_flDamage = 80
SWEP.Primary_flDelay = .063
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 2
SWEP.bSilenced = false
SWEP.CSMuzzleFlashes = true
SWEP.vSprint = Vector( -3.228, 1.358, -.94 )
SWEP.Crosshair = "Rifle"

sound.Add {
	name = "M16A4_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^M16Shot.wav"
}

function SWEP:Initialize()
	self:SetHoldType "AR2"
	if self.bSilenced then
		self.WorldModel = WORLDMODEL_SILENCED
	else
		self.WorldModel = WORLDMODEL
	end
end

function SWEP:Deploy() self:SendWeaponAnim( self.bSilenced && ACT_VM_DRAW_SILENCED || ACT_VM_DRAW ) end

function SWEP:Holster()
	if self.flSilencerInterruptTime then
		if CurTime() <= self.flSilencerInterruptTime then
			self.bSilenced = !self.bSilenced
			if self.bSilenced then
				self.WorldModel = WORLDMODEL_SILENCED
			else
				self.WorldModel = WORLDMODEL
			end
		end
		self.flSilencerInterruptTime = nil
	end
	return true
end

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	if self.flSilencerInterruptTime then
		if CurTime() <= self.flSilencerInterruptTime then
			if self.bSilenced then
				self.bSilenced = nil
			else
				self.bSilenced = true
			end
			if self.bSilenced then
				self.WorldModel = WORLDMODEL_SILENCED
			else
				self.WorldModel = WORLDMODEL
			end
		end
		self.flSilencerInterruptTime = nil
	end
	local owner = self:GetOwner()
	self:FireBullets {
		Attacker = owner,
		Src = owner:GetShootPos(),
		Dir = self:GetAimVector(),
		Tracer = 1,
		Spread = Vector( self.Primary_flSpreadX, self.Primary_flSpreadY ),
		Damage = self.Primary_flDamage
	}
	owner:MuzzleFlash()
	owner:SetAnimation( PLAYER_ATTACK1 )
	self:SendWeaponAnim( self.bSilenced && ACT_VM_PRIMARYATTACK_SILENCED || ACT_VM_PRIMARYATTACK )
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( 1 )
	ed:SetFlags( 1 )
	util.Effect( "MuzzleFlash", ed )
	self:DoRecoil()
	self:EmitSound( self.bSilenced && "SilencedShot" || "M16A4_Shot" )
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end

function SWEP:SecondaryAttack()
	if self.flSilencerInterruptTime && CurTime() <= self.flSilencerInterruptTime then return end
	if self.bSilenced then
		self:SendWeaponAnim( ACT_VM_DETACH_SILENCER )
		self.flSilencerInterruptTime = CurTime() + 1
		self.WorldModel = WORLDMODEL_SILENCED
		self.bSilenced = nil
	else
		self:SendWeaponAnim( ACT_VM_ATTACH_SILENCER )
		self.flSilencerInterruptTime = CurTime() + 1
		self.WorldModel = WORLDMODEL
		self.bSilenced = true
	end
end

function SWEP:Reload()
	if self.flSilencerInterruptTime then
		if CurTime() <= self.flSilencerInterruptTime then
			if self.bSilenced then
				self.bSilenced = nil
			else
				self.bSilenced = true
			end
			if self.bSilenced then
				self.WorldModel = WORLDMODEL_SILENCED
			else
				self.WorldModel = WORLDMODEL
			end
		end
		self.flSilencerInterruptTime = nil
	end
	self:SetClip1( 0 )
	self:DefaultReload( self.bSilenced && ACT_VM_RELOAD_SILENCED || ACT_VM_RELOAD )
end

list.Add( "NPCUsableWeapons", { class = "M16A4", title = "#M16A4", category = SWEP.Category } )
