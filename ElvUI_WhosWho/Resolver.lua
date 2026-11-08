local _, ns = ...

local secret = issecretvalue or function() return false end
function ns.PlainString(value)
    return not secret(value) and type(value) == 'string'
end

local function guid(value)
    return ns.PlainString(value) and value:match('^Player%-%d+%-%x+$') ~= nil
end

local function nickname(value)
    return ns.PlainString(value) and #value > 0 and #value <= 100
        and not value:find('[%c|%[%]]') and value:find('%S') ~= nil
end

-- No own identity directory: only a disposable GUID index into WiW's live tables.
-- Rebuilt outside the chat hotpath. Never read private keys, notes or account data.
function ns.NewResolver(getData)
    local index, indexedData = {}, nil
    local resolver = {}

    function resolver:Refresh()
        index, indexedData = {}, nil
        local data = getData()
        if type(data) ~= 'table' or data.addonVersion ~= '1.0.1'
            or type(data.people) ~= 'table' or type(data.identity) ~= 'table' then return false end
        local nextIndex, count = {}, 0
        local function add(owner, own, key)
            if type(owner) ~= 'table' or type(owner.chars) ~= 'table' then return end
            for id, char in pairs(owner.chars) do
                count = count + 1
                if count > 50000 then return false end
                if guid(id) and type(char) == 'table' and (not own or char.linked == true) then
                    if nextIndex[id] ~= nil then
                        nextIndex[id] = false -- Ambiguous even when nicknames are identical.
                    else
                        nextIndex[id] = { owner = owner, own = own, key = key, char = char }
                    end
                end
            end
            return true
        end
        if add(data.identity, true) == false then return false end
        for key, person in pairs(data.people) do
            count = count + 1
            if count > 50000 or add(person, false, key) == false then return false end
        end
        index, indexedData = nextIndex, data
        return true
    end

    function resolver:Resolve(id)
        if not guid(id) then return end
        local data = getData()
        if data ~= indexedData or type(data) ~= 'table' or data.addonVersion ~= '1.0.1' then return end
        local entry = index[id]
        if not entry then return end
        local owner, char = entry.owner, entry.char
        if (entry.own and data.identity ~= owner)
            or (not entry.own and data.people[entry.key] ~= owner)
            or owner.chars[id] ~= char or owner.outdated
            or (data.noIdentity and data.noIdentity[id]) then return end
        if entry.own then
            if char.linked ~= true or char.removedAt then return end
        elseif char.state ~= 'confirmed' and char.state ~= 'added' and char.state ~= 'guild' then
            return -- Listed/relayed records have not confirmed this sender.
        end
        local main = guid(owner.main) and owner.chars[owner.main]
        if not main and type(owner.signedRecord) == 'table' and type(owner.signedRecord.chars) == 'table'
            and guid(owner.main) then main = owner.signedRecord.chars[owner.main] end
        local name
        if entry.own then
            if not main or main.linked ~= true then return end
            name = owner.nickname or main.name
        else
            name = owner.customNickname or owner.nickname or (main and main.name)
        end
        if not nickname(name) then return end
        -- person.main may be a guild-specific display main. Only the signed global
        -- main (or an explicitly maintained manual identity) can earn the star.
        local mainGuid
        if entry.own then
            mainGuid = owner.main
        elseif type(owner.signedRecord) == 'table' then
            mainGuid = owner.signedRecord.main
        elseif ns.PlainString(entry.key) and entry.key:match('^M%d+$') then
            mainGuid = owner.main
        end
        return name, guid(mainGuid) and mainGuid == id or false
    end

    return resolver
end
