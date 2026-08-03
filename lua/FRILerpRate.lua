// (Calculate) Frame-Rate Independent Lerp Rate

local min = math.min
local exp = math.exp

function FRILerpRate( flRate, flFrameTime ) return min( 1, 1 - exp( -flRate * flFrameTime ) ) end
