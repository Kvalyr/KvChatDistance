-- ====================================================================================================================
-- =	KvChatDistance - Text effects by distance to source unit
-- =	Copyright (c) Kvalyr - 2021 - All Rights Reserved
-- ====================================================================================================================
local strsplit = _G["strsplit"]
local time = _G["time"]
local tremove = _G["tremove"]
local C_ChatInfo = _G["C_ChatInfo"]
local GetNumGuildMembers = _G["GetNumGuildMembers"]
local IsInGuild = _G["IsInGuild"]
-- ====================================================================================================================
-- Debugging
local KLib = _G["KLib"]
if not KLib then
    KLib = {Con = function() end, Warn = function() end, Print = print} -- No-Op if KLib not available
end
-- ====================================================================================================================

-- TODO: Range Exchange: Inform receiver about self's estimation of receiver's range
-- TODO: Range Exchange: Inform receiver about self's estimation of other's range
-- TODO: Position Request: Request position information about other from target
-- TODO: Position Broadcast: Broadcast position information about self
-- TODO: Position Broadcast: Broadcast position information about other from self

-- TODO: Request list of known users, then request position info for each without throttling

-- KvChatDistance.comms = {}
KvChatDistance.comms_prefix = "KVCD"
KvChatDistance.comms_delimiter = ":"

KvChatDistance.comms_knownPlayers = {}
KvChatDistance.comms_knownUsers = {}
KvChatDistance.comms_lastGuildPingTime = 0

-- TODO: Combine version checks with range ping to reduce number of messages?
KvChatDistance.comms_opcodes = {
    ["MI"] = {"misc",}, -- Misc
    ["RV"] = {"version", "versionApi"}, -- Version Check
    ["SV"] = {"version", "versionApi"}, -- Version Check
    ["RP"] = {"unitName", "y", "x", "z", "mapID"}, -- Request position info
    ["SP"] = {"unitName", "y", "x", "z", "mapID"}, -- Send own position
    ["RR"] = {"unitName", "range"}, -- Request Range
    ["SR"] = {"unitName", "range"}, -- Send Range

    -- TODO: Handle vararg responses
    ["RU"] = {"..."}, -- Request list of known users
}
KvChatDistance.comms_opcodes_cooldowns = {
    ["RV"] = 300,
}


KvChatDistance.comms_throttleCache = {}
for key in pairs(KvChatDistance.comms_opcodes) do
    KvChatDistance.comms_throttleCache[key] = {}
end


-- --------------------------------------------------------------------------------------------------------------------
-- Init
-- --------------------------------------------------------
function KvChatDistance:CommsInit()
    self.comms_prefixRegistered = C_ChatInfo.RegisterAddonMessagePrefix(self.comms_prefix)
    KvChatDistance.commsInitDone = true
end

-- --------------------------------------------------------------------------------------------------------------------
-- (De)Serialization
-- --------------------------------------------------------
function KvChatDistance:CommsDeserializePayload(payload)

    local payloadParams = {strsplit(self.comms_delimiter, payload)}
    -- local opCode = payloadParams[1]
    local opCode = tremove(payloadParams, 1)
    local paramsForOpcode = self.comms_opcodes[opCode]

    -- KvChatDistance:Con("CommsDeserializePayload", opCode, paramsForOpcode)

    if not paramsForOpcode then
        KvChatDistance:Con("CommsOnReceived", "Invalid Prefix:", opCode)
        return
    end

    -- Match payload indexes up to keys
    local namedPayloadParams = {}
    for index, param in pairs(payloadParams) do
        local paramKey = paramsForOpcode[index]
        namedPayloadParams[paramKey] = param
    end
    return opCode, namedPayloadParams
end

-- --------------------------------------------------------

function KvChatDistance:CommsSerializePayload(opCode, data)
    local payload = opCode
    local paramsForOpcode = KvChatDistance.comms_opcodes[opCode]
    if not paramsForOpcode then
        KvChatDistance:Con("CommsSerializePayload", "Invalid Prefix:", opCode)
        return
    end

    -- KvChatDistance:Con("CommsSerializePayload", opCode, "paramsForOpcode", paramsForOpcode)
    if not KvChatDistance.TableIsEmpty(data) then
        for index, paramKey in pairs(paramsForOpcode) do
            local paramValue = data[index] or ""
            payload = payload..KvChatDistance.comms_delimiter..paramValue
        end
    end
    return payload
end



-- --------------------------------------------------------------------------------------------------------------------
-- Player Register
-- --------------------------------------------------------
function KvChatDistance:CommsRegisterPlayer(newPlayerName, pinged, addonUser, version, versionApi)
    -- if newPlayerName == self.constants.playerNameWithRealm or newPlayerName == self.constants.playerName then return end
    if KvChatDistance.UnitNameIsPlayer(newPlayerName) then return end

    newPlayerName = KvChatDistance.StripRealmFromUnitNameIfSameRealm(newPlayerName)

    KvChatDistance:Debug3("CommsRegisterPlayer", newPlayerName, pinged, addonUser, version, versionApi)

    -- TODO: Make this a proper handshake. Compare versions etc.
    -- Consider including broadcast settings in handshake for smarter broadcast/request logic
    if not KvChatDistance.comms_knownPlayers[newPlayerName] then
        KvChatDistance.comms_knownPlayers[newPlayerName] = {}
    end
    if pinged ~= nil then
        KvChatDistance.comms_knownPlayers[newPlayerName].pinged = pinged
    end
    if addonUser ~= nil then
        KvChatDistance.comms_knownPlayers[newPlayerName].addonUser = addonUser
    end
    if addonUser then
        local compatible = true
        KvChatDistance.comms_knownPlayers[newPlayerName].version = version
        KvChatDistance.comms_knownPlayers[newPlayerName].versionApi = versionApi
        KvChatDistance.comms_knownPlayers[newPlayerName].compatible = compatible  -- TODO
        if compatible then
            KvChatDistance:CommsRequestPosition(newPlayerName)
        end
        KvChatDistance.comms_knownUsers[newPlayerName] = true
    end
end

function KvChatDistance:CommsIsPlayerRegistered(playerName)
    local playerData = KvChatDistance.comms_knownPlayers[playerName]
    if not playerData then
        return false, false
    end
    return playerData.pinged, playerData.compatible
end


function KvChatDistance:CommsForgetPlayerIgnoreRealm(playerName)
    local playerNameWithoutRealm = KvChatDistance.StripRealmFromUnitName(playerName)
    local keyToNil = nil
    for key in pairs(KvChatDistance.comms_knownPlayers) do
        local keyWithoutRealm = KvChatDistance.StripRealmFromUnitName(playerName)
        if playerNameWithoutRealm == keyWithoutRealm then
            -- KvChatDistance.comms_knownPlayers[playerName] = nil
            keyToNil = key
            break
        end
    end
    if keyToNil then
        KvChatDistance.comms_knownPlayers[keyToNil] = nil
        KvChatDistance:Debug4("CommsForgetPlayerIgnoreRealm", playerName, keyToNil)
        return true
    end
end

function KvChatDistance:CommsForgetPlayer(playerName)
    if KvChatDistance.comms_knownPlayers[playerName] then
        KvChatDistance:Debug2("Forgetting player:", playerName)
        KvChatDistance.comms_knownPlayers[playerName] = nil
        return true
    else
        local playerName = KvChatDistance.AddRealmToUnitName(playerName)
        if KvChatDistance.comms_knownPlayers[playerName] then
            KvChatDistance:Debug2("Forgetting player:", playerName)
            KvChatDistance.comms_knownPlayers[playerName] = nil
            return true
        end
    end
    KvChatDistance:Debug4("CommsForgetPlayer false", playerName)

    -- Temporary hack to reduce "No player named X is currently playing" spam caused by mismatch with localized realm names
    return KvChatDistance:CommsForgetPlayerIgnoreRealm(playerName)

    -- return false
end

function KvChatDistance:CommsGetRegisteredPlayers()
    return KvChatDistance.comms_knownPlayers
end

-- --------------------------------------------------------------------------------------------------------------------
-- Event Handler
-- --------------------------------------------------------
function KvChatDistance:CHAT_MSG_ADDON(event, prefix, message, channel, sender, target, zoneChannelID, channelIndex, channelName, instanceID)
    -- https://wow.gamepedia.com/CHAT_MSG_ADDON
    if prefix ~= self.comms_prefix then return end

    local settings = self:GetSettings()
    if not KvChatDistance:Allowed(settings) then return end
    if not settings.allowComms then return end

    -- TODO: These checks may be overkill
    if not (KvChatDistance.commsInitDone and C_ChatInfo.IsAddonMessagePrefixRegistered(self.comms_prefix)) then
        KvChatDistance:Warn("KvChatDistance", "PREFIX NOT REGISTERED", event, prefix, message, channel, sender, target, zoneChannelID, channelIndex, channelName, instanceID)
        return
    end

    if (settings.debugLevel or 1) < 3 and KvChatDistance.UnitNameIsPlayer(sender) then return end

    self:Debug4(event, prefix, message, channel, sender, target, zoneChannelID, channelIndex, channelName, instanceID)

    self:CommsOnReceived(message, channel, sender, target)
end

-- --------------------------------------------------------------------------------------------------------------------
-- Main handler for incoming comms
-- --------------------------------------------------------
function KvChatDistance:CommsOnReceived(payload, channel, sender, target)
    if not KvChatDistance.commsInitDone then return end

    local opCode, namedPayloadParams = KvChatDistance:CommsDeserializePayload(payload)

    -- TODO: More robust check than this
    if opCode and KvChatDistance.comms_opcodes[opCode] ~= nil then
        KvChatDistance:CommsRegisterPlayer(sender, nil, true)
    end
    KvChatDistance:Debug2("CommsOnReceived", sender, opCode, namedPayloadParams, channel)

    -- TODO: Link these via callbacks for the Opcodes
    if opCode == "MI" then
        KvChatDistance:Con("CommsOnReceived", opCode, namedPayloadParams["misc"], channel)

    elseif opCode == "RV" then
        -- Request Version
        KvChatDistance:CommsVersionResponse(sender)

    elseif opCode == "SV" then
        -- Receiving Incoming Version
        KvChatDistance:CommsVersionReceived(sender, namedPayloadParams, channel)

    elseif opCode == "RP" then
        -- Request Position
        KvChatDistance:CommsPositionResponse(sender)

    elseif opCode == "SP" then
        -- Receiving Incoming Position
        KvChatDistance:CommsPositionReceived(sender, namedPayloadParams, channel)

    elseif opCode == "RR" then
        -- Request Range
        KvChatDistance:CommsRangeResponse(sender, namedPayloadParams)

    elseif opCode == "SR" then
        -- Receiving Incoming Range
        KvChatDistance:CommsRangeReceived(sender, namedPayloadParams, channel)

    end

end

-- --------------------------------------------------------------------------------------------------------------------
-- Transmit
-- --------------------------------------------------------
function KvChatDistance:CommsTransmit(opCode, dataTable, channel, target, otherTarget)
    if not KvChatDistance:Allowed() then return end

    if not channel then channel = "WHISPER" end
    local payload = self:CommsSerializePayload(opCode, dataTable)

    -- Check throttle - If true, we aren't throttled for this opcode and target
    if KvChatDistance:CommsTrack(opCode, channel, target, otherTarget) then
        KvChatDistance:Debug4("CommsTransmit", opCode, payload, channel, target)
        ChatThrottleLib:SendAddonMessage("NORMAL", self.comms_prefix, payload, channel, target)--, "queueName")

    else
        -- TODO: Queue?
        KvChatDistance:Debug4("CommsTransmit", "THROTTLED TRANSMIT", opCode, channel, target)
    end
end

-- --------------------------------------------------------------------------------------------------------------------
-- Version
-- --------------------------------------------------------
function KvChatDistance:CommsVersionReceived(sender, payloadParams, channel)
    -- KvChatDistance:Debug2("CommsVersionReceived", sender, payloadParams, channel)
    KvChatDistance:CommsRegisterPlayer(sender, true, true, payloadParams.version, payloadParams.versionApi)
end

function KvChatDistance:CommsVersionResponse(requester, channel)
    KvChatDistance:CommsSendVersion(requester, "WHISPER")
end

-- --------------------------------------------------------------------------------------------------------------------
-- Position
-- --------------------------------------------------------
function KvChatDistance:CommsPositionReceived(sender, payloadParams, channel)
    -- Accept position info about sender, or about another that sender knows about
    local unitName = payloadParams.unitName
    if not unitName or unitName == "" then unitName = sender end
    unitName = KvChatDistance.StripRealmFromUnitNameIfSameRealm(unitName)

    KvChatDistance:Debug2("CommsPositionReceived", unitName, payloadParams, channel)
    KvChatDistance:PositionStoreUnitInfo(unitName, payloadParams.y, payloadParams.x, payloadParams.z, payloadParams.mapID)
end


-- Send position in response to request
function KvChatDistance:CommsPositionResponse(requester)
    KvChatDistance:CommsSendPosition(requester, "WHISPER")
end

-- --------------------------------------------------------------------------------------------------------------------
-- Range
-- --------------------------------------------------------
function KvChatDistance:CommsRangeReceived(sender, payloadParams, channel)
    local unitName = payloadParams.unitName
    if not unitName or unitName == "" then unitName = sender end
    unitName = KvChatDistance.StripRealmFromUnitNameIfSameRealm(unitName)

    -- Accept range info about sender relative to another unit, or about sender relative to us
    local compareUnit = payloadParams.unitName
    if not compareUnit or compareUnit == "" then
        compareUnit = sender
    end
    local receivedRange = tonumber(payloadParams.range)
    local cachedRange = KvChatDistance:RangeGetUnitInfo(compareUnit)
    KvChatDistance:Debug2("CommsRangeReceived", compareUnit, receivedRange, channel)

    -- We have no cached range for the unit and the unit is someone else the sender knows about
    if not cachedRange and compareUnit ~= sender then
        -- TODO: This is a naive assumption that the other is further from us than the sender
        -- TODO: Incorrect if other is between us and sender
        -- TODO: Compare results from 2 or more senders
        local senderRange = KvChatDistance:RangeGetUnitInfo(sender) or 0
        KvChatDistance:RangeStoreUnitInfo(compareUnit, senderRange + receivedRange)
        return
    end
    if receivedRange and receivedRange > 0 and cachedRange ~= receivedRange then
        KvChatDistance:RangeStoreUnitInfo(compareUnit, (receivedRange + cachedRange) / 2)
        return
    end

    -- We don't need what we were sent
end

-- Send range in response to request
-- Can return receiver's range from requester or receiver's range from another
function KvChatDistance:CommsRangeResponse(requester, payloadParams)
    return KvChatDistance:CommsSendRange(requester,  "WHISPER", payloadParams.unitName)
end

-- --------------------------------------------------------------------------------------------------------------------
-- Comms Requests
-- --------------------------------------------------------
function KvChatDistance:CommsRequestVersion(target, channel)
    -- KvChatDistance:Debug4("CommsRequestVersion", target)
    if not channel then channel = "WHISPER" end
    KvChatDistance:CommsRegisterPlayer(target, true, false)
    self:CommsTransmit("RV", {}, channel, target)
end

function KvChatDistance:CommsRequestPosition(target, channel, otherTarget)
    if not channel then channel = "WHISPER" end
    if not otherTarget then otherTarget = "" end
    self:CommsTransmit("RP", {otherTarget}, channel, target, otherTarget)
end

function KvChatDistance:CommsRequestRange(target, channel, otherTarget)
    if not channel then channel = "WHISPER" end
    if not otherTarget then otherTarget = "" end
    -- if not compareUnit then compareUnit = KvChatDistance.UnitNameWithRealm("player") end
    self:CommsTransmit("RR", {otherTarget},channel, target, otherTarget)
end

-- --------------------------------------------------------------------------------------------------------------------
-- Comms Sends
-- --------------------------------------------------------
function KvChatDistance:CommsSendVersion(target, channel)
    if not channel then channel = "WHISPER" end
    self:CommsTransmit("SV", {self.version, self.comms_apiVersion}, channel, target)
end

function KvChatDistance:CommsSendPosition(target, channel)
    if not self:GetSettings().positionBroadcastEnabled then return end
    if not channel then channel = "WHISPER" end
    local posY, posX, posZ, instanceID = KvChatDistance:PositionGetCurrent("player")
    self:CommsTransmit("SP", {"", posY, posX, posZ, instanceID}, channel, target)
end

function KvChatDistance:CommsSendRange(target, channel, compareUnit)
    if not channel then channel = "WHISPER" end
    if not compareUnit or compareUnit == "" then
        compareUnit = target
    end
    local range = KvChatDistance:RangeGetUnitInfo(compareUnit) or -1
    KvChatDistance:Con("CommsRangeResponse", compareUnit, target, range)
    self:CommsTransmit("SR", {"", range}, channel, target)
end

-- --------------------------------------------------------------------------------------------------------------------
-- Comms Throttle Ticker
-- --------------------------------------------------------
function KvChatDistance:CommsTrack(opCode, channel, target, otherTarget)
    if not channel then channel = "" end
    if not target then target = "" end
    if not otherTarget then otherTarget = "" end
    target = KvChatDistance.StripRealmFromUnitNameIfSameRealm(target)

    local channelTarget = channel..target..otherTarget
    if channelTarget == "" then
        -- TODO: Error
        KvChatDistance:Con("Invalid channel/target combo", opCode, channel, target)
        return true
    end

    if not KvChatDistance.comms_throttleCache[opCode][channelTarget] then
        KvChatDistance.comms_throttleCache[opCode][channelTarget] = time()
        return true
    end
    return false
end

function KvChatDistance.CommsUpdateThrottle()
    -- for KvChatDistance.comms_throttleCache[opCode][target]
    local settings = KvChatDistance:GetSettings()
    local curTime = time()

    for opCode, opCodeThrottleTable in pairs(KvChatDistance.comms_throttleCache) do
        local commsThrottleDuration = settings["commsThrottleDuration_" .. (opCode or "")]
        if not commsThrottleDuration then
            commsThrottleDuration = KvChatDistance.comms_opcodes_cooldowns[opCode] or settings.commsThrottleDuration
        end
        for target, lastTransmit in pairs (opCodeThrottleTable) do
            -- If it has been more than commsThrottleDuration seconds since we last called that opcode for this target, clear throttle
            if curTime - (lastTransmit or 0) >= commsThrottleDuration then
                KvChatDistance:Debug4("CommsUpdateThrottle", "EVICTING", opCode, target, curTime, lastTransmit)
                KvChatDistance.comms_throttleCache[opCode][target] = nil
            end
        end

    end
end

-- --------------------------------------------------------------------------------------------------------------------
-- Comms Broadcast Ticker
-- --------------------------------------------------------
function KvChatDistance:CommsBroadCastAllOnlineFriends()
    -- Only broadcast to friends who aren't also in our guild
    local nonGuildFriends = KvChatDistance.GetFriendsNotInGuild()

    for friendName in pairs(nonGuildFriends) do
        self:Debug2("CommsBroadCastAllOnlineFriends", friendName)
        KvChatDistance:CommsSendVersion(friendName)
    end
end

function KvChatDistance:CommsBroadCastGuild()
    if not IsInGuild() then return end
    local settings = KvChatDistance:GetSettings()
    local interval = settings.commsBroadcastTickerInterval
    local curTime = time()

    -- If all guild members are pinging simultaneously, we don't want any more than about 10 incoming pings per minute
    -- Scale ping cooldown accordingly for guilds larger than that and 'skip a turn' when still in cooldown
    local targetGuildPingsPerMinute = 10

    local numTotalGuildMembers, numOnlineGuildMembers = GetNumGuildMembers()
    if numOnlineGuildMembers > targetGuildPingsPerMinute then
        local cooldown = numOnlineGuildMembers / targetGuildPingsPerMinute
        cooldown = math.max(1, cooldown)
        interval = (interval * cooldown) - 1
        if curTime < (KvChatDistance.comms_lastGuildPingTime + interval) then
            KvChatDistance:Debug2("CommsBroadCastGuild", "Skipping due to cooldown", curTime, KvChatDistance.comms_lastGuildPingTime, interval)
            return
        end
    end
    KvChatDistance.comms_lastGuildPingTime = curTime
    KvChatDistance:CommsSendVersion("GUILD", "GUILD")
end

function KvChatDistance.CommsBroadcast()
    -- for KvChatDistance.comms_throttleCache[opCode][target]
    local settings = KvChatDistance:GetSettings()
    local curTime = time()

    -- TODO: Party
    -- TODO: Raid


    KvChatDistance:CommsBroadCastGuild()

    -- Broadcast to friends who are not in same guild
    KvChatDistance:CommsBroadCastAllOnlineFriends()
end

-- --------------------------------------------------------------------------------------------------------------------
-- Filter out errors produced in chat frame from trying to SendAddonMessage whisper players that have gone offline or
-- are from opposite faction
-- Forget unreachable players to prevent further errors
-- --------------------------------------------------------
local function FilterPlayerNotFound(self, event, msg, ...)
    local player = strmatch(msg, _G["ERR_CHAT_PLAYER_NOT_FOUND_S"]:format("(.+)"))
	if player == nil or player == "" then
		return false
    end
	return KvChatDistance:CommsForgetPlayer(player), msg, ...
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", FilterPlayerNotFound)
