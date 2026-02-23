local sv_cheats = GetConVar "sv_cheats"
function GM:PlayerNoclip( _, bNoClip )
	if bNoClip then return sv_cheats:GetBool() end
	return true
end

function GM:PlayerSpawn( ply ) ply:SetupHands() end
