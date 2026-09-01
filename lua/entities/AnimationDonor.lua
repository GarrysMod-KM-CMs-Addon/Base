// NOTE: You should probably call GetAnimationDonor()
// instead of trying to directly interact with this!

AddCSLuaFile()
DEFINE_BASECLASS "base_nextbot"

scripted_ents.Register( ENT, "BaseActorAnimationDonor" )

local FL_ANIMDONOR = FL_GODMODE + FL_NOTARGET + FL_WORLDBRUSH + FL_STATICPROP

function ENT:Initialize()
	if IsValid( g_pAnimationDonor ) then
		ErrorNoHaltWithStack( "g_pAnimationDonor: Second animation Donor (" .. tostring( self ) .. ") when one already exists" .. tostring( g_pAnimationDonor ) .. "! Removing!" )
		self:Remove()
		return
	end

	g_pAnimationDonor = self

	self:SetNoDraw( true )
	self:SetNotSolid( true )
	self:SetHealth( 0 )
	self:SetMaxHealth( 0 )
	self:SetCollisionGroup( COLLISION_GROUP_WORLD )
	self:AddFlags( FL_ANIMDONOR )
end

if CLIENT then return end

local TRANSMIT_ALWAYS = TRANSMIT_ALWAYS
function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end

local coroutine_yield = coroutine.yield
function ENT:RunBehaviour() while true do coroutine_yield() end end

function ENT:OnTakeDamage() return 0 end
function ENT:OnKilled() end
