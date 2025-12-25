AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "CombineHunter" )
// scripted_ents.Alias( "npc_hunter", "CombineHunter" )

// https://github.com/KM-CM/GarrysMod-KM_CMs_Addon_CombineHunter
if file.Exists( "sound/CombineHunter/Fire.wav", "GAME" ) then
	sound.Add {
		name = "CombineHunterScan",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Scan/1.wav",
			"^CombineHunter/Scan/2.wav",
			"^CombineHunter/Scan/3.wav",
			"^CombineHunter/Scan/4.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.Scan",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Scan/1.wav",
			"^CombineHunter/Scan/2.wav",
			"^CombineHunter/Scan/3.wav",
			"^CombineHunter/Scan/4.wav"
		}
	}
	
	sound.Add {
		name = "CombineHunterSend",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Send/1.wav",
			"^CombineHunter/Send/2.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.FoundEnemy",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Send/1.wav",
			"^CombineHunter/Send/2.wav"
		}
	}
	
	sound.Add {
		name = "CombineHunterReceive",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Receive/1.wav",
			"^CombineHunter/Receive/2.wav",
			"^CombineHunter/Receive/3.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.FoundEnemyAck",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Receive/1.wav",
			"^CombineHunter/Receive/2.wav",
			"^CombineHunter/Receive/3.wav"
		}
	}
	
	sound.Add {
		name = "CombineHunterFlank",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Flank/1.wav",
			"^CombineHunter/Flank/2.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.FlankAnnounce",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Flank/1.wav",
			"^CombineHunter/Flank/2.wav"
		}
	}
	
	sound.Add {
		name = "CombineHunterCharge",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Charge/1.wav",
			"^CombineHunter/Charge/2.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.TackleAnnounce",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Charge/1.wav",
			"^CombineHunter/Charge/2.wav"
		}
	}
	
	sound.Add {
		name = "CombineHunterAlert",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Alert/1.wav",
			"^CombineHunter/Alert/2.wav",
			"^CombineHunter/Alert/3.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.Alert",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Alert/1.wav",
			"^CombineHunter/Alert/2.wav",
			"^CombineHunter/Alert/3.wav"
		}
	}
	
	sound.Add {
		name = "CombineHunterFootstep",
		channel = CHAN_STATIC,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Footstep/1.wav",
			"^CombineHunter/Footstep/2.wav",
			"^CombineHunter/Footstep/3.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.Footstep",
		channel = CHAN_STATIC,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Footstep/1.wav",
			"^CombineHunter/Footstep/2.wav",
			"^CombineHunter/Footstep/3.wav",
		}
	}
	
	sound.Add {
		name = "CombineHunterBackFootstep",
		channel = CHAN_STATIC,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/BackFootstep/1.wav",
			"^CombineHunter/BackFootstep/2.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.BackFootstep",
		channel = CHAN_STATIC,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/BackFootstep/1.wav",
			"^CombineHunter/BackFootstep/2.wav",
		}
	}

	sound.Add {
		name = "CombineHunterMaintainFire",
		channel = CHAN_STATIC,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/MaintainFire/1.wav",
			"^CombineHunter/MaintainFire/2.wav",
			"^CombineHunter/MaintainFire/3.wav"
		}
	}
	
	sound.Add {
		name = "CombineHunterFire",
		channel = CHAN_WEAPON,
		level = 150,
		pitch = { 98, 104 },
		sound = "^CombineHunter/Fire.wav"
	}
	sound.Add {
		name = "NPC_Hunter.FlechetteShoot",
		channel = CHAN_WEAPON,
		level = 150,
		pitch = { 98, 104 },
		sound = "^CombineHunter/Fire.wav"
	}
else
	// TODO: Redefine all of those sounds with better info instead of copying them
	local t = sound.GetProperties "NPC_Hunter.Scan" t.name = "CombineHunterScan" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.FoundEnemy" t.name = "CombineHunterSend" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.FoundEnemyAck" t.name = "CombineHunterReceive" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.FlankAnnounce" t.name = "CombineHunterFlank" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.TackleAnnounce" t.name = "CombineHunterCharge" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.Alert" t.name = "CombineHunterAlert" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.DefendStrider" t.name = "CombineHunterMaintainFire" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.Footstep" t.name = "CombineHunterFootstep" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.BackFootstep" t.name = "CombineHunterBackFootstep" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.FlechetteShoot" t.name = "CombineHunterFire" sound.Add( t )
end

ENT.PrintName = "#CombineHunter"

if !IsMounted "ep2" then return end

if CLIENT then
    local cMaterial = Material "sprites/light_glow02_add"
    local cColor = Color( 131, 224, 255 )
	local render_SetMaterial = render.SetMaterial
	local render_DrawSprite = render.DrawSprite
	function ENT:Draw()
		self:DrawModel()
        render_SetMaterial( cMaterial )
		local v = self:GetAttachment( self:LookupAttachment "bottom_eye" )
		v = v.Pos + v.Ang:Forward() * -5
		render_DrawSprite( v, 20, 20, cColor )
		render_DrawSprite( v, 20, 20, cColor )
		v = self:GetAttachment( self:LookupAttachment "top_eye" )
		v = v.Pos + v.Ang:Forward() * -5
		render_DrawSprite( v, 20, 20, cColor )
		render_DrawSprite( v, 20, 20, cColor )
    end
	return
end

function ENT:GetShootPos() return self:GetAttachment( self:LookupAttachment "bottom_eye" ).Pos end

ENT.flTopSpeed = 300
ENT.flRunSpeed = 200
ENT.flWalkSpeed = 75

ENT.iDefaultClass = CLASS_COMBINE

function ENT:MoveAlongPath( pPath, flSpeed, _, tFilter )
	self.loco:SetDesiredSpeed( flSpeed )
	local f = flSpeed * ACCELERATION_NORMAL
	self.loco:SetAcceleration( f )
	self.loco:SetDeceleration( f )
	self.loco:SetJumpHeight( 256 )
	local Y
	local pGoal = pPath:GetCurrentGoal()
	if pGoal then Y = ( pGoal.pos - self:GetPos() ):Angle()[ 2 ] - self:GetAngles()[ 2 ]
	else Y = GetVelocity( self ):Angle()[ 2 ] - self:GetAngles()[ 2 ] end
	self:SetPoseParameter( "move_yaw", Lerp( math.min( 5 * FrameTime() ), math.NormalizeAngle( self:GetPoseParameter "move_yaw" ), math.NormalizeAngle( Y ) ) )
	local f = GetVelocity( self ):Length()
	if f <= 12 then self:PromoteSequence "idle1" else
		if f > self.flTopSpeed - 12 then
			self:PromoteMotionSequence "canter_all"
		elseif f > self.flRunSpeed - 12 then
			self:PromoteMotionSequence "prowl_all"
		else self:PromoteMotionSequence "walk_all" end
	end
	self:HandleJumpingAlongPath( pPath, flSpeed, tFilter )
end

function ENT:DLG_MaintainFire() self:EmitSound "CombineHunterMaintainFire" BaseClass.DLG_MaintainFire( self ) end

ENT.bPlantAttack = true
ENT.bUnPlantedAttack = true

ENT.GAME_bOrganic = true

ENT.HAS_MELEE_ATTACK = true
ENT.HAS_RANGE_ATTACK = true

function ENT:Plant()
	self.bSuppressing = true
	self:AnimationSystemHalt()
	self:PlaySequenceAndWait( "plant", 1 )
	self.bPlanted = true
end

function ENT:UnPlant()
	self.bSuppressing = nil
	self.flPlantEndTime = nil
	self:AnimationSystemHalt()
	self:PlaySequenceAndWait( "unplant", 1 )
	self.bPlanted = nil
end

ENT.flNextShot = 0
function ENT:RangeAttackPlanted()
	self.bSuppressing = true
	if CurTime() <= self.flNextShot then return end
	local Attachment = self:GetAttachment( self:LookupAttachment( self.bLastFlechetteFromDown && "top_eye" || "bottom_eye" ) )
	local pFlechette = ents.Create "hunter_flechette"
	if !IsValid( pFlechette ) then return end
	pFlechette:SetOwner( self )
	pFlechette:SetPos( Attachment.Pos )
	pFlechette:Spawn()
	local d = self:GetAimVector()
	pFlechette:SetAngles( d:Angle() )
	pFlechette:SetVelocity( d * 4096 )
	self:EmitSound "CombineHunterFire"
	self.flNextShot = CurTime() + .1
	self.bLastFlechetteFromDown = !self.bLastFlechetteFromDown
end

function ENT:Initialize()
	BaseClass.Initialize( self )
	self:SetModel "models/hunter.mdl"
	self:SetBloodColor( DONT_BLEED )
	// The POWER of Combine engineering!
	self:SetHealth( 32768 )
	self:SetMaxHealth( 32768 )
	self:SetCollisionBounds( self.vHullMins, self.vHullMaxs )
	self:PhysicsInitShadow( false, false )
end

function ENT:OnKilled( d )
	if BaseClass.OnKilled( self, d ) then return end
	self:BecomeRagdoll( d )
end
