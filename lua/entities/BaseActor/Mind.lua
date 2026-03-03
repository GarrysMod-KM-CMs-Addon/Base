local table_IsEmpty = table.IsEmpty

ENT.m_sDefaultIdleSchedule = "Idle"
ENT.m_sDefaultCombatSchedule = "Combat"

function ENT:SelectSchedule( MyTable )
	if table_IsEmpty( MyTable.tEnemies ) then
		MyTable.SetNPCState( self, NPC_STATE_IDLE )
		MyTable.SetSchedule( self, MyTable.m_sDefaultIdleSchedule, MyTable )
	else
		MyTable.SetNPCState( self, NPC_STATE_COMBAT )
		MyTable.SetSchedule( self, MyTable.m_sDefaultCombatSchedule, MyTable )
	end
end

function ENT:Behaviour( MyTable )
	MyTable.RunMind( self, MyTable )
	MyTable.AnimationSystemTick( self, MyTable )
end
