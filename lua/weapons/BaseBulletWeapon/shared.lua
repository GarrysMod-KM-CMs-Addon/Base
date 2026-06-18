DEFINE_BASECLASS "BaseWeapon"

SWEP.Crosshair = "Rifle"
SWEP.sHoldType = "AR2"

SWEP.Primary_flSpreadX = 0
SWEP.Primary_flSpreadY = 0
SWEP.Primary_flDamage = 0
SWEP.Primary_flDelay = 0
SWEP.Primary_iNum = 1
SWEP.Primary_iTracer = 1

SWEP.Instructions = "Primary to shoot."

local CEntity, CWeapon = FindMetaTable "Entity", FindMetaTable "Weapon"

local CEntity_GetTable = CEntity.GetTable
local CEntity_GetOwner = CEntity.GetOwner
local CEntity_FireBullets = CEntity.FireBullets
local CEntity_EmitSound = CEntity.EmitSound
local CWeapon_SetHoldType = CWeapon.SetHoldType
local CWeapon_SetNextPrimaryFire = CWeapon.SetNextPrimaryFire
local Vector = Vector
local PLAYER_ATTACK1 = PLAYER_ATTACK1
local EffectData = EffectData
local util_Effect = util.Effect
local CurTime = CurTime

function SWEP:Initialize() CWeapon_SetHoldType( self, CEntity_GetTable( self ).sHoldType ) end

function SWEP:FurtherModificationsToBulletTable( tBullets, MyTable ) end

function SWEP:PrimaryAttack()
	local MyTable = CEntity_GetTable( self )
	if !MyTable.CanPrimaryAttack( self, MyTable ) then return end
	local owner = CEntity_GetOwner( self )
	local tBullets = {
		Attacker = owner,
		Src = owner:GetShootPos(),
		Dir = MyTable.GetAimVector( self, MyTable ),
		Tracer = MyTable.Primary_iTracer,
		TracerName = MyTable.Primary_sTracer,
		Spread = Vector( MyTable.Primary_flSpreadX, MyTable.Primary_flSpreadY ),
		Damage = MyTable.Primary_flDamage,
		Num = MyTable.Primary_iNum,
		Force = 1
	}
	MyTable.FurtherModificationsToBulletTable( self, tBullets, MyTable )
	CEntity_FireBullets( self, tBullets )
	owner:SetAnimation( PLAYER_ATTACK1 )
	MyTable.ShootEffects( self, MyTable )
	local s = MyTable.sSound
	if s then CEntity_EmitSound( self, s ) end
	s = MyTable.sSoundAuto
	if s then CEntity_EmitSound( self, s ) end
	MyTable.TakePrimaryAmmo( self, 1 )
	MyTable.flLastShot = CurTime()
	if owner:IsPlayer() then self:CallOnClient "LastShot" end
	CWeapon_SetNextPrimaryFire( self, CurTime() + MyTable.Primary_flDelay )
end

weapons.Register( SWEP, "BaseBulletWeapon" )
