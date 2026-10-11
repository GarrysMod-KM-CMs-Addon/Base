// Debug Print Model Data

// Gives you useful model info, e.g. if sequences have root motion and all poseparams
// Does not give you useless info like what animations sequence n is attached to

function PrintModelData( pEntity )
	if isstring( pEntity ) then
		local pDonor = GetAnimationDonor()
		pDonor:SetModel( pEntity )
		pEntity = pDonor
	end

	print( "====== PrintModelData ======" )
	print()
	print( "Internally using: " .. tostring( pEntity ) )
	print( "Model: " .. tostring( pEntity:GetModel() ) )
	print()

	local iCount = pEntity:GetNumPoseParameters()
	if iCount > 0 then
		print( "Found " .. tostring( iCount ) .. " pose parameters" )
		for i = 0, iCount - 1 do
			local flMin, flMax = pEntity:GetPoseParameterRange( i )
			print( pEntity:GetPoseParameterName( i ) .. ' ' .. flMin .. " / " .. flMax )
		end
		print()
	else print "No pose parameters" end

	local iCount = pEntity:GetSequenceCount()
	if iCount > 0 then
		print( "Found " .. tostring( iCount ) .. " sequences" )
		print( "You can view them by right clicking the model in the spawnmenu and selecting Edit icon" )
		for i = 0, iCount - 1 do
			local b1, v1, a1 = pEntity:GetSequenceMovement( i, 0, .5 )
			local b2, v2, a2 = pEntity:GetSequenceMovement( i, .5, 1 )
			if b1 && b2 && ( v1 != v2 || a1 != a2 ) then
				print( "Found root motion sequence " .. tostring( i ) ..  ": " .. pEntity:GetSequenceName( i ) )
			end
		end
	else print "No sequences (dafuq?!)" end
end
