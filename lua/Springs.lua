local sqrt = math.sqrt

function CreateImportantSpring( flStiffness, flDamping )
	local flCurrentX, flCurrentY, flCurrentZ = 0, 0, 0
	local flTargetX, flTargetY, flTargetZ = 0, 0, 0
	local flVelocityX, flVelocityY, flVelocityZ = 0, 0, 0

	flStiffness = flStiffness || 1
	flDamping = flDamping || 1

	local flSqrt = sqrt( flStiffness )

	return {
		SetTarget = function( flX, flY, flZ )
			flTargetX = flX
			flTargetY = flY
			flTargetZ = flZ
		end,

		// Not sure if we'll ever need these
		SetStiffness = function( flNew )
			flStiffness = flNew
			flSqrt = sqrt( flNew )
		end,

		SetDamping = function( flNew ) flDamping = flNew end,

		Unpack = function()
			return flCurrentX, flCurrentY, flCurrentZ
		end,

		Decay = function( flFrameTime )
			local flForceX = ( flTargetX - flCurrentX ) * flStiffness + ( -flVelocityX * flDamping ) * flSqrt
			local flForceY = ( flTargetY - flCurrentY ) * flStiffness + ( -flVelocityY * flDamping ) * flSqrt
			local flForceZ = ( flTargetZ - flCurrentZ ) * flStiffness + ( -flVelocityZ * flDamping ) * flSqrt

			flVelocityX = flVelocityX + ( flForceX * flFrameTime )
			flVelocityY = flVelocityY + ( flForceY * flFrameTime )
			flVelocityZ = flVelocityZ + ( flForceZ * flFrameTime )

			flCurrentX = flCurrentX + ( flVelocityX * flFrameTime )
			flCurrentY = flCurrentY + ( flVelocityY * flFrameTime )
			flCurrentZ = flCurrentZ + ( flVelocityZ * flFrameTime )
		end
	}
end
