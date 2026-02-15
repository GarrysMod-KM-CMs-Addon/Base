// I (KM_CM) took the code from Hunter's Glee https://github.com/StrawWagen/hunters_glee
// Hunter's Glee itself took the code from https://steamcommunity.com/sharedfiles/filedetails/?id=3504739480

DEFINE_BASECLASS "BaseWeapon"
AddCSLuaFile()

sound.Add {
	name = "VideoCamera_Toggle",
	channel = CHAN_WEAPON,
	volume = .5,
	level = 70,
	pitch = 112,
	sound = "buttons/lightswitch2.wav",
}

SWEP.PrintName = "#VideoCamera"
SWEP.Instructions = "#VideoCameraInstructions"
SWEP.Purpose = "#VideoCameraDescription"
SWEP.Spawnable = true
SWEP.HoldType = "rpg"
SWEP.WorldModel = Model "models/dav0r/camera.mdl"
SWEP.ViewModel = Model "models/dav0r/camera.mdl"
SWEP.ViewModelFOV = 55
SWEP.UseHands = false
SWEP.Slot = 5
SWEP.Crosshair = ""

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", "Quality" )
	self:NetworkVar( "Float", "FOVScale" )
end

function SWEP:Initialize()
	self:SetHoldType "rpg"
	self:SetQuality( math.Rand( .5, 4 ) )
	self:SetFOVScale( math.Rand( .75, 1 ) )
end

if SERVER then
	ACHIEVEMENT_ACQUIRE "videocamera"

	hook.Add( "PlayerSpawn", "VideoCamera", function( ply ) ply:SendLua "VideoCamera_SetUp()" end )
else
	local iFramesWhileDead = 0
	local iFramesWhileDeadRange = { 1, 90 }
	local VideoCamera_pWriter, sError
	local clError, clSave = Color( 255, 0, 0 ), Color( 0, 255, 255 )
	local __CONFIG__ = {
		container = "webm",
		video = "vp8",
		audio = "vorbis",
		quality = 40,
		bitrate = 30,
		fps = 18,
		lockfps = true,
		width = 640,
		height = 480,
		fovScale = 1
	}
	local tCurrentConfig
	function VideoCamera_BeginRecording()
		hook.Add( "PreDrawViewModels", "VideoCamera", function()
			if !VideoCamera_pWriter then return end
			local ply = LocalPlayer()
			if !IsValid( ply ) || !ply:Alive() then
				iFramesWhileDead = iFramesWhileDead - 1
				if iFramesWhileDead <= 0 then
					VideoCamera_Toggle()
					return
				end
			end
			VideoCamera_pWriter:AddFrame( FrameTime(), true )
			LocalPlayer():SetDSP( 38, true )
		end )
	end
	function VideoCamera_Toggle( pCamera )
		if VideoCamera_pWriter then
			hook.Remove( "PreDrawViewModels", "VideoCamera" )
			chat.AddText( clSave, "Saved video to /videos/" .. tCurrentConfig.name .. ".webm" )
			VideoCamera_pWriter:Finish()
			VideoCamera_pWriter = nil // Memory leak! Whoops...
			LocalPlayer():SetDSP( 0, true )
		elseif IsValid( pCamera ) then
			tCurrentConfig = table.Copy( __CONFIG__ )
			tCurrentConfig.quality = __CONFIG__.quality * pCamera:GetQuality()
			tCurrentConfig.fps = math.Clamp( __CONFIG__.fps * pCamera:GetQuality(), 5, 60 )
			tCurrentConfig.bitrate = __CONFIG__.bitrate * pCamera:GetQuality()
			tCurrentConfig.fovScale = __CONFIG__.fovScale * pCamera:GetFOVScale()
			iFramesWhileDead = math.random( iFramesWhileDeadRange[ 1 ], iFramesWhileDeadRange[ 2 ] )
			tCurrentConfig.name = "VideoCamera_" .. util.DateStamp()
			local w, h = ScrW(), ScrH()
			tCurrentConfig.width = math.min( w, 480 )
			tCurrentConfig.height = math.min( math.floor( ( tCurrentConfig.width * h ) / w ), w )
			VideoCamera_pWriter, sError = video.Record( tCurrentConfig )
			if VideoCamera_pWriter then
				VideoCamera_pWriter:SetRecordSound( true )
				VideoCamera_BeginRecording()
			else
				chat.AddText( clError, "Couldn't record video: " .. sError )
			end
		end
	end

	function VideoCamera_SetUp()
		if VideoCamera_pWriter then
			VideoCamera_Toggle()
		end
	end

	local clRecordingA, clRecordingB = Color( 255, 100, 100 ), Color( 20, 20, 20 )
	hook.Add( "HUDPaint", "VideoCamera", function()
		if VideoCamera_pWriter then
			if math.sin( CurTime() * 8 ) > 0 then
				draw.SimpleTextOutlined( "RECORDING", "DermaLarge", ScrW() * 0.5, 0, clRecordingA, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, clRecordingB )
			end
		end
	end )

	hook.Add( "CalcView", "VideoCamera", function( ply, pos, angles, fov )
		if VideoCamera_pWriter then
			return {
				origin = pos,
				angles = angles,
				fov = fov * tCurrentConfig.fovScale
			}
		end
	end )
end

function SWEP:CanSecondaryAttack() return false end

function SWEP:PrimaryAttack()
	local flTime = CurTime()
	if flTime < self:GetNextPrimaryFire() then return end
	if SERVER && game.SinglePlayer() then
		self:CallOnClient "PrimaryAttack"
		return
	end
	self:SetNextPrimaryFire( flTime + .1 )
	self:EmitSound "VideoCamera_Toggle"
	if CLIENT && ( IsFirstTimePredicted() || game.SinglePlayer() ) then VideoCamera_Toggle( self ) end
end

function SWEP:Holster()
	if CLIENT && ( IsFirstTimePredicted() || game.SinglePlayer() ) && LocalPlayer() == self:GetOwner() && VideoCamera_pWriter then VideoCamera_Toggle() end
	if game.SinglePlayer() then self:CallOnClient "Holster" end
	return true
end

function SWEP:Think() self.pLastOwner = self:GetOwner() end

function SWEP:OnDrop()
	local pLastOwner = self.pLastOwner
	if IsValid( pLastOwner ) && pLastOwner:IsPlayer() then pLastOwner:SendLua "VideoCamera_Toggle()" end
end

function SWEP:DrawWorldModel()
	local ply = self:GetOwner()
	if !IsValid( ply ) || ply:GetActiveWeapon() != self then
		self:DrawModel()
		return
	end

	local pos, ang
	local at = ply:GetAttachment( ply:LookupAttachment "anim_attachment_RH" )
	if at then
		ang = at.Ang
		pos = at.Pos + ang:Up() * 10 + ang:Right() + ang:Forward() * 2
	else
		local tCandidates = {
			"ValveBiped.Bip01_R_Hand",
			"ValveBiped.Bip01_R_Forearm",
			"RightHand",
			"r_hand",
		}
		for _, bname in ipairs( tCandidates ) do
			local iBone = ply:LookupBone( bname )
			if iBone then
				local m = ply:GetBoneMatrix( iBone )
				if m then
					ang = m:GetAngles()
					pos = m:GetTranslation()
				else
					local bp, ba = ply:GetBonePosition( iBone )
					if bp && ba then
						ang = ba
						pos = bp
					end
				end
				if pos && ang then pos = pos + ang:Up() * 8 + ang:Right() * 2 + ang:Forward() * 2 break end
			end
		end
		if !pos || !ang then
			ang = ply:EyeAngles()
			pos = ply:EyePos() + ang:Right() * 11 + ang:Forward() * 4
		end
	end
	self:SetPos( pos )
	self:SetAngles( ang )
	self:SetupBones()
	self:DrawModel()
end

SWEP.SwayScale = 0
SWEP.BobScale = 0

SWEP.flViewModelX = 30
SWEP.flViewModelY = 16
SWEP.flViewModelZ = -6

SWEP.bPistolSprint = true
SWEP.vPistolSprint = Vector( 16, -12, -32 )
SWEP.vPistolSprintAngle = Vector( 90, 0, 0 )
