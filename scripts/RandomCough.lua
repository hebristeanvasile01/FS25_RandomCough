-- Random Cough (FS25)
-- The farmer coughs now and then, at a random moment. Male and female characters
-- have their own cough sound. Client side only: every player hears their own cough.

RandomCough = {}

RandomCough.MOD_NAME = g_currentModName
RandomCough.MOD_DIR = g_currentModDirectory

-- Time between two coughs in minutes (real time, not game time)
RandomCough.MIN_INTERVAL_MINUTES = 3
RandomCough.MAX_INTERVAL_MINUTES = 10

-- If the character model file name contains one of these (lowercase), the player is female
RandomCough.FEMALE_PATTERNS = {"female", "playerf", "woman", "girl"}

RandomCough.isLoaded = false
RandomCough.samples = {}
RandomCough.timer = 0
RandomCough.genderOverride = nil -- nil = automatic, "male" or "female" = forced
RandomCough.lastLoggedStyle = nil

function RandomCough:loadMap(filename)
    -- A dedicated server has no audio and no local player
    if g_dedicatedServer ~= nil then
        return
    end

    self:loadSamples()
    self:resetTimer()

    addConsoleCommand("rcCough", "Plays a cough now. Optional: male or female", "consoleCommandCough", self, "[male|female]")
    addConsoleCommand("rcCoughGender", "Forces the cough voice: auto, male or female", "consoleCommandGender", self, "[auto|male|female]")
    addConsoleCommand("rcCoughInterval", "Sets the min and max minutes between coughs", "consoleCommandInterval", self, "[minMinutes]; [maxMinutes]")

    self.isLoaded = true
end

function RandomCough:deleteMap()
    if not self.isLoaded then
        return
    end

    self.isLoaded = false

    removeConsoleCommand("rcCough")
    removeConsoleCommand("rcCoughGender")
    removeConsoleCommand("rcCoughInterval")

    for key, sample in pairs(self.samples) do
        g_soundManager:deleteSample(sample)
        self.samples[key] = nil
    end
end

function RandomCough:loadSamples()
    local xmlPath = Utils.getFilename("xml/sounds.xml", self.MOD_DIR)
    local xmlHandle = loadXMLFile("RandomCoughSounds", xmlPath)

    if xmlHandle == nil or xmlHandle == 0 then
        Logging.warning("[RandomCough] Could not load %s", xmlPath)
        return
    end

    for _, gender in ipairs({"male", "female"}) do
        local sample = g_soundManager:loadSample2DFromXML(xmlHandle, "sounds", gender .. "Cough", self.MOD_DIR, 1, AudioGroup.ENVIRONMENT)

        if sample ~= nil then
            self.samples[gender] = sample
        else
            Logging.warning("[RandomCough] Could not load the %s cough sound", gender)
        end
    end

    delete(xmlHandle)
end

function RandomCough:resetTimer()
    local minMs = self.MIN_INTERVAL_MINUTES * 60 * 1000
    local maxMs = math.max(self.MAX_INTERVAL_MINUTES * 60 * 1000, minMs)

    self.timer = minMs + math.random() * (maxMs - minMs)
end

-- Returns "male" or "female"
function RandomCough:getGender()
    if self.genderOverride ~= nil then
        return self.genderOverride
    end

    local gender = "male"
    local fileName = ""

    if g_localPlayer ~= nil and g_localPlayer.graphicsComponent ~= nil then
        local style = g_localPlayer.graphicsComponent:getStyle()

        if style ~= nil and style.xmlFilename ~= nil then
            fileName = string.lower(tostring(style.xmlFilename))

            for _, pattern in ipairs(self.FEMALE_PATTERNS) do
                if string.find(fileName, pattern, 1, true) ~= nil then
                    gender = "female"
                    break
                end
            end
        end
    end

    -- Log the detection once per character model, to make it easy to verify
    if self.lastLoggedStyle ~= fileName then
        self.lastLoggedStyle = fileName
        Logging.info("[RandomCough] Character model '%s' -> %s cough", fileName, gender)
    end

    return gender
end

function RandomCough:cough(gender)
    gender = gender or self:getGender()

    local sample = self.samples[gender] or self.samples.male

    if sample == nil then
        return false
    end

    if g_soundManager:getIsSamplePlaying(sample) then
        return false
    end

    g_soundManager:playSample(sample)

    return true
end

function RandomCough:update(dt)
    if not self.isLoaded then
        return
    end

    -- Not in menus and not before the player exists
    if g_currentMission == nil or g_localPlayer == nil or g_gui:getIsGuiVisible() then
        return
    end

    self.timer = self.timer - dt

    if self.timer <= 0 then
        self:cough()
        self:resetTimer()
    end
end

------------------------------------------------------------------------------
-- Console commands (open the console with the ~ key)
------------------------------------------------------------------------------

function RandomCough:consoleCommandCough(gender)
    gender = gender ~= nil and string.lower(gender) or nil

    if gender ~= nil and gender ~= "male" and gender ~= "female" then
        return "Use: rcCough [male|female]"
    end

    if self:cough(gender) then
        return string.format("Cough (%s)", gender or self:getGender())
    end

    return "Could not play the cough sound, check log.txt"
end

function RandomCough:consoleCommandGender(value)
    value = value ~= nil and string.lower(value) or "auto"

    if value == "auto" then
        self.genderOverride = nil
    elseif value == "male" or value == "female" then
        self.genderOverride = value
    else
        return "Use: rcCoughGender [auto|male|female]"
    end

    return string.format("Cough voice: %s (detected: %s)", value, self:getGender())
end

function RandomCough:consoleCommandInterval(minMinutes, maxMinutes)
    local minValue = tonumber(minMinutes)
    local maxValue = tonumber(maxMinutes)

    if minValue == nil or maxValue == nil or minValue <= 0 or maxValue < minValue then
        return string.format("Use: rcCoughInterval [minMinutes] [maxMinutes]. Now: %s to %s", self.MIN_INTERVAL_MINUTES, self.MAX_INTERVAL_MINUTES)
    end

    self.MIN_INTERVAL_MINUTES = minValue
    self.MAX_INTERVAL_MINUTES = maxValue
    self:resetTimer()

    return string.format("Cough every %s to %s minutes", minValue, maxValue)
end

addModEventListener(RandomCough)
