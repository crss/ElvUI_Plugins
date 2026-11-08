local addonName, ns = ...
local secret = issecretvalue or function() return false end
local allowed = {
    SAY = true, YELL = true, GUILD = true, OFFICER = true,
    PARTY = true, PARTY_LEADER = true, RAID = true, RAID_LEADER = true,
    RAID_WARNING = true, INSTANCE_CHAT = true, INSTANCE_CHAT_LEADER = true,
    WHISPER = true, WHISPER_INFORM = true, CHANNEL = true,
    EMOTE = true, TEXT_EMOTE = true,
}
local STAR = '|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:12:12|t '
local state, errors, installed, E, CH = 'waiting for login', 0, false
local resolver = ns.NewResolver(function()
    return type(WhosWhoDB) == 'table' and WhosWhoDB.global or nil
end)

local function metadata(name, key)
    local get = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    return get and get(name, key)
end

local function settings()
    return type(ElvUIWhosWhoDB) == 'table' and ElvUIWhosWhoDB or {}
end

local function display(chatType, sender, senderGuid)
    if not settings().enabled or secret(chatType) or not allowed[chatType]
        or not ns.PlainString(sender) or not ns.PlainString(senderGuid) then return end
    local name, main = resolver:Resolve(senderGuid)
    if not name then return end
    if settings().mainStar and main then name = STAR .. name end
    -- Class comes exclusively from the message's GUID, never from WiW's main.
    local _, class = GetPlayerInfoByGUID(senderGuid)
    if not secret(class) and type(class) == 'string' then
        local color = E:ClassColor(class)
        if color and type(color.WrapTextInColorCode) == 'function' then
            return color:WrapTextInColorCode(name)
        end
    end
    return name -- Unknown class: inherit normal chat color, do not guess.
end

local function install()
    if installed then return end
    if type(ElvUI) ~= 'table' or type(ElvUI[1]) ~= 'table' then state = 'ElvUI missing'; return end
    E = ElvUI[1]
    if metadata('ElvUI', 'Version') ~= 'v16.01' or metadata('WhosWho', 'Version') ~= '1.0.1' then
        state = 'unsupported addon version'; return
    end
    if not E.Forever or type(E.GetModule) ~= 'function' then state = 'requires WoW Forever'; return end
    CH = E:GetModule('Chat', true)
    if not CH or not CH.db or not E.private or not E.private.chat or not E.private.chat.enable
        or type(CH.MessageFormatter) ~= 'function'
        or type(E.ClassColor) ~= 'function' then state = 'ElvUI chat unavailable'; return end
    if not C_Timer or type(C_Timer.NewTicker) ~= 'function' then state = 'timer unavailable'; return end
    local original = CH.MessageFormatter
    -- The native plugin filter only receives a completed body: it cannot safely
    -- distinguish a sender from links inside the message. Wrap the formatter's
    -- coloredName argument instead. All identity and message arguments pass through.
    CH.MessageFormatter = function(self, frame, info, chatType, chatGroup, chatTarget,
        channelLength, coloredName, historySavedName, arg1, arg2, arg3, arg4, arg5,
        arg6, arg7, arg8, arg9, arg10, arg11, arg12, ...)
        local ok, replacement = pcall(display, chatType, arg2, arg12)
        if ok and replacement then coloredName = replacement
        elseif not ok then errors = errors + 1 end
        return original(self, frame, info, chatType, chatGroup, chatTarget,
            channelLength, coloredName, historySavedName, arg1, arg2, arg3, arg4, arg5,
            arg6, arg7, arg8, arg9, arg10, arg11, arg12, ...)
    end
    local function refresh()
        local ok, ready = pcall(resolver.Refresh, resolver)
        state = ok and ready and 'ready' or 'WiW data unavailable'
        if not ok then errors = errors + 1 end
    end
    refresh()
    ns.ticker = C_Timer.NewTicker(1, refresh)
    installed = true
end

local frame = CreateFrame('Frame')
frame:RegisterEvent('PLAYER_LOGIN')
frame:SetScript('OnEvent', function()
    if type(ElvUIWhosWhoDB) ~= 'table' then ElvUIWhosWhoDB = {} end
    if ElvUIWhosWhoDB.enabled == nil then ElvUIWhosWhoDB.enabled = true end
    if ElvUIWhosWhoDB.mainStar == nil then ElvUIWhosWhoDB.mainStar = false end
    local ok = pcall(install)
    if not ok then state = 'initialization failed'; errors = errors + 1 end
end)

SLASH_ELVUIWHOSWHO1 = '/wiwbridge'
SlashCmdList.ELVUIWHOSWHO = function(command)
    if not ns.PlainString(command) then return end
    command = command:lower():match('^%s*(.-)%s*$')
    local db = settings()
    if command == 'on' then db.enabled = true
    elseif command == 'off' then db.enabled = false
    elseif command == 'star on' then db.mainStar = true
    elseif command == 'star off' then db.mainStar = false
    elseif command == 'refresh' then pcall(resolver.Refresh, resolver)
    elseif command ~= '' and command ~= 'status' then
        print('WiW Bridge: /wiwbridge on | off | star on | star off | refresh | status'); return
    end
    print('WiW Bridge: ' .. state .. '; enabled=' .. tostring(db.enabled)
        .. '; star=' .. tostring(db.mainStar) .. '; errors=' .. errors
        .. '; ElvUI=' .. tostring(metadata('ElvUI', 'Version'))
        .. '; WiW=' .. tostring(metadata('WhosWho', 'Version')))
end
