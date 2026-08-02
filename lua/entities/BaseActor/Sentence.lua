local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable

function ENT:EmitSentence( tSentence, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	local pLast = MyTable.m_pLastSentence
	if pLast then
		local pNew = { tSentence = tSentence }
		local pHead = pLast.pNext
		pNew.pPrev = pLast
		pNew.pNext = pHead
		pLast.pNext = pNew
		pHead.pPrev = pNew
		MyTable.m_pLastSentence = pNew
	else
		pLast = { tSentence = tSentence }
		pLast.pPrev = pLast
		pLast.pNext = pLast
		MyTable.m_pLastSentence = pLast
	end
end

local CreateSound = CreateSound

ENT.m_flSpeechTime = 0
function ENT:HandleSentences( MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	if CurTime() <= MyTable.m_flSpeechTime then return end
	local pLast = MyTable.m_pLastSentence
	if !pLast then return end
	local pNext = MyTable.m_pNextSentence || pLast.pNext
	local tSentence = pNext.tSentence
	local sSentence = tSentence.sSentence
	local pSound = CreateSound( self, sSentence )
	pSound:Play()
	MyTable.m_flSpeechTime = CurTime() + MyTable.GAME_flLastSoundDuration * ( tSentence.flMultiplier || .95 ) + ( tSentence.flDelay || 0 )
	if pNext.pNext == pNext then
		MyTable.m_pLastSentence = nil
		MyTable.m_pNextSentence = nil
		return
	end
	MyTable.m_pNextSentence = pNext.pNext
	pNext.pPrev.pNext = pNext.pNext
	pNext.pNext.pPrev = pNext.pPrev
	if pNext == pLast then  MyTable.m_pLastSentence = pNext.pPrev  end
end
