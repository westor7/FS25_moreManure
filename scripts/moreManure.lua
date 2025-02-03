-- Author: westor
-- Contact: westor7 @ Discord
--
-- Copyright (c) 2025 westor

moreManure = {}
moreManure.settings = {}
moreManure.name = g_currentModName or "FS25_moreManure"
moreManure.version = "1.0.0.0"
moreManure.debug = true -- for debugging purposes only
moreManure.dir = g_currentModDirectory
moreManure.init = false

function moreManure.prerequisitesPresent(specializations)
    return true
end

function moreManure:loadMap()
	Logging.info("[%s]: Initializing mod v".. moreManure.version .. " (c) 2025 by westor.", moreManure.name)
	
	if g_dedicatedServer or g_currentMission.missionDynamicInfo.isMultiplayer or not g_server or not g_currentMission:getIsServer() then
		Logging.error("[%s]: Error, Cannot use this mod because this mod is working only for singleplayer!", moreManure.name)

		return
    end
	
	InGameMenu.onMenuOpened = Utils.appendedFunction(InGameMenu.onMenuOpened, moreManure.initUi)

	FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, moreManure.saveSettings)
	
	moreManure:loadSettings()
end

function moreManure:defSettings()
	moreManure.settings.Multiplier = 1.5
	moreManure.settings.Multiplier_OLD = 1.5
end

function moreManure:saveSettings()
	Logging.info("[%s]: Trying to save settings..", moreManure.name)

	local modSettingsDir = getUserProfileAppPath() .. "modSettings"
	local fileName = "moreManure.xml"
	local createXmlFile = modSettingsDir .. "/" .. fileName

	local xmlFile = createXMLFile("moreManure", createXmlFile, "moreManure")
	
	setXMLFloat(xmlFile, "moreManure.manure#Multiplier",moreManure.settings.Multiplier)
	
	saveXMLFile(xmlFile)
	delete(xmlFile)
	
	Logging.info("[%s]: Settings have been saved.", moreManure.name)
end

function moreManure:loadSettings()
	Logging.info("[%s]: Trying to load settings..", moreManure.name)
	
	local modSettingsDir = getUserProfileAppPath() .. "modSettings"
	local fileName = "moreManure.xml"
	local fileNamePath = modSettingsDir .. "/" .. fileName
	
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
			
			Multiplier = 1.5
		end

		if Multiplier < 1.5 then
			Logging.warning("[%s]: Could not retrieve the correct 'Multiplier' digital number value because it is lower than '1.5' from the XML file or it is corrupted, using the default!", moreManure.name)
			
			Multiplier = 1.5
		end
		
		if Multiplier > 50 then
			Logging.warning("[%s]: Could not retrieve the correct 'Multiplier' digital number value because it is higher than '50' from the XML file or it is corrupted, using the default!", moreManure.name)
			
			Multiplier = 1.5
		end
		
		moreManure.settings.Multiplier = Multiplier
		moreManure.settings.Multiplier_OLD = Multiplier
		
		delete(xmlFile)
					
		Logging.info("[%s]: Settings have been loaded.", moreManure.name)
	else
		moreManure:defSettings()

		Logging.info("[%s]: NOT any File founded!, using the default settings.", moreManure.name)
	end
end

function moreManure:initUi()
	if not moreManure.init then
		local uiSettingsmoreManure = moreManureUI.new(moreManure.settings,moreManure.debug)
		
		uiSettingsmoreManure:registerSettings()
		
		moreManure.init = true
	end
end

function moreManure:updateOutput(of, superFunc, foodFactor, productionFactor, globalProductionFactor)
	if self.isServer then
		local spec = self.spec_husbandryStraw	
		local fillLevel = self:getHusbandryFillLevel(spec.inputFillType) 
	
		if fillLevel > 0 and spec.inputLitersPerHour ~= 0 and spec.outputLitersPerHour > 0 then
		    local amount = spec.inputLitersPerHour * g_currentMission.environment.timeAdjustment
            local delete = amount - self:removeHusbandryFillLevel(self:getOwnerFarmId(), amount, spec.inputFillType)
			local liters = spec.outputLitersPerHour * moreManure.settings.Multiplier

			if liters > 0 and delete > 0 then
				self:addHusbandryFillLevelFromTool(self:getOwnerFarmId(), liters, spec.outputFillType, nil, nil, nil)
			end

			self:updateStrawPlane()
		end
	end

	superFunc(self, foodFactor, productionFactor, globalProductionFactor)
end

PlaceableHusbandryStraw.updateOutput = Utils.overwrittenFunction(PlaceableHusbandryStraw.updateOutput, moreManure.updateOutput)

addModEventListener(moreManure)