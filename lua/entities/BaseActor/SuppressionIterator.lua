local STEP = 5.625
local LIMIT = 22.5

local yield = coroutine.yield
local random = math.random

local function Iterator( flPitch, flYaw )
	yield( flPitch, flYaw )

	for flAngle = STEP, LIMIT, STEP do
		local EPattern = random( 1, 4 )

		local p1, p2, y1, y2

		if EPattern == 1 then
			p1, p2 =  1, -1
			y1, y2 =  1, -1
		elseif EPattern == 2 then
			p1, p2 = -1,  1
			y1, y2 =  1, -1
		elseif EPattern == 3 then
			p1, p2 =  1, -1
			y1, y2 = -1,  1
		else
			p1, p2 = -1,  1
			y1, y2 = -1,  1
		end

		yield( flPitch + flAngle * p1, flYaw + flAngle * y1 )
		yield( flPitch + flAngle * p2, flYaw + flAngle * y1 )
		yield( flPitch + flAngle * p1, flYaw + flAngle * y2 )
		yield( flPitch + flAngle * p2, flYaw + flAngle * y2 )
	end
end

local wrap = coroutine.wrap

return function( flPitch, flYaw ) return wrap( function() Iterator( flPitch, flYaw ) end ) end
