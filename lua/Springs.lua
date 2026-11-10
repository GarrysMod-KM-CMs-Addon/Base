local exp = math.exp

function CreateImportantSpring( flStiffness, flDamping )
	local flCurrentX, flCurrentY, flCurrentZ = 0, 0, 0
	local flTargetX, flTargetY, flTargetZ = 0, 0, 0
	local flVelocityX, flVelocityY, flVelocityZ = 0, 0, 0

	flStiffness = flStiffness || 1
	flDamping = flDamping || 1

	return {
		SetTarget = function( flX, flY, flZ )
			flTargetX = flX
			flTargetY = flY
			flTargetZ = flZ
		end,

		// Not sure if we'll ever need these
		//	SetStiffness = function( flNew ) flStiffness = flNew end,
		//	SetDamping = function( flNew ) flDamping = flNew end,

		Unpack = function()
			return flCurrentX, flCurrentY, flCurrentZ
		end,

		Decay = function( flFrameTime )
			flVelocityX = flVelocityX + ( flTargetX - flCurrentX ) * flStiffness * flFrameTime
			flVelocityY = flVelocityY + ( flTargetY - flCurrentY ) * flStiffness * flFrameTime
			flVelocityZ = flVelocityZ + ( flTargetZ - flCurrentZ ) * flStiffness * flFrameTime

			local flExpDamp = exp( -flDamping * flFrameTime )
			flVelocityX = flVelocityX * flExpDamp
			flVelocityY = flVelocityY * flExpDamp
			flVelocityZ = flVelocityZ * flExpDamp

			flCurrentX = flCurrentX + flVelocityX * flFrameTime
			flCurrentY = flCurrentY + flVelocityY * flFrameTime
			flCurrentZ = flCurrentZ + flVelocityZ * flFrameTime
		end
	}
end
