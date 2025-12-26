DEFINE_BASECLASS "BaseWeapon"

SWEP.Crosshair = "Open"
SWEP.sHoldType = "RPG"

SWEP.Primary_flSpreadX = 0
SWEP.Primary_flSpreadY = 0
SWEP.Primary_sProjectile = ""

SWEP.Instructions = "Primary to shoot."

local CEntity, CWeapon = FindMetaTable "Entity", FindMetaTable "Weapon"

local CEntity_GetTable = CEntity.GetTable
local CEntity_GetOwner = CEntity.GetOwner
local CEntity_EmitSound = CEntity.EmitSound
local CWeapon_SetHoldType = CWeapon.SetHoldType
local CWeapon_SetNextPrimaryFire = CWeapon.SetNextPrimaryFire
local Vector = Vector
local PLAYER_ATTACK1 = PLAYER_ATTACK1
local EffectData = EffectData
local util_Effect = util.Effect
local CurTime = CurTime

function SWEP:Initialize() CWeapon_SetHoldType( self, CEntity_GetTable( self ).sHoldType ) end

function SWEP:DoMuzzleFlash()
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( 1 )
	ed:SetFlags( 1 )
	util_Effect( "MuzzleFlash", ed )
end

local ents_Create = ents.Create
local math_Rand = math.Rand
function SWEP:PrimaryAttack()
	local MyTable = CEntity_GetTable( self )
	if !MyTable.CanPrimaryAttack( self, MyTable ) then return end
	local pOwner = CEntity_GetOwner( self )
	local pProjectile = ents_Create( MyTable.Primary_sProjectile )
	if IsValid( pOwner ) then
		pProjectile:SetOwner( pOwner )
		pProjectile:SetPos( pOwner:GetShootPos() )
		pOwner:SetAnimation( PLAYER_ATTACK1 )
	else
		pProjectile:SetOwner( self )
		pProjectile:SetPos( self:GetPos() + self:OBBCenter() )
	end
	local flX = math_Rand( -.5, .5 ) + math_Rand( -.5, .5 )
	local flY = math_Rand( -.5, .5 ) + math_Rand( -.5, .5 )
	local aAim = MyTable.GetAimVector( self, MyTable ):Angle()
	pProjectile:SetAngles( ( aAim:Forward() + flX * MyTable.Primary_flSpreadX * aAim:Right() + flY * MyTable.Primary_flSpreadY * aAim:Up() ):Angle() )
	pProjectile:Spawn()
	MyTable.ShootEffects( self, MyTable )
	local s = MyTable.sSound
	if s then CEntity_EmitSound( self, s ) end
	s = MyTable.sSoundAuto
	if s then CEntity_EmitSound( self, s ) end
	MyTable.TakePrimaryAmmo( self, 1 )
	CWeapon_SetNextPrimaryFire( self, CurTime() + MyTable.Primary_flDelay )
end

weapons.Register( SWEP, "BaseProjectileWeapon" )
