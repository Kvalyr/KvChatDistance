-- ====================================================================================================================
-- =	KvChatDistance - Text effects by distance to source unit
-- =	Copyright (c) Kvalyr - 2021 - All Rights Reserved
-- ====================================================================================================================

-- TODO: Replace with proper i18n functionality
local i18n = {}
i18n["enabled"] = "Main Toggle"
i18n["enabled_desc"] = "Toggles all functionality of the addon."

i18n["allowInDungeons"] = "Enable in Dungeons"
i18n["allowInRaids"] = "Enable in Raids"
i18n["allowInScenarios"] = "Enable in Scenarios"

i18n["highlightSelf"] = "Highlight Self"
i18n["highlightSelfColor"] = "Self message highlight colour"

i18n["highlightFriends"] = "Highlight Friends"
i18n["highlightFriends_desc"] = "Toggles highlighting of friends' messages in chat."
i18n["highlightFriends_descextra"] = "They will not be affected by distance."
i18n["highlightFriendsColor"] = "Friend message highlight colour"
i18n["highlightFriendsBypassDistance"] = "Ignore distance for friends."
i18n["highlightGuild"] = "Highlight Guild Members"
i18n["highlightGuild_desc"] = "Toggles highlighting of guild members' messages in chat."
i18n["highlightGuild_descextra"] = "They will not be affected by distance."
i18n["highlightGuildColor"] = "Guild message highlight colour"
i18n["highlightGuildBypassDistance"] = "Ignore distance for guild members."
i18n["highlightGroup"] = "Highlight Group Members"
i18n["highlightGroup_desc"] = "Toggles highlighting of group members' messages in chat."
i18n["highlightGroup_descextra"] = "They will not be affected by distance."
i18n["highlightGroupColor"] = "Group message highlight colour"
i18n["highlightGroupBypassDistance"] = "Ignore distance for group members."

i18n["unitSearchTargetDepth"] = "Target Search Depth"
i18n["unitSearchTargetDepth_desc"] = "How many targets deep to search on checked units. Higher values reduce performance."
-- i18n["unitSearchTargetDepth_descextra"] = "How many targets deep to search on checked units. Higher values reduce performance."
i18n["useNameplateTrick"] = "Momentary Nameplate Scan"
i18n["useNameplateTrick_desc"] = "Momentarily enable all nameplates on an interval."
i18n["useNameplateTrick_descextra"] = "When enabled, this option forces nameplates to show for a split-second on an interval (set with the slider below) so that range information can be grabbed from the nameplates for units visible in your field of view.\n\n|cFFFF00FFWarning: This experimental option may interfere with other addons that control nameplate visibility.|r\n\n|cFFFF0000Warning: If disabled, the addon's ability to determine the distance of speakers in chat is severely hampered|r"
i18n["hideNameplatesDuringTrick"] = "Hide Nameplates during scan"
i18n["hideNameplatesDuringTrick_desc"] = "Hides the nameplates when they're being scanned."
i18n["hideNameplatesDuringTrick_descextra"] = "This should reduce the visual impact of the nameplates being toggled on an interval."
i18n["nameplateTickerInterval"] = "Nameplate Scan Interval (secs)"
i18n["nameplateTickerInterval_desc"] = "Sets the interval at which nameplates are briefly enabled so that the addon can grab distance information for nearby players."
i18n["nameplateTickerInterval_descextra"] = "Lower values may result in noticeable flickering."

i18n["sayEnabled"] = "Say (/s)"
i18n["sayEnabled_desc"] = "Enable text fading by distance for the 'Say' channel (/s)"
i18n["sayColorMin"] = "Far Say Brightness"
i18n["sayColorMid"] = "Medium Say Brightness"
i18n["sayColorMax"] = "Near Say Brightness"

i18n["emoteEnabled"] = "Emote (/e)"
i18n["emoteEnabled_desc"] = "Enable text fading by distance for the 'Emote' channel (/e)"
i18n["emoteColorMin"] = "Far Emote Brightness"
i18n["emoteColorMid"] = "Medium Emote Brightness"
i18n["emoteColorMax"] = "Near Emote Brightness"

i18n["yellEnabled"] = "Yell (/y)"
i18n["yellEnabled_desc"] = "Enable text fading by distance for the 'Yell' channel (/y)"
i18n["yellColorMin"] = "Far Yell Brightness"
i18n["yellColorMid"] = "Medium Yell Brightness"
i18n["yellColorMax"] = "Near Yell Brightness"

i18n["unknownColor"] = "Unknown-distance Brightness"

-- Prefixes
i18n["prefixFriends"] = "Friend: Add the prefix below to messages from friends."
i18n["prefixGuild"] = "Guild: Add the prefix below to messages from members of your guild."
i18n["prefixGroup"] = "Group: Add the prefix below to messages from people in your party/raid."
i18n["prefixStrangers"] = "Strangers: Add the prefix below to messages from players not in your friends, guild or group."
i18n["prefixTarget"] = "Target: Add the prefix below to messages from your current target."
i18n["prefixFocus"] = "Focus: Add the prefix below to messages from your current focus target."
i18n["prefixNPCs"] = "NPCs: Add the prefix below to messages from NPCs."

-- Comms
i18n["allowComms"] = "Toggle Addon Communication"
i18n["allowComms_desc"] = "Controls whether or not this addon can communicate silently with other users of the addon to improve range calculation accuracy."
i18n["allowComms_descextra"] = "Note: addon communication is fully disabled during combat, arenas and battlegrounds.\n\n|cFFFF0000Warning: If disabled, the addon's ability to determine the distance of speakers in chat is severely hampered|r"
i18n["positionBroadcastEnabled"] = "Toggle Sending Position to other users"
i18n["positionBroadcastEnabled_desc"] = "Controls whether or not your current world coordinates are sent to other users of the addon for more accurate range calculation."
i18n["positionBroadcastEnabled_descextra"] = "This option allows you to disable broadcasting your position in case you have privacy concerns.\n\n|cFFFF00FFNote: Your position is never sent during combat or to opposite-faction players.|r\n\n|cFFFF0000Warning: If disabled, the addon's ability to determine the distance of speakers in chat is severely hampered|r"

-- i18n["veryNearDistanceThreshold"] = "[Very Near] Range"
-- i18n["veryNearDistanceThreshold_desc"] = "Sets the maximum range for what the addon considers 'Very Near'."

-- i18n["nearDistanceThreshold"] = "[Near] Range"
-- i18n["nearDistanceThreshold_desc"] = "Sets the maximum range for what the addon considers 'Near'."

-- i18n["midDistanceThreshold"] = "[Mid] Range"
-- i18n["midDistanceThreshold_desc"] = "Sets the maximum range for what the addon considers 'Mid-Range'."

-- i18n["farDistanceThreshold"] = "[Far] Range"
-- i18n["farDistanceThreshold_desc"] = "Sets the maximum range for what the addon considers 'Far'."

KvChatDistance.i18n = i18n
