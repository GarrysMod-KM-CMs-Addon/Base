/*
WeaponTemplate_t {
	Attachment -> Any

	BarrelVector -> Vector
	BarrelAngle -> Angle

	SpreadX -> Number
	SpreadY -> Number

	GDelay -> Number

	Sound -> Sound
	SoundAuto -> Sound, CHAN_AUTO

	Damage -> Number

	IsAutomatic
}
*/

local vSpread = Vector()
local tBullet = { Spread = vSpread }
local EffectData = EffectData

local CEntity = FindMetaTable "Entity"
local CEntity_FireBullets = CEntity.FireBullets
local CEntity_EmitSound = CEntity.EmitSound

function FireWeapon( pEntity, sTemplate, TEMPLATE )
	local tWeaponData = pEntity.WEAPON_DATA_INTERNAL
	if !tWeaponData then
		tWeaponData = {}
		pEntity.WEAPON_DATA_INTERNAL = tWeaponData
	end

	local tData = tWeaponData[ sTemplate ]
	if !tData then
		tData = {}
		tWeaponData[ sTemplate ] = tData
	end

	if CurTime() <= ( tData.flNext || 0 ) then return end

	local flDelay = TEMPLATE.Delay( pEntity, TEMPLATE )
	tData.flNext = CurTime() + flDelay

	local dShoot = TEMPLATE.BarrelDirection( pEntity, TEMPLATE )
	local vShoot = TEMPLATE.BarrelVector( pEntity, TEMPLATE )

	if !TEMPLATE.HasMuzzleFlashEffect || TEMPLATE.HasMuzzleFlashEffect( pEntity, TEMPLATE ) then
		local pEffectData = EffectData()

		pEffectData:SetEntity( pEntity )
		pEffectData:SetMaterialIndex( 0 )
	
		pEffectData:SetOrigin( vShoot )
		pEffectData:SetStart( vShoot )
		pEffectData:SetNormal( dShoot )
		pEffectData:SetAngles( dShoot:Angle() )
		pEffectData:SetMagnitude( 1 / ( flDelay * math.Rand( .75, 1.25 ) ) )

		util.Effect( TEMPLATE.MuzzleFlashEffect && TEMPLATE.MuzzleFlashEffect( pEntity, TEMPLATE ) || "MuzzleFlashGeneric", pEffectData )
	end

	vSpread[ 1 ] = TEMPLATE.SpreadX && TEMPLATE.SpreadX( pEntity, TEMPLATE ) || 0
	vSpread[ 2 ] = TEMPLATE.SpreadY && TEMPLATE.SpreadY( pEntity, TEMPLATE ) || 0

	tBullet.Attacker = pEntity
	tBullet.Src = vShoot
	tBullet.Dir = dShoot
	tBullet.Damage = TEMPLATE.Damage && TEMPLATE.Damage( pEntity, TEMPLATE ) || 0

	CEntity_FireBullets( pEntity, tBullet )

	local sSound = TEMPLATE.Sound && TEMPLATE.Sound( pEntity, TEMPLATE )
	if sSound then pEntity:EmitSound( sSound ) end

	sSound = TEMPLATE.SoundAuto && TEMPLATE.SoundAuto( pEntity, TEMPLATE )
	if sSound then pEntity:EmitSound( sSound ) end
end
