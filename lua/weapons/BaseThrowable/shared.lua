DEFINE_BASECLASS "BaseWeapon"

weapons.Register( SWEP, "BaseThrowable" )

SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = true
SWEP.bPistolSprint = true
SWEP.Slot = 4

SWEP.Crosshair = "Special"

SWEP.__GRENADE__ = true
SWEP.GRENADE_flMinimumTime = 1
SWEP.GRENADE_flMaximumTime = 1

SWEP.Instructions = "Primary to pull the pin, and then again to throw."

local CEntity, CWeapon = FindMetaTable "Entity", FindMetaTable "Weapon"

local CEntity_GetTable = CEntity.GetTable
local CEntity_GetClass = CEntity.GetClass
local CWeapon_SetHoldType = CWeapon.SetHoldType
local CWeapon_SetClip1 = CWeapon.SetClip1

function SWEP:Initialize()
	CWeapon_SetHoldType( self, "Grenade" )
	CWeapon_SetClip1( self, 1 )
end

local math_max = math.max

function SWEP:Equip( pOwner )
	local MyTable = CEntity_GetTable( self )
	MyTable.m_pLastOwner = pOwner
	local pOwnerTable = CEntity_GetTable( pOwner )
	local tGrenades = pOwnerTable.GAME_tGrenades || {}
	local sClass = CEntity_GetClass( self )
	local f = math_max( ( tGrenades[ sClass ] || 0 ) + 1, 0 )
	tGrenades[ sClass ] = f
	CWeapon_SetClip1( self, f ) // Fool the ammo drawing systems of BaseWeapon into thinking we have this much ammo
	self:CallOnClient( "SetPrimaryClipSize", f )
	pOwner.GAME_tGrenades = tGrenades
end

local IsValid = IsValid

function SWEP:EquipAmmo( pOwner )
	local MyTable = CEntity_GetTable( self )
	MyTable.m_pLastOwner = pOwner
	local pOwnerTable = CEntity_GetTable( pOwner )
	local tGrenades = pOwnerTable.GAME_tGrenades || {}
	local sClass = CEntity_GetClass( self )
	local f = math_max( ( tGrenades[ sClass ] || 0 ) + 1, 0 )
	tGrenades[ sClass ] = f
	pOwner.GAME_tGrenades = tGrenades
	local p = pOwner:GetWeapon( sClass )
	if IsValid( p ) then
		p.bPinPulled = MyTable.bPinPulled
		CWeapon_SetClip1( p, f )
		p:CallOnClient( "SetPrimaryClipSize", f )
	end
end

local CEntity_GetOwner = CEntity.GetOwner

function SWEP:SetPrimaryClipSize( f ) self.Primary.ClipSize = f end

local CEntity_Remove = CEntity.Remove
function SWEP:Detonate() CEntity_Remove( self ) end

local CurTime = CurTime

local math_Rand = math.Rand

local sound_EmitHint = sound.EmitHint
local CEntity_GetPos = CEntity.GetPos
local CEntity_OBBCenter = CEntity.OBBCenter

if SERVER then
	local SOUND_BASE_THROWABLE = SOUND_DANGER + SOUND_CONTEXT_EXPLOSION + SOUND_CONTEXT_REACT_TO_SOURCE

	function SWEP:GAME_Think()
		local MyTable = CEntity_GetTable( self )
		local f = MyTable.GRENADE_flTime
		if f && CurTime() > f then MyTable.Detonate( self, MyTable ) return end
		if MyTable.bPinPulled then
			local flRadius = MyTable.GRENADE_flRadius
			if flRadius then
				sound_EmitHint( SOUND_BASE_THROWABLE, CEntity_GetPos( self ) + CEntity_OBBCenter( self ), flRadius * 1.25, .1, self )
			end
		end
		local pOwner = CEntity_GetOwner( self )
		if !IsValid( pOwner ) then return end
		local f = math_max( ( ( CEntity_GetTable( pOwner ).GAME_tGrenades || {} )[ CEntity_GetClass( self ) ] || 0 ), 0 )
		CWeapon_SetClip1( self, f )
		self:CallOnClient( "SetPrimaryClipSize", f )
	end
end

function SWEP:Reload() end

local timer_Simple = timer.Simple

function SWEP:OnDrop()
	local pOwner = CEntity_GetTable( self ).m_pLastOwner
	if !IsValid( pOwner ) then return end
	local pOwnerTable = CEntity_GetTable( pOwner )
	local tGrenades = pOwnerTable.GAME_tGrenades || {}
	local sClass = CEntity_GetClass( self )
	local f = math_max( ( tGrenades[ sClass ] || 1 ) - 1, 0 )
	tGrenades[ sClass ] = f
	pOwner.GAME_tGrenades = tGrenades
	CWeapon_SetClip1( self, 0 )
	self:CallOnClient( "SetPrimaryClipSize", 0 )
	// Aren't completely out of grenades of this type yet
	if f > 0 then
		timer_Simple( .1, function()
			if !IsValid( pOwner ) then return end
			local p = pOwner:Give( sClass )
			if !IsValid( p ) then return end
			// Compensate for Equip giving one grenade when picked up
			local f = math_max( ( tGrenades[ sClass ] || 1 ) - 1, 0 )
			tGrenades[ sClass ] = f
			pOwner.GAME_tGrenades = tGrenades
		end )
	end
end

SWEP.aPullPin = ACT_VM_PULLPIN

local ACT_VM_THROW = ACT_VM_THROW
local PLAYER_ATTACK1 = PLAYER_ATTACK1
local engine_TickCount = engine.TickCount

SWEP.flAnimation = 0
SWEP.flLastPinPull = 0
function SWEP:PrimaryAttack()
	local MyTable = CEntity_GetTable( self )
	if CurTime() <= MyTable.flAnimation then return end
	if MyTable.bPinPulled then
		self:SendWeaponAnim( ACT_VM_THROW )
		local pOwner = CEntity_GetOwner( self )
		if IsValid( pOwner ) then
			local f = pOwner.SetAnimation
			if f then f( pOwner, PLAYER_ATTACK1 ) end
		end
		local f = self:SequenceDuration()
		MyTable.flAnimation = CurTime() + f + engine_TickCount()
		MyTable.flThrowAnimation = CurTime() + f
		MyTable.GRENADE_flTime = MyTable.GRENADE_flTime + f
		return
	end
	MyTable.bPinPulled = true
	self:SendWeaponAnim( MyTable.aPullPin )
	local f = self:SequenceDuration()
	MyTable.flAnimation = CurTime() + f
	MyTable.flLastPinPull = CurTime() + f
	MyTable.GRENADE_flTime = CurTime() + f + math_Rand( MyTable.GRENADE_flMinimumTime, MyTable.GRENADE_flMaximumTime )
end

if !SERVER then return end

local CEntity_SetPos = CEntity.SetPos

function SWEP:Think()
	local MyTable = CEntity_GetTable( self )
	local f = MyTable.flThrowAnimation
	if f && CurTime() > f then
		self:SendWeaponAnim( ACT_VM_DRAW )
		MyTable.flAnimation = CurTime() + self:SequenceDuration()
		MyTable.flThrowAnimation = nil
		local pOwner = CEntity_GetOwner( self )
		if !IsValid( pOwner ) then return end
		local pOwnerTable = CEntity_GetTable( pOwner )
		local tGrenades = pOwnerTable.GAME_tGrenades || {}
		local sClass = CEntity_GetClass( self )
		local f = math_max( ( tGrenades[ sClass ] || 1 ) - 1, 0 )
		tGrenades[ sClass ] = f
		pOwner.GAME_tGrenades = tGrenades
		CWeapon_SetClip1( self, f )
		self:CallOnClient( "SetPrimaryClipSize", f )
		pOwner:DropWeapon( self )
		CEntity_SetPos( self, pOwner:EyePos() )
		local vDirection = pOwner:GetAimVector()
		local flForce = pOwnerTable.GAME_flThrowForce || 1024
		timer_Simple( .1, function()
			if !IsValid( self ) then return end
			local pPhys = self:GetPhysicsObject()
			if !IsValid( pPhys ) then CEntity_Remove( self ) return end
			if IsValid( pOwner ) then
				pPhys:AddVelocity( pOwner:GetAimVector() * ( pOwnerTable.GAME_flThrowForce || 1024 ) )
				if f <= 0 then return end
				local p = pOwner:Give( sClass )
				if !IsValid( p ) then return end
				// Compensate for Equip giving one grenade when picked up
				local f = math_max( ( tGrenades[ sClass ] || 1 ) - 1, 0 )
				tGrenades[ sClass ] = f
				pOwner.GAME_tGrenades = tGrenades
			else
				pPhys:AddVelocity( vDirection * flForce )
			end
		end )
	end
end
