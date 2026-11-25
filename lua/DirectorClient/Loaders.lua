DIRECTOR_NUM_BATTLE_THEMES = 0
DIRECTOR_BATTLE_THEMES = {}

function AddCombatTheme( sName, pData )
	local sGlobal = "M_" .. sName

	local pGlobal = _G[ sGlobal ]

	if pGlobal then
		pGlobal.pData = pData

		if !pGlobal.iCombatThemeIndex then
			DIRECTOR_NUM_BATTLE_THEMES = DIRECTOR_NUM_BATTLE_THEMES + 1
			table.insert( DIRECTOR_BATTLE_THEMES, pGlobal )
			pGlobal.iCombatThemeIndex = DIRECTOR_NUM_BATTLE_THEMES
		end

		return
	end

	pGlobal = {
		sName = sName,
		pData = pData
	}

	DIRECTOR_NUM_BATTLE_THEMES = DIRECTOR_NUM_BATTLE_THEMES + 1
	table.insert( DIRECTOR_BATTLE_THEMES, pGlobal )
	pGlobal.iCombatThemeIndex = DIRECTOR_NUM_BATTLE_THEMES

	_G[ sGlobal ] = pGlobal
end

DIRECTOR_NUM_COMBAT_PANIC_THEMES = 0
DIRECTOR_COMBAT_PANIC_THEMES = {}

function AddCombatPanicTheme( sName, pData )
	local sGlobal = "M_" .. sName

	local pGlobal = _G[ sGlobal ]

	if pGlobal then
		pGlobal.pData = pData

		if !pGlobal.iCombatPanicThemeIndex then
			DIRECTOR_NUM_COMBAT_PANIC_THEMES = DIRECTOR_NUM_COMBAT_PANIC_THEMES + 1
			table.insert( DIRECTOR_COMBAT_PANIC_THEMES, pGlobal )
			pGlobal.iCombatPanicThemeIndex = DIRECTOR_NUM_COMBAT_PANIC_THEMES
		end

		return
	end

	pGlobal = {
		sName = sName,
		pData = pData
	}

	DIRECTOR_NUM_COMBAT_PANIC_THEMES = DIRECTOR_NUM_COMBAT_PANIC_THEMES + 1
	table.insert( DIRECTOR_COMBAT_PANIC_THEMES, pGlobal )
	pGlobal.iCombatPanicThemeIndex = DIRECTOR_NUM_COMBAT_PANIC_THEMES

	_G[ sGlobal ] = pGlobal
end
