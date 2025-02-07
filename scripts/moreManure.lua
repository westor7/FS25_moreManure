-- Author: westor
-- Contact: westor7 @ Discord
--
-- Copyright (c) 2025 westor

moreManure = {}
moreManure.settings = {}
moreManure.name = g_currentModName or "FS25_moreManure"
moreManure.version = "1.0.1.0"
moreManure.dir = g_currentModDirectory
moreManure.init = false
moreManure.initUI = false

function moreManure.prerequisitesPresent(specializations)
	return true
end

function moreManure:loadMap()
	if g_dedicatedServer or g_currentMission.missionDynamicInfo.isMultiplayer or not g_server or not g_currentMission:getIsServer() then
		Logging.error("[%s]: Error, Cannot use this mod because this mod is working only for singleplayer!", moreManure.name)

		return
	end
	
	moreManure.init = true
	
	InGameMenu.onMenuOpened = Utils.appendedFunction(InGameMenu.onMenuOpened, moreManure.initUi)

	FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, moreManure.saveSettings)
end

function moreManure:defSettings()
	moreManure.settings.Multiplier = 2
	moreManure.settings.OldMultiplier = 2
end

function moreManure:saveSettings()
	Logging.info("[%s]: Trying to save settings..", moreManure.name)

	local modSettingsDir = getUserProfileAppPath() .. "modSettings"
	local createXmlFile = modSettingsDir .. "/" .. "moreManure.xml"

	local xmlFile = createXMLFile("moreManure", createXmlFile, "moreManure")
	
	setXMLFloat(xmlFile, "moreManure.manure#Multiplier",moreManure.settings.Multiplier)
	
	saveXMLFile(xmlFile)
	delete(xmlFile)
	
	Logging.info("[%s]: Settings have been saved.", moreManure.name)
end

function moreManure:loadSettings()
	Logging.info("[%s]: Trying to load settings..", moreManure.name)
	
	local modSettingsDir = getUserProfileAppPath() .. "modSettings"
	local fileNamePath = modSettingsDir .. "/" .. "moreManure.xml"
	
	if fileExists(fileNamePath) then
		Logging.info("[%s]: File founded, loading now the settings..", moreManure.name)
		
		local xmlFile = loadXMLFile("moreManure", fileNamePath)
		
		if xmlFile == 0 then
			Logging.warning("[%s]: Could not read the data from XML file, maybe the XML file is empty or corrupted, using the default!", moreManure.name)
			
			moreManure:defSettings()
			
			Logging.info("[%s]: Settings have been loaded.", moreManure.name)
			
			return
		end

		local Multiplier = getXMLFloat(xmlFile, "moreManure.manure#Multiplier")

		if Multiplier == nil or Multiplier == 0 then
			Logging.warning("[%s]: Could not parse the correct 'Multiplier' value from the XML file, maybe it is corrupted, using the default!", moreManure.name)
			
			Multiplier = 2
		end

		if Multiplier < 1.5 then
			Logging.warning("[%s]: Could not retrieve the correct 'Multiplier' digital number value because it is lower than '1.5' from the XML file or it is corrupted, using the default!", moreManure.name)
			
			Multiplier = 2
		end
		
		if Multiplier > 100 then
			Logging.warning("[%s]: Could not retrieve the correct 'Multiplier' digital number value because it is higher than '100' from the XML file or it is corrupted, using the default!", moreManure.name)
			
			Multiplier = 2
		end
		
		moreManure.settings.Multiplier = Multiplier
		moreManure.settings.OldMultiplier = Multiplier
		
		delete(xmlFile)
					
		Logging.info("[%s]: Settings have been loaded.", moreManure.name)
	else
		moreManure:defSettings()

		Logging.info("[%s]: NOT any File founded!, using the default settings.", moreManure.name)
	end
end

function moreManure:initUi()
	if not moreManure.initUI then
		local uiSettingsmoreManure = moreManureUI.new(moreManure.settings)
		
		uiSettingsmoreManure:registerSettings()
		
		moreManure.initUI = true
	end
end

function moreManure:loadAnimals()
	if not self.isServer then return end

	Logging.info("[%s]: Initializing mod v%s (c) 2025 by westor.", moreManure.name, moreManure.version)

	moreManure:loadSettings()
	moreManure:initAllAnimals()
	
	Logging.info("[%s]: End of mod initalization.", moreManure.name)
end

function moreManure:initAllAnimals()
	local types = { 
		"COW_SWISS_BROWN", 
		"COW_HOLSTEIN", 
		"COW_ANGUS", 
		"COW_LIMOUSIN", 
		"COW_WATERBUFFALO",
		
		"PIG_LANDRACE",
		"PIG_BLACK_PIED",
		"PIG_BERKSHIRE",
		
		"HORSE_GRAY",
		"HORSE_PINTO",
		"HORSE_PALOMINO",
		"HORSE_CHESTNUT",
		"HORSE_BAY",
		"HORSE_BLACK",
		"HORSE_SEAL_BROWN",
		"HORSE_DUN"
	}
	
	moreManure.updated = 0
	
	Logging.info("[%s]: Start of animals manure updates. - Total: %s", moreManure.name, table.getn(types))

	moreManure:initAnimals(true, false, false)
	moreManure:initAnimals(false, true, false)
	moreManure:initAnimals(false, false, true)
	
	Logging.info("[%s]: End of animals manure updates. - Updated: %s - Total: %s", moreManure.name, moreManure.updated, table.getn(types))
end

function moreManure:initAnimals(animalCows, animalPigs, animalHorses)
	local animalCall = ""

	if animalCows then animalCall = "COW" end
	if animalPigs then animalCall = "PIG" end
	if animalHorses then animalCall = "HORSE" end

	for _1, subTypeIndex in ipairs(g_currentMission.animalSystem.nameToType[animalCall].subTypes) do
		local subType = g_currentMission.animalSystem.subTypes[subTypeIndex]

		if subType.output.manure then
			local animalType = subType.name
			
			moreManure.updated = moreManure.updated + 1
		
			for _2, output in ipairs(subType.output.manure.keyframes) do
				local amount = output[1]
				local age = output.time
				local newAmount = 0
				local defAmount = 0
				
				if moreManure.init then 
					defAmount = amount / moreManure.settings.OldMultiplier
					newAmount = defAmount * moreManure.settings.Multiplier
				else
					defAmount = amount
					newAmount = defAmount * moreManure.settings.Multiplier
				end

				output[1] = newAmount
				
				Logging.info("[%s]: %s animal manure amount has been updated. - Animal Type: %s - Age: %s - Default: %s - Old: %s - New: %s - Old Multiplier: %s - New Multiplier: %s", moreManure.name, animalCall, animalType, age, defAmount, amount, newAmount, moreManure.settings.OldMultiplier, moreManure.settings.Multiplier)
			end	

		end
		
	end
end

AnimalSystem.loadAnimals = Utils.appendedFunction(AnimalSystem.loadAnimals, moreManure.loadAnimals)

addModEventListener(moreManure)