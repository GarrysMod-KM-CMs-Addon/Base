local SPEED_OF_SOUND = 13720

hook.Add( "EntityEmitSound", "GameImprovements", function( Data, _Comp )
	local pPlayer = LocalPlayer()
	if !IsValid( pPlayer ) then Data.Volume = 0 return nil end
	if _Comp then
		if _Comp.KM_CMs_Addon then
			return
		else _Comp.KM_CMs_Addon = true end
	end
	local pEntity = Data.Entity
	if !pEntity.SND_bActualSound then return true end
	pEntity.SND_bActualSound = nil
	Data.SoundTime = pEntity.SND_flSoundTime
	local vPos = pEntity.SND_vPos
	Data.Volume = pEntity.SND_flVolume * math.max( 0, 1 - vPos:Distance( EyePos() ) / pEntity.SND_flDistance )
	local vMyVelocity, vTheirVelocity = GetVelocity( pPlayer ), pEntity.SND_vVelocity
	local vDelta = vMyVelocity - vTheirVelocity
	local dTheirVelocity = vTheirVelocity:GetNormalized()
	local flRelativeSpeed = ( vTheirVelocity - vMyVelocity ):Dot( ( EyePos() - vPos ):GetNormalized() )
	local f = math.abs( flRelativeSpeed )
	if f >= SPEED_OF_SOUND then Data.Volume = 0 return nil end
	Data.Pitch = Data.Pitch * ( SPEED_OF_SOUND / ( SPEED_OF_SOUND + flRelativeSpeed ) )
	hook.Run( "EntityEmitSound", Data, { KM_CMs_Addon = true } )
	return true
end )

net.Receive( "EmitSound", function()
	local SoundName = net.ReadString()
	local SoundTime = net.ReadFloat()
	local flDistance = net.ReadFloat()
	local Pitch = net.ReadUInt( 8 )
	local Flags = net.ReadUInt( 32 )
	local Channel = net.ReadUInt( 8 )
	local Volume = net.ReadFloat()
	local vPos = net.ReadVector()
	local vVelocity = net.ReadVector()
	local pEntity = net.ReadEntity()
	if !IsValid( pEntity ) then
		// TODO: Use the global EmitSound
		return
	end
	local f = vPos:Distance( EyePos() )
	pEntity.SND_flDistance = flDistance
	if f < 2048 then
		pEntity.SND_bActualSound = true
		pEntity.SND_flSoundTime = SoundTime
		pEntity.SND_vPos = vPos
		pEntity.SND_vVelocity = vVelocity
		pEntity.SND_flVolume = Volume * .5
		pEntity:EmitSound( SoundName, 0, Pitch, pEntity.SND_flVolume, CHAN_STATIC, Flags, 1 )
		return
	end
	pEntity.SND_bActualSound = true
	pEntity.SND_flSoundTime = SoundTime
	pEntity.SND_vPos = vPos
	pEntity.SND_vVelocity = vVelocity
	f = math.Clamp( math.Remap( f, 2048, 4096, 0, 1 ), 0, 1 )
	pEntity.SND_flVolume = Volume * ( 1 - f ) * .5
	pEntity:EmitSound( SoundName, 0, Pitch, pEntity.SND_flVolume, CHAN_STATIC, Flags, 1 )
	pEntity.SND_bActualSound = true
	pEntity.SND_flVolume = Volume * f * .5
	pEntity:EmitSound( SoundName, 0, Pitch, pEntity.SND_flVolume, CHAN_STATIC, Flags, 7 )
end )
