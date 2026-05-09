local addonName, ns = ...

ns.SoundKitLibrary = ns.SoundKitLibrary or {
    classes = {},
    classSpellKeys = {},
    misc = {},
}

function ns.RegisterClassSoundKits(classToken, entries)
    if type(classToken) ~= "string" then
        return
    end
    if type(entries) ~= "table" then
        return
    end
    ns.SoundKitLibrary.classes[classToken:upper()] = entries
end

function ns.RegisterMiscSoundKits(entries)
    if type(entries) ~= "table" then
        return
    end
    ns.SoundKitLibrary.misc = entries
end

function ns.RegisterClassSpellKeys(classToken, entries)
    if type(classToken) ~= "string" then
        return
    end
    if type(entries) ~= "table" then
        return
    end
    ns.SoundKitLibrary.classSpellKeys[classToken:upper()] = entries
end
