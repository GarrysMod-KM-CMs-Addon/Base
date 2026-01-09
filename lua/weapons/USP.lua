DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Pistols"
SWEP.PrintName = "#USP"

SWEP.Instructions = "Primary to shoot, secondary to attach or detach the silencer."
SWEP.Purpose = "Universal Self-Loading Pistol, with a Silencer."
SWEP.ViewModel = Model "models/weapons/cstrike/c_pist_usp.mdl"
SWEP.UseHands = true
local WORLDMODEL = Model "models/weapons/w_pist_usp.mdl"
local WORLDMODEL_SILENCED = Model "models/weapons/w_pist_usp_silencer.mdl"
SWEP.WorldModel = WORLDMODEL
SWEP.Primary.ClipSize = 15
SWEP.Primary.DefaultClip = 15
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Pistol"
SWEP.Primary_flSpreadX = .0094
SWEP.Primary_flSpreadY = .0094
SWEP.Primary_flDamage = 80
SWEP.Primary_flDelay = .08571428571
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 1
SWEP.CSMuzzleFlashes = true
SWEP.vViewModelAim = Vector( -12, -5.905, 2.6 )
SWEP.Crosshair = "Pistol"
SWEP.sAimSound = "BaseWeapon_Aim_Pistol"
SWEP.bPistolSprint = true
SWEP.flRecoil = 1.6
SWEP.flSideWaysRecoilMin = -.28
SWEP.flSideWaysRecoilMax = .28
SWEP.flRecoilGrowMin = -.5
SWEP.flRecoilGrowMax = -.9

sound.Add {
	name = "USP_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^HKP2000Shot.wav"
}

function SWEP:Initialize()
	self:SetHoldType "Pistol"
	if self.bSilenced then
		self.WorldModel = WORLDMODEL_SILENCED
	else
		self.WorldModel = WORLDMODEL
	end
end

function SWEP:Deploy() self:BaseWeaponDraw( self.bSilenced && ACT_VM_DRAW_SILENCED || ACT_VM_DRAW ) end

function SWEP:Holster()
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
	// self:SendWeaponAnim( self.bSilenced && ACT_VM_PRIMARYATTACK_SILENCED || ACT_VM_PRIMARYATTACK )
	if owner.GetViewModel then
		local vm = owner:GetViewModel()
		if IsValid( vm ) then vm:SendViewModelMatchingSequence( vm:LookupSequence( self.bSilenced && "shoot1" || "shoot1_unsil" ) ) end
	end
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( 1 )
	ed:SetFlags( 1 )
	util.Effect( "MuzzleFlash", ed )
	self:DoRecoil()
	self:EmitSound( self.bSilenced && "SilencedShot" || "USP_Shot" )
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

list.Add( "NPCUsableWeapons", { class = "USP", title = "#USP", category = SWEP.Category } )
