// Neither of us actually worked together, it's just that we took each other's stuff
// Credits:
// - Ubisoft Montreal for the model animations, they're from Far Cry 3
// - Buu342 for ripping the animations
// - Buu342 for writing the original code (see https://steamcommunity.com/sharedfiles/filedetails/?id=271689250)
// - KM_CM (me) for completely rewriting the code based on Buu342's version

DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Hands"
SWEP.PrintName = "#Hands"
SWEP.Instructions = ""
SWEP.Purpose = ""
SWEP.ViewModel = Model "models/weapons/c_realhands.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = -1
SWEP.Slot = 0
SWEP.DrawAmmo = false
SWEP.Crosshair = ""
SWEP.ViewModelFOV = 64
SWEP.bSprintNotAnimated = true
SWEP.bCoverNotAnimated = true
SWEP.bJumpingNotAnimated = true
SWEP.bPlayingJump = true

function SWEP:Reload() end

local language_GetPhrase = CLIENT && language.GetPhrase
local table_Random = table.Random
local table_insert = table.insert

function SWEP:Initialize()
	if CLIENT then
		local tMessages = {}
		local iCurrent = 0
		while true do
			iCurrent = iCurrent + 1
			local sLocalization = "Tip_Walking" .. tostring( iCurrent )
			local sPhrase = language_GetPhrase( sLocalization )
			if sLocalization == sPhrase then break end
			table_insert( tMessages, sPhrase )
		end
		self.Instructions = "TIP: " .. ( table_Random( tMessages ) || "ERROR" )
	end
	self:SetHoldType "Normal"
end

function SWEP:Deploy()
	local pOwner = self:GetOwner()
	if IsValid( pOwner ) && pOwner:IsPlayer() then pOwner:GetViewModel():SetPlaybackRate( 1 ) end
	self:SendWeaponAnim( ACT_VM_IDLE )
	self.bPlayingJump = nil
	self.bPlayingSprint = nil
	self.bPlayingCover = nil
end

local CEntity_Remove = FindMetaTable( "Entity" ).Remove

function SWEP:OnDrop() CEntity_Remove( self ) end

function SWEP:GetCapabilities() return 0 end

function SWEP:Think()
	local pOwner = self:GetOwner()
	if !IsValid( pOwner ) || !pOwner:IsPlayer() then return end
	if pOwner:GetNW2Bool "CTRL_bSliding" then
		self.bPlayingJump = nil
		self.bPlayingSprint = nil
		self.bPlayingCover = nil
		pOwner:GetViewModel():SetPlaybackRate( 1 )
		self:SendWeaponAnim( ACT_VM_IDLE )
		return
	end
	if pOwner:GetNW2Bool "CTRL_bInCover" && !pOwner:GetNW2Bool "CTRL_bGunUsesCoverStance" then
		if !self.bPlayingCover then
			pOwner:GetViewModel():SetPlaybackRate( 1 )
			self:SendWeaponAnim( ACT_VM_LOWERED_TO_IDLE )
			self.bPlayingCover = true
			self.bPlayingSprint = nil
		end
		return
	else
		if self.bPlayingCover then
			pOwner:GetViewModel():SetPlaybackRate( 1 )
			self:SendWeaponAnim( ACT_VM_IDLE_TO_LOWERED )
			self.bPlayingCover = nil
			self.bPlayingSprint = nil
			return
		end
	end
	local bGround = pOwner:OnGround()
	if !bGround then
		if !self.bPlayingJump then
			pOwner:GetViewModel():SetPlaybackRate( 1 )
			self:SendWeaponAnim( ACT_VM_DRAW )
			self.bPlayingJump = true
			self.bPlayingSprint = nil
			self.bPlayingCover = nil
		end
		return
	else self.bPlayingJump = nil end
	local flSpeed = pOwner:GetVelocity():Length()
	if bGround && flSpeed > ( pOwner:GetWalkSpeed() * .9 ) then
		pOwner:GetViewModel():SetPlaybackRate( math.Clamp( math.Remap( flSpeed, pOwner:GetWalkSpeed(), pOwner:GetRunSpeed(), 1, 1.25 ), 1, 1.25 ) )
		if !self.bPlayingSprint then
			self:SendWeaponAnim( ACT_VM_SWINGHARD )
			self.bPlayingSprint = true
		end
	elseif self.bPlayingSprint then
		pOwner:GetViewModel():SetPlaybackRate( 1 )
		self:SendWeaponAnim( ACT_VM_IDLE )
		self.bPlayingSprint = nil
	end
end
