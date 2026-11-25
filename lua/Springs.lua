// Credits to Modern Wokefare for da technology

local sqrt = math.sqrt
local exp = math.exp
local sin = math.sin
local cos = math.cos

function CreateImportantSpring( flStiffness, flDamping )
	local flCurrentX, flCurrentY, flCurrentZ = 0, 0, 0
	local flTargetX, flTargetY, flTargetZ = 0, 0, 0
	local flVelocityX, flVelocityY, flVelocityZ = 0, 0, 0

	flStiffness = flStiffness || 1
	flDamping = flDamping || 1

	local flOmega = sqrt( flStiffness )

	local function SolveAxis( flPos, flVel, flTarget, flDt )
		local flOffset = flPos - flTarget
		local flDampRatio = flDamping * .5

		if flDampRatio < 1 then
			local flOmegaD = flOmega * sqrt( 1 - flDampRatio * flDampRatio )
			local flExp = exp( -flDampRatio * flOmega * flDt )
			local flCos = cos( flOmegaD * flDt )
			local flSin = sin( flOmegaD * flDt )

			local flC1 = flOffset
			local flC2 = ( flVel + flDampRatio * flOmega * flOffset ) / flOmegaD

			local flNewPos = flTarget + flExp * ( flC1 * flCos + flC2 * flSin )
			local flNewVel = flExp * ( ( flC2 * flOmegaD - flC1 * flDampRatio * flOmega ) * flCos - ( flC1 * flOmegaD + flC2 * flDampRatio * flOmega ) * flSin )
			return flNewPos, flNewVel

		elseif flDampRatio == 1 then
			local flExp = exp( -flOmega * flDt )
			local flC1 = flOffset
			local flC2 = flVel + flOmega * flOffset

			local flNewPos = flTarget + flExp * ( flC1 + flC2 * flDt )
			local flNewVel = flExp * ( flC2 - flOmega * ( flC1 + flC2 * flDt ) )
			return flNewPos, flNewVel

		else
			local flS = sqrt( flDampRatio * flDampRatio - 1 )
			local flR1 = -flOmega * ( flDampRatio - flS )
			local flR2 = -flOmega * ( flDampRatio + flS )

			local flC2 = ( flVel - flR1 * flOffset ) / ( flR2 - flR1 )
			local flC1 = flOffset - flC2

			local flExp1 = exp( flR1 * flDt )
			local flExp2 = exp( flR2 * flDt )

			local flNewPos = flTarget + flC1 * flExp1 + flC2 * flExp2
			local flNewVel = flC1 * flR1 * flExp1 + flC2 * flR2 * flExp2

			return flNewPos, flNewVel
		end
	end

	return {
		SetTarget = function( flX, flY, flZ )
			flTargetX = flX
			flTargetY = flY
			flTargetZ = flZ
		end,

		SetStiffness = function( flNew )
			flStiffness = flNew
			flOmega = sqrt( flNew )
		end,

		SetDamping = function( flNew ) flDamping = flNew end,

		Unpack = function() return flCurrentX, flCurrentY, flCurrentZ end,

		Decay = function( flFrameTime )
			flCurrentX, flVelocityX = SolveAxis( flCurrentX, flVelocityX, flTargetX, flFrameTime )
			flCurrentY, flVelocityY = SolveAxis( flCurrentY, flVelocityY, flTargetY, flFrameTime )
			flCurrentZ, flVelocityZ = SolveAxis( flCurrentZ, flVelocityZ, flTargetZ, flFrameTime )
		end
	}
end
