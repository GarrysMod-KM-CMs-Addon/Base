DEFINE_BASECLASS "BaseWeapon"

weapons.Register( SWEP, "BaseThrowable" )

SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = true

SWEP.Secondary.ClipSize = 1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = true

SWEP.WPN_SPRINT = WPN_PISTOL
// SWEP.WPN_SHOOT = WPN_PISTOL
SWEP.Slot = 4

SWEP.bNoReloads = true
SWEP.bSpecial = true

SWEP.Crosshair = "Special"

SWEP.__GRENADE__ = true
SWEP.GRENADE_flMinimumTime = 1
SWEP.GRENADE_flMaximumTime = 1

SWEP.Instructions = "Pull the pin, then throw. Primary to throw far, secondary to throw close, and reload to drop."

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
	BaseClass.Equip( self, pOwner )
	local MyTable = CEntity_GetTable( self )
	local pOwnerTable = CEntity_GetTable( pOwner )
	// Actors can have multiple entities of the same class as weapons, they don't need this shit, they'll literally have two grenades
	if pOwnerTable.__ACTOR__ then return end
	local tGrenades = pOwnerTable.GAME_tItemCounts || {}
	local sClass = CEntity_GetClass( self )
	local f = math_max( ( tGrenades[ sClass ] || 0 ) + 1, 0 )
	tGrenades[ sClass ] = f
	CWeapon_SetClip1( self, f ) // Fool the ammo drawing system of BaseWeapon into thinking we have this much ammo
	self:CallOnClient( "SetPrimaryClipSize", f )
	pOwner.GAME_tItemCounts = tGrenades
end

local IsValid = IsValid

function SWEP:EquipAmmo( pOwner )
	local pOwnerTable = CEntity_GetTable( pOwner )
	if pOwnerTable.__ACTOR__ then return end
	local tGrenades = pOwnerTable.GAME_tItemCounts || {}
	local sClass = CEntity_GetClass( self )
	local f = math_max( ( tGrenades[ sClass ] || 0 ) + 1, 0 )
	tGrenades[ sClass ] = f
	pOwner.GAME_tItemCounts = tGrenades
	local p = pOwner:GetWeapon( sClass )
	if IsValid( p ) then
		p.bPinPulled = CEntity_GetTable( self ).bPinPulled
		CWeapon_SetClip1( p, f )
		p:CallOnClient( "SetPrimaryClipSize", f )
	end
end

local CEntity_GetOwner = CEntity.GetOwner

function SWEP:SetPrimaryClipSize( f ) self.Primary.ClipSize = f end

local CEntity_Remove = CEntity.Remove
function SWEP:DetonateThink() CEntity_Remove( self ) end

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
		if f && CurTime() > f then MyTable.DetonateThink( self, MyTable ) return end
		if MyTable.bPinPulled then
			local flRadius = MyTable.GRENADE_flRadius
			if flRadius then
				sound_EmitHint( SOUND_BASE_THROWABLE, CEntity_GetPos( self ) + CEntity_OBBCenter( self ), flRadius * 1.25, .1, self )
			end
		end
		local pOwner = CEntity_GetOwner( self )
		if !IsValid( pOwner ) then return end
		local f = math_max( ( ( CEntity_GetTable( pOwner ).GAME_tItemCounts || {} )[ CEntity_GetClass( self ) ] || 0 ), 0 )
		CWeapon_SetClip1( self, f )
		self:CallOnClient( "SetPrimaryClipSize", f )
	end
end

local timer_Simple = timer.Simple

function SWEP:OnDrop()
	BaseClass.OnDrop( self )
	local pOwner = CEntity_GetTable( self ).m_pLastOwner
	if !IsValid( pOwner ) then return end
	local pOwnerTable = CEntity_GetTable( pOwner )
	if pOwnerTable.__ACTOR__ then return end
	local tGrenades = pOwnerTable.GAME_tItemCounts || {}
	local sClass = CEntity_GetClass( self )
	local f = math_max( ( tGrenades[ sClass ] || 1 ) - 1, 0 )
	tGrenades[ sClass ] = f
	pOwner.GAME_tItemCounts = tGrenades
	local pOwner = self:GetOwner()
	CWeapon_SetClip1( self, 0 )
	// Aren't completely out of grenades of this type yet
	if f > 0 then
		timer_Simple( 0, function()
			if !IsValid( pOwner ) then return end
			local p = pOwner:Give( sClass )
			if !IsValid( p ) then return end
			// Compensate for Equip giving one grenade when picked up
			local f = math_max( ( tGrenades[ sClass ] || 1 ) - 1, 0 )
			tGrenades[ sClass ] = f
			pOwner.GAME_tItemCounts = tGrenades
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
		MyTable.m_flForceMultiplier = 1
		return
	end
	MyTable.bPinPulled = true
	self:SendWeaponAnim( MyTable.aPullPin )
	local f = self:SequenceDuration()
	MyTable.flAnimation = CurTime() + f
	MyTable.flLastPinPull = CurTime() + f
	MyTable.GRENADE_flTime = CurTime() + f + math_Rand( MyTable.GRENADE_flMinimumTime, MyTable.GRENADE_flMaximumTime )
end
function SWEP:SecondaryAttack()
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
		MyTable.m_flForceMultiplier = .5
		return
	end
	MyTable.bPinPulled = true
	self:SendWeaponAnim( MyTable.aPullPin )
	local f = self:SequenceDuration()
	MyTable.flAnimation = CurTime() + f
	MyTable.flLastPinPull = CurTime() + f
	MyTable.GRENADE_flTime = CurTime() + f + math_Rand( MyTable.GRENADE_flMinimumTime, MyTable.GRENADE_flMaximumTime )
end
function SWEP:Reload()
	local MyTable = CEntity_GetTable( self )
	if CurTime() <= MyTable.flAnimation then return end
	if MyTable.bAllowInstantDeploy then
		local pOwner = CEntity_GetOwner( self )
		if IsValid( pOwner ) then
			local f = pOwner.SetAnimation
			if f then f( pOwner, PLAYER_ATTACK1 ) end
		end
		MyTable.flAnimation = CurTime()
		MyTable.flThrowAnimation = CurTime()
		MyTable.GRENADE_flTime = CurTime()
		MyTable.m_flForceMultiplier = 0
		return
	end
	if MyTable.bPinPulled then
		self:SendWeaponAnim( ACT_VM_THROW )
		local pOwner = CEntity_GetOwner( self )
		if IsValid( pOwner ) then
			local f = pOwner.SetAnimation
			if f then f( pOwner, PLAYER_ATTACK1 ) end
		end
		local f = self:SequenceDuration()
		MyTable.flAnimation = CurTime() + f
		MyTable.flThrowAnimation = CurTime() + f
		MyTable.GRENADE_flTime = MyTable.GRENADE_flTime + f
		MyTable.m_flForceMultiplier = 0
		return
	end
	MyTable.bPinPulled = true
	self:SendWeaponAnim( MyTable.aPullPin )
	local f = self:SequenceDuration()
	MyTable.flAnimation = CurTime() + f
	MyTable.flLastPinPull = CurTime() + f
	MyTable.GRENADE_flTime = CurTime() + f + math_Rand( MyTable.GRENADE_flMinimumTime, MyTable.GRENADE_flMaximumTime )
end

if CLIENT then return end

SWEP.m_flForceMultiplier = 0

local CEntity_SetPos = CEntity.SetPos

function SWEP:AfterDropWeapon( pOwner, MyTable ) end

function SWEP:Think()
	BaseClass.Think( self )
	local MyTable = CEntity_GetTable( self )
	local f = MyTable.flThrowAnimation
	if f && CurTime() > f then
		self:SendWeaponAnim( ACT_VM_DRAW )
		MyTable.flAnimation = CurTime() + self:SequenceDuration()
		MyTable.flThrowAnimation = nil
		local pOwner = CEntity_GetOwner( self )
		if !IsValid( pOwner ) then return end
		local pOwnerTable = CEntity_GetTable( pOwner )
		local tGrenades = pOwnerTable.GAME_tItemCounts || {}
		local sClass = CEntity_GetClass( self )
		local f = math_max( ( tGrenades[ sClass ] || 1 ) - 1, 0 )
		tGrenades[ sClass ] = f
		pOwner.GAME_tItemCounts = tGrenades
		MyTable.Holster( self )
		self:CallOnClient "Holster"
		pOwner:DropWeapon( self )
		self:SetOwner( pOwner ) // Might be overriden, I don't know, no need to figure out as of now
		MyTable.AfterDropWeapon( self, pOwner, MyTable )
		CEntity_SetPos( self, pOwner:EyePos() )
		local vDirection = pOwner:GetAimVector()
		local flForce = ( pOwnerTable.GAME_flThrowForce || 1024 ) * MyTable.m_flForceMultiplier
		timer_Simple( 0, function()
			if !IsValid( self ) then return end
			local pPhys = self:GetPhysicsObject()
			if !IsValid( pPhys ) then CEntity_Remove( self ) return end
			if IsValid( pOwner ) then
				self:SetOwner( pOwner ) // Set the owner again just in case
				pPhys:AddVelocity( pOwner:GetAimVector() * flForce )
				if f <= 0 then return end
				local p = pOwner:Give( sClass )
				if !IsValid( p ) then return end
				// Compensate for Equip giving one grenade when picked up
				local f = math_max( ( tGrenades[ sClass ] || 1 ) - 1, 0 )
				tGrenades[ sClass ] = f
				pOwner.GAME_tItemCounts = tGrenades
			else
				pPhys:AddVelocity( vDirection * flForce )
			end
		end )
	end
end
