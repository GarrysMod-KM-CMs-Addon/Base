// See Hands.lua for the credits!

DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Hands"
SWEP.PrintName = "#Hands"
SWEP.Instructions = ""
SWEP.Purpose = ""
SWEP.ViewModel = Model "models/weapons/c_swim.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model ""
SWEP.AdminOnly = false
SWEP.Weight = -1
SWEP.Slot = 0
SWEP.DrawAmmo = false
SWEP.Crosshair = ""
SWEP.ViewModelFOV = 64
SWEP.bCoverNotAnimated = true
SWEP.bJumpingNotAnimated = true
SWEP.flSwim = 0

sound.Add {
	name = "Hands_UnderwaterLoop",
	sound = "ambient/water/underwater.wav",
	level = 0,
	volume = 1,
	channel = CHAN_STATIC
}

sound.Add {
	name = "Hands_SwimHit",
	sound = {
		"player/footsteps/wade1.wav",
		"player/footsteps/wade2.wav",
		"player/footsteps/wade3.wav",
		"player/footsteps/wade4.wav",
		"player/footsteps/wade5.wav",
		"player/footsteps/wade6.wav"
	},
	level = 60,
	volume = 1,
	channel = CHAN_STATIC
}

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
			local sLocalization = "Tip_Swimming" .. tostring( iCurrent )
			local sPhrase = language_GetPhrase( sLocalization )
			if sLocalization == sPhrase then break end
			table_insert( tMessages, sPhrase )
		end
		self.Instructions = "TIP: " .. ( table_Random( tMessages ) || "ERROR" )
	end
	self:SetHoldType "Normal"
end

function SWEP:Deploy() self:Think() end

function SWEP:OnRemove()
	local pWaterLoop = self.pWaterLoop
	if pWaterLoop then pWaterLoop:Stop() end
end

local CEntity_Remove = FindMetaTable( "Entity" ).Remove

function SWEP:OnDrop() CEntity_Remove( self ) end

function SWEP:GetCapabilities() return 0 end

if !SERVER then return end

local ACT_VM_HITCENTER = ACT_VM_HITCENTER
local ACT_VM_HITLEFT = ACT_VM_HITLEFT
local ACT_VM_HITRIGHT = ACT_VM_HITRIGHT
local ACT_VM_HITCENTER2 = ACT_VM_HITCENTER2

local IN_SPEED = IN_SPEED
local IN_FORWARD = IN_FORWARD
local IN_MOVELEFT = IN_MOVELEFT
local IN_MOVERIGHT = IN_MOVERIGHT
local IN_BACK = IN_BACK

local IsValid = IsValid
local timer_Simple = timer.Simple

function SWEP:Think()
	local pOwner = self:GetOwner()
	if !IsValid( pOwner ) || !pOwner:IsPlayer() then return end
	local pWaterLoop = self.pWaterLoop
	if pOwner:WaterLevel() > 2 then
		if !pWaterLoop then
			local pFilter = RecipientFilter()
			pFilter:AddPlayer( pOwner )
			pWaterLoop = CreateSound( self, "Hands_UnderwaterLoop", pFilter )
			pWaterLoop:Play()
			self.pWaterLoop = pWaterLoop
		end
	elseif pWaterLoop then pWaterLoop:Stop() self.pWaterLoop = nil end
	if CurTime() > self.flSwim then
		local pViewModel = pOwner:GetViewModel()
		local bSprinting = pOwner:KeyDown( IN_FORWARD ) && pOwner:KeyDown( IN_SPEED ) && !pOwner:Crouching()
		pViewModel:SetPlaybackRate( bSprinting && 2 || 1 )
		if bSprinting then
			self:SendWeaponAnim( ACT_VM_HITCENTER )
			timer_Simple( .15, function() if IsValid( pOwner ) then pOwner:ViewPunch( Angle( -5, 0, 0 ) ) pOwner:EmitSound "Hands_SwimHit" end end )
		elseif pOwner:KeyDown( IN_MOVELEFT ) then
			self:SendWeaponAnim( ACT_VM_HITLEFT )
			timer_Simple( .33, function() if IsValid( pOwner ) then pOwner:ViewPunch( Angle( 0, -5, 0 ) ) pOwner:EmitSound "Hands_SwimHit" end end )
			timer_Simple( .8, function() if IsValid( pOwner ) then pOwner:ViewPunch( Angle( 0, -5, 0 ) ) pOwner:EmitSound "Hands_SwimHit" end end )
		elseif pOwner:KeyDown( IN_MOVERIGHT ) then
			self:SendWeaponAnim( ACT_VM_HITRIGHT )
			timer_Simple( .33, function() if IsValid( pOwner ) then pOwner:ViewPunch( Angle( 0, 5, 0 ) ) pOwner:EmitSound "Hands_SwimHit" end end )
			timer_Simple( .8, function() if IsValid( pOwner ) then pOwner:ViewPunch( Angle( 0, 5, 0 ) ) pOwner:EmitSound "Hands_SwimHit" end end )
		elseif pOwner:KeyDown( IN_FORWARD ) then
			self:SendWeaponAnim( ACT_VM_HITCENTER )
			timer_Simple( .3, function() if IsValid( pOwner ) then pOwner:ViewPunch( Angle( -5, 0, 0 ) ) pOwner:EmitSound "Hands_SwimHit" end end )
		elseif pOwner:KeyDown( IN_BACK ) then
			self:SendWeaponAnim( ACT_VM_HITCENTER2 )
			timer_Simple( .20, function() if IsValid( pOwner ) then pOwner:ViewPunch( Angle( 5, 0, 0 ) ) pOwner:EmitSound "Hands_SwimHit" end end )
		end
		if bSprinting then
			self.flSwim = CurTime() + self:SequenceDuration()
		else self.flSwim = CurTime() + self:SequenceDuration() + .5 end
	end
end
