DEFINE_BASECLASS "BaseActor"
function ENT:Initialize() BaseClass.Initialize( self ) end

ENT.tThreatToClass = {}
function ENT:Behaviour( MyTable )
	MyTable.ClearThreatToClass( self, MyTable )
	BaseClass.Behaviour( self, MyTable )
end
