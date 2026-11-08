-- Synthetic identities only. Also run the actual installed formatter when supplied.
local unpack = unpack or table.unpack
local loadstring = loadstring or load
local checks = 0
local function eq(actual, expected)
    checks = checks + 1
    assert(actual == expected, 'check ' .. checks .. ': ' .. tostring(actual) .. ' ~= ' .. tostring(expected))
end
local function contains(s, part) assert(s:find(part, 1, true), s); checks = checks + 1 end
local ns = {}
local secretValue = setmetatable({}, { __tostring = function() error('secret read') end })
issecretvalue = function(v) return v == secretValue end
assert(loadfile(ROOT .. '/ElvUI_WhosWho/Resolver.lua'))('ElvUI_WhosWho', ns)
local main, alt, unknown = 'Player-1-0001', 'Player-1-0002', 'Player-1-0099'
local own = 'Player-1-0003'
local person = { main = main, nickname = 'Buddy', chars = {
    [main] = { name = 'Example Main', state = 'confirmed' },
    [alt] = { name = 'Example Alt', state = 'confirmed' },
}, signedRecord = { main = main } }
local data = { addonVersion = '1.0.1', identity = { main = own, chars = {
    [own] = { name = 'Own Example', linked = true },
} }, people = { P1 = person }, noIdentity = {} }
local r = ns.NewResolver(function() return data end)
eq(r:Refresh(), true)
eq(r:Resolve(main), 'Buddy'); eq(r:Resolve(alt), 'Buddy')
local _, isMain = r:Resolve(main); eq(isMain, true)
_, isMain = r:Resolve(alt); eq(isMain, false)
eq(r:Resolve(own), 'Own Example'); eq(r:Resolve(unknown), nil)
eq(r:Resolve(secretValue), nil)
person.customNickname = 'Local Buddy'; eq(r:Resolve(alt), 'Local Buddy')
person.customNickname = '|Hplayer:Bad|hBad|h'; eq(r:Resolve(alt), nil)
person.customNickname = nil
person.outdated = true; eq(r:Resolve(alt), nil); person.outdated = nil
person.chars[alt].state = 'listed'; eq(r:Resolve(alt), nil)
person.chars[alt].state = 'relayed'; eq(r:Resolve(alt), nil)
person.chars[alt].state = 'added'; eq(r:Resolve(alt), 'Buddy')
person.chars[alt].state = 'confirmed'
data.noIdentity[alt] = 1; eq(r:Resolve(alt), nil); data.noIdentity[alt] = nil
data.people.duplicate = { nickname = 'Buddy', chars = { [alt] = {} } }
r:Refresh(); eq(r:Resolve(alt), nil)
data.people.duplicate = nil; r:Refresh(); eq(r:Resolve(alt), 'Buddy')
local old = person.chars[alt]; person.chars[alt] = nil
eq(r:Resolve(alt), nil); person.chars[alt] = old
person.main = alt -- Guild display main must not become the true main.
_, isMain = r:Resolve(alt); eq(isMain, false); person.main = main
data.addonVersion = 'future'; eq(r:Resolve(main), nil); eq(r:Refresh(), false)
data.addonVersion = '1.0.1'; r:Refresh()
-- Verify the adapter does not mutate any WiW fields, even with metatables.
setmetatable(person, { __newindex = function() error('write to WiW') end })
eq(r:Resolve(main), 'Buddy')

-- Minimal game services. All original formatter arguments are captured verbatim.
SlashCmdList = {}; C_AddOns = {}
local versions = { ElvUI = 'v16.01', WhosWho = '1.0.1' }
C_AddOns.GetAddOnMetadata = function(name) return versions[name] end
local ticks = {}
C_Timer = { NewTicker = function(_, fn) ticks[#ticks + 1] = fn; return {} end }
local frames = {}
CreateFrame = function()
    local f = { RegisterEvent = function() end }
    f.SetScript = function(_, _, callback) f.callback = callback end
    frames[#frames + 1] = f; return f
end
GetPlayerInfoByGUID = function(id)
    if id == main then return 'Warrior', 'WARRIOR' end
    if id == alt then return 'Mage', 'MAGE' end
end
E = { Forever = true, private = { chat = { enable = true } } }
E.IsSecretValue = function(_, v) return issecretvalue(v) end
E.NotSecretValue = function(_, v) return not issecretvalue(v) end
E.ClassColor = function(_, class)
    local color = class == 'MAGE' and 'ff3fc7eb' or 'ffc79c6e'
    return { WrapTextInColorCode = function(_, name) return '|c' .. color .. name .. '|r' end }
end
CH = { db = {}, PluginMessageFilters = {} }
E.GetModule = function() return CH end
ElvUI = { E }; WhosWhoDB = { global = data }
local calls, lastArgs = 0
local original = function(...)
    calls = calls + 1; lastArgs = { n = select('#', ...), ... }
    return select(8, ...), 'second return'
end
CH.MessageFormatter = original
assert(loadfile(ROOT .. '/ElvUI_WhosWho/Bridge.lua'))('ElvUI_WhosWho', ns)
frames[1].callback()
local formatter = CH.MessageFormatter
local message = 'Example Main says 100% |Hplayer:Example Alt|h[Example Alt]|h'
local function invoke(kind, id, text)
    return CH:MessageFormatter({}, {}, kind, kind, nil, 0, 'Original', nil,
        text or message, 'Example Main', '', '', '', '', 0, 0, nil, nil, 42, id,
        nil, false, nil, nil, false, nil, true, nil, 'history', nil)
end
eq(invoke('GUILD', main), '|cffc79c6eBuddy|r')
eq(lastArgs[10], message); eq(lastArgs[11], 'Example Main'); eq(lastArgs[21], main)
eq(lastArgs.n, 31); eq(lastArgs[30], 'history')
eq(invoke('PARTY', alt), '|cff3fc7ebBuddy|r')
eq(invoke('WHISPER', unknown), 'Original')
eq(invoke('BN_WHISPER', main), 'Original')
eq(invoke('MONSTER_SAY', main), 'Original')
eq(invoke('SAY', secretValue), 'Original')
eq(invoke('SAY', own), 'Own Example') -- no known class, normal chat color
SlashCmdList.ELVUIWHOSWHO('star on')
contains(invoke('GUILD', main), 'UI-RaidTargetingIcon_1')
eq(invoke('GUILD', alt), '|cff3fc7ebBuddy|r')
SlashCmdList.ELVUIWHOSWHO('off'); eq(invoke('GUILD', main), 'Original')
SlashCmdList.ELVUIWHOSWHO('on'); SlashCmdList.ELVUIWHOSWHO('star off')
local saved = GetPlayerInfoByGUID
GetPlayerInfoByGUID = function() error('API failure') end
local before = calls; eq(invoke('GUILD', main), 'Original'); eq(calls, before + 1)
GetPlayerInfoByGUID = saved
local a, b = invoke('GUILD', main); eq(b, 'second return')
-- The timer owns full scans; a burst must resolve without calling pairs at all.
local nativePairs = pairs
pairs = function() error('full scan in chat hotpath') end
local passed = true
for i = 1, 1000 do
    if invoke('GUILD', alt) ~= '|cff3fc7ebBuddy|r' then passed = false; break end
end
pairs = nativePairs
eq(passed, true)
person.nickname = 'Changed Buddy'; ticks[1]()
eq(invoke('GUILD', alt), '|cff3fc7ebChanged Buddy|r')
person.nickname = 'Buddy'; ticks[1]()
-- Missing/unsupported integrations install no wrapper, no timer and never throw.
local function disabled(setup)
    CH.MessageFormatter = original
    setup()
    local count = #ticks
    assert(loadfile(ROOT .. '/ElvUI_WhosWho/Bridge.lua'))('ElvUI_WhosWho', ns)
    frames[#frames].callback()
    eq(CH.MessageFormatter, original); eq(#ticks, count)
    versions.ElvUI = 'v16.01'; versions.WhosWho = '1.0.1'
    E.private.chat.enable = true; ElvUI = { E }
end
disabled(function() versions.WhosWho = nil end)
disabled(function() versions.ElvUI = 'future' end)
disabled(function() E.private.chat.enable = false end)
disabled(function() ElvUI = nil end)

if ELVUI_FORMATTER then
    -- Real ElvUI v16.01 function, with game services stubbed. No upstream code is bundled.
    format = string.format; strsub = string.sub; gsub = string.gsub; strmatch = string.match
    specialChatIcons = {}; lfgRoles = {}
    RemoveExtraSpaces = function(v) return v end
    CanChatGroupPerformExpressionExpansion = function() return false end
    CH.MessageIsProtected = function() return false end
    CH.ChatFrame_ReplaceIconAndGroupExpressions = function(_, v) return v end
    CH.GetPlayerInfoByGUID = function() return nil end
    CH.GetDiscordInfo = function() return nil, false end
    CH.GetPluginIcon = function() end
    CH.GetPFlag = function() return '' end
    CH.GetPlayerLink = function(_, name, display, line, group)
        return '|Hplayer:' .. name .. ':' .. line .. ':' .. group .. '|h' .. display .. '|h'
    end
    for _, kind in ipairs({ 'GUILD', 'SAY', 'YELL', 'WHISPER', 'WHISPER_INFORM', 'PARTY',
        'RAID', 'OFFICER', 'CHANNEL', 'EMOTE' }) do
        _G['CHAT_' .. kind .. '_GET'] = '%s: '
    end
    assert(loadstring(ELVUI_FORMATTER))()
    local native = CH.MessageFormatter
    assert(loadfile(ROOT .. '/ElvUI_WhosWho/Bridge.lua'))('ElvUI_WhosWho', ns)
    frames[#frames].callback()
    for _, kind in ipairs({ 'GUILD', 'SAY', 'YELL', 'WHISPER', 'WHISPER_INFORM', 'PARTY',
        'RAID', 'OFFICER', 'EMOTE' }) do
        local body = invoke(kind, alt)
        contains(body, '|Hplayer:Example Main:42:' .. kind .. '|h')
        contains(body, '|cff3fc7ebBuddy|r')
        contains(body, message) -- embedded player link and message are byte-identical
    end
    CHAT_TEXT_EMOTE_GET = '%s'
    local body = invoke('TEXT_EMOTE', alt, 'Example Main waves at Example Main.')
    contains(body, 'Buddy|r|h waves at Example Main.')
    eq(CHAT_SAY_GET, '%s: ')
    print('Installed ElvUI formatter integration passed')
end
print(checks .. ' assertions passed')
