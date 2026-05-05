local addonName, ns = ...

local ADDON_TITLE = "PacopaoQOL"
local DB_NAME = "PacopaoQOLDB"
local settingsCategoryID
local SettingsLib = LibStub and LibStub("LibEQOLSettingsMode-1.0", true)

local defaults = {
    profile = {
        sonido_reenviar_efectos = false,
        sonido_canal_efectos = "Master", -- Valores internos de WoW: Master, Music, Ambience, Dialog
        sonido_mantener_audio_sincronizado = false,
        ui_indicador_zona_montura = false,
        ui_indicador_zona_montura_pos = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 60,
        },
        ui_indicador_zona_montura_desbloqueado = false,
        ui_indicador_zona_montura_escala = 1,
        combat_melee_indicator_enabled = false,
        combat_melee_indicator_size = 32,
        combat_melee_indicator_opacity = 1,
        combat_melee_indicator_unlocked = false,
        combat_melee_indicator_pos = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 0,
        },
        grupos_auto_confirm_role_checks = false,
    },
}

local ignoredSoundIDs = {
    [218234] = true,
    [31580] = true,
    [314204] = true,
}

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff" .. ADDON_TITLE .. "|r: " .. msg)
end

local function EnsureDB()
    _G[DB_NAME] = _G[DB_NAME] or {}
    PacopaoQOLDB = _G[DB_NAME]
    PacopaoQOLDB.profile = PacopaoQOLDB.profile or {}

    for key, value in pairs(defaults.profile) do
        if PacopaoQOLDB.profile[key] == nil then
            PacopaoQOLDB.profile[key] = value
        end
    end
end

local function GetProfile()
    return PacopaoQOLDB and PacopaoQOLDB.profile
end

local function IsForwardEnabled()
    local p = GetProfile()
    return p and p.sonido_reenviar_efectos == true
end

local function GetForwardChannel()
    local p = GetProfile()
    return (p and p.sonido_canal_efectos) or "Master"
end

local function IsCinematicPlaying()
    local cinematicShown = CinematicFrame and CinematicFrame.IsShown and CinematicFrame:IsShown()
    local movieShown = MovieFrame and MovieFrame.IsShown and MovieFrame:IsShown()
    return cinematicShown or movieShown
end

local function ApplyAudioSync()
    if not SetCVar then
        return
    end
    SetCVar("Sound_OutputDriverIndex", "0")
    if Sound_GameSystem_RestartSoundSystem and not IsCinematicPlaying() then
        Sound_GameSystem_RestartSoundSystem()
    end
end

local function UpdateAudioSync()
    if not audioSyncFrame then
        audioSyncFrame = CreateFrame("Frame")
        audioSyncFrame:SetScript("OnEvent", function()
            local p = GetProfile()
            if p and p.sonido_mantener_audio_sincronizado then
                ApplyAudioSync()
            end
        end)
    end

    audioSyncFrame:UnregisterEvent("VOICE_CHAT_OUTPUT_DEVICES_UPDATED")

    local p = GetProfile()
    if p and p.sonido_mantener_audio_sincronizado then
        audioSyncFrame:RegisterEvent("VOICE_CHAT_OUTPUT_DEVICES_UPDATED")
        ApplyAudioSync()
    end
end

local isReplaying = false
local mountIndicatorFrame
local mountIndicatorEditMode = false
local meleeIndicatorFrame
local meleeIndicatorTicker
local meleeIndicatorEventsFrame
local audioSyncFrame
local roleCheckAutoConfirmInitialized = false
local function IsBlizzardEditModeActive()
    return EditModeManagerFrame and EditModeManagerFrame:IsShown()
end

local function IsAutoConfirmRoleChecksEnabled()
    local p = GetProfile()
    return p and p.grupos_auto_confirm_role_checks == true
end

local function InitAutoConfirmRoleChecks()
    if roleCheckAutoConfirmInitialized then
        return
    end
    roleCheckAutoConfirmInitialized = true

    if not LFDRoleCheckPopupAcceptButton then
        return
    end

    LFDRoleCheckPopupAcceptButton:HookScript("OnShow", function(self)
        if IsAutoConfirmRoleChecksEnabled() then
            self:Click()
        end
    end)
end

hooksecurefunc("PlaySound", function(soundKitID, channel)
    if isReplaying then
        return
    end

    if not IsForwardEnabled() then
        return
    end

    if channel and channel ~= "SFX" then
        return
    end

    if not soundKitID or ignoredSoundIDs[soundKitID] then
        return
    end

    isReplaying = true
    PlaySound(soundKitID, GetForwardChannel(), true)
    isReplaying = false
end)

local function EnsureMountIndicator()
    if mountIndicatorFrame then
        return mountIndicatorFrame
    end

    mountIndicatorFrame = CreateFrame("Frame", "PacopaoQOLMountIndicator", UIParent)
    mountIndicatorFrame:SetSize(32, 32)
    mountIndicatorFrame:SetMovable(true)
    mountIndicatorFrame:EnableMouse(false)
    mountIndicatorFrame:RegisterForDrag("LeftButton")
    mountIndicatorFrame:Hide()

    mountIndicatorFrame.icon = mountIndicatorFrame:CreateTexture(nil, "OVERLAY")
    mountIndicatorFrame.icon:SetAllPoints()
    mountIndicatorFrame.icon:SetAtlas("Fyrakk-Flying-Icon", true)
    mountIndicatorFrame.icon:SetVertexColor(1, 0.82, 0, 1)

    mountIndicatorFrame.bg = mountIndicatorFrame:CreateTexture(nil, "BACKGROUND")
    mountIndicatorFrame.bg:SetAllPoints()
    mountIndicatorFrame.bg:SetColorTexture(0, 0, 0, 0.35)
    mountIndicatorFrame.bg:Hide()

    mountIndicatorFrame.text = mountIndicatorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mountIndicatorFrame.text:SetPoint("TOP", mountIndicatorFrame, "BOTTOM", 0, -4)
    mountIndicatorFrame.text:SetText("Arrastra")
    mountIndicatorFrame.text:Hide()

    mountIndicatorFrame:SetScript("OnDragStart", function(self)
        local p = GetProfile()
        local unlocked = p and p.ui_indicador_zona_montura_desbloqueado == true
        if not mountIndicatorEditMode and not unlocked then
            return
        end
        self:StartMoving()
    end)

    mountIndicatorFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p = GetProfile()
        if not p then
            return
        end
        local point, _, relativePoint, x, y = self:GetPoint(1)
        p.ui_indicador_zona_montura_pos.point = point or "CENTER"
        p.ui_indicador_zona_montura_pos.relativePoint = relativePoint or "CENTER"
        p.ui_indicador_zona_montura_pos.x = x or 0
        p.ui_indicador_zona_montura_pos.y = y or 60
    end)

    return mountIndicatorFrame
end

local function IsMountIndicatorUnlocked()
    local p = GetProfile()
    return p and p.ui_indicador_zona_montura_desbloqueado == true
end

local function ApplyMountIndicatorScale()
    local frame = EnsureMountIndicator()
    local p = GetProfile()
    local scale = (p and p.ui_indicador_zona_montura_escala) or 1
    scale = math.max(0.5, math.min(2, scale))
    local size = 32 * scale
    frame:SetScale(1)
    frame:SetSize(size, size)
end

local function ApplyMountIndicatorPosition()
    local frame = EnsureMountIndicator()
    local p = GetProfile()
    if not p then
        return
    end

    local pos = p.ui_indicador_zona_montura_pos or defaults.profile.ui_indicador_zona_montura_pos
    frame:ClearAllPoints()
    frame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 60)
end

local function IsMountableNow()
    return C_Spell and C_Spell.IsSpellUsable and C_Spell.IsSpellUsable(23214)
end

local function RefreshMountIndicator()
    local p = GetProfile()
    local frame = EnsureMountIndicator()
    local unlocked = IsMountIndicatorUnlocked()

    if not p or not p.ui_indicador_zona_montura then
        if mountIndicatorEditMode or unlocked then
            frame:Show()
        end
        if not mountIndicatorEditMode and not unlocked then
            frame:Hide()
        end
        return
    end

    if mountIndicatorEditMode or unlocked then
        frame:Show()
        return
    end

    if IsMountableNow() then
        frame:Show()
    else
        frame:Hide()
    end
end

local function RegisterMountIndicatorEvents()
    local frame = EnsureMountIndicator()
    if frame._pqolEventsRegistered then
        return
    end

    frame._pqolEventsRegistered = true
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    frame:SetScript("OnEvent", RefreshMountIndicator)
end

local function SetMountIndicatorEditMode(enabled)
    local frame = EnsureMountIndicator()
    mountIndicatorEditMode = enabled and true or false
    frame:EnableMouse(mountIndicatorEditMode or IsMountIndicatorUnlocked())
    frame:SetClampedToScreen(mountIndicatorEditMode or IsMountIndicatorUnlocked())
    frame.bg:SetShown(mountIndicatorEditMode or IsMountIndicatorUnlocked())
    frame.text:SetShown(mountIndicatorEditMode or IsMountIndicatorUnlocked())
    RefreshMountIndicator()
end

local meleeSpellIDBySpecID = {
    [250] = 316239, [251] = 316239, [252] = 49998,
    [577] = 162794, [581] = 344859,
    [103] = 5221, [104] = 5221,
    [255] = 186270,
    [268] = 205523, [269] = 205523,
    [66] = 96231, [70] = 96231,
    [259] = 1752, [260] = 1752, [261] = 1752,
    [263] = 17364,
    [71] = 1464, [72] = 1464, [73] = 23922,
}

local function IsMeleeIndicatorUnlocked()
    local p = GetProfile()
    return p and p.combat_melee_indicator_unlocked == true
end

local function EnsureMeleeIndicator()
    if meleeIndicatorFrame then
        return meleeIndicatorFrame
    end

    meleeIndicatorFrame = CreateFrame("Frame", "PacopaoQOLMeleeIndicator", UIParent)
    meleeIndicatorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    meleeIndicatorFrame:SetFrameStrata("DIALOG")
    meleeIndicatorFrame:SetFrameLevel(200)
    meleeIndicatorFrame:SetMovable(true)
    meleeIndicatorFrame:EnableMouse(false)
    meleeIndicatorFrame:RegisterForDrag("LeftButton")
    meleeIndicatorFrame:Hide()

    meleeIndicatorFrame.tex = meleeIndicatorFrame:CreateTexture(nil, "ARTWORK")
    meleeIndicatorFrame.tex:SetAllPoints()
    meleeIndicatorFrame.tex:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")

    meleeIndicatorFrame.bg = meleeIndicatorFrame:CreateTexture(nil, "BACKGROUND")
    meleeIndicatorFrame.bg:SetAllPoints()
    meleeIndicatorFrame.bg:SetColorTexture(0, 0, 0, 0.35)
    meleeIndicatorFrame.bg:Hide()

    meleeIndicatorFrame.text = meleeIndicatorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    meleeIndicatorFrame.text:SetPoint("TOP", meleeIndicatorFrame, "BOTTOM", 0, -4)
    meleeIndicatorFrame.text:SetText("Arrastra")
    meleeIndicatorFrame.text:Hide()

    meleeIndicatorFrame:SetScript("OnDragStart", function(self)
        if not IsMeleeIndicatorUnlocked() and not IsBlizzardEditModeActive() then
            return
        end
        self:StartMoving()
    end)
    meleeIndicatorFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p = GetProfile()
        if not p then
            return
        end
        local point, _, relativePoint, x, y = self:GetPoint(1)
        p.combat_melee_indicator_pos.point = point or "CENTER"
        p.combat_melee_indicator_pos.relativePoint = relativePoint or "CENTER"
        p.combat_melee_indicator_pos.x = x or 0
        p.combat_melee_indicator_pos.y = y or 0
    end)

    return meleeIndicatorFrame
end

local function ApplyMeleeIndicatorPosition()
    local frame = EnsureMeleeIndicator()
    local p = GetProfile()
    local pos = (p and p.combat_melee_indicator_pos) or defaults.profile.combat_melee_indicator_pos
    frame:ClearAllPoints()
    frame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
end

local function ApplyMeleeIndicatorStyle()
    local frame = EnsureMeleeIndicator()
    local p = GetProfile()
    if not p then
        return
    end

    local size = math.max(12, math.min(96, p.combat_melee_indicator_size or 32))
    local opacity = math.max(0.05, math.min(1, p.combat_melee_indicator_opacity or 1))

    frame:SetSize(size, size)
    frame:SetAlpha(opacity)
    frame.tex:SetVertexColor(1, 1, 1, 1)
end

local function IsValidMeleeTarget()
    return UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target")
end

local function IsOutOfMeleeRange()
    local specID = PlayerUtil.GetCurrentSpecID()
    local spellID = meleeSpellIDBySpecID[specID]
    if spellID then
        local inRange = C_Spell.IsSpellInRange(spellID, "target")
        if inRange ~= nil then
            return inRange == false
        end
    end
    local autoAttackRange = C_Spell.IsSpellInRange(6603, "target")
    if autoAttackRange ~= nil then
        return autoAttackRange == false
    end
    local interactRange = CheckInteractDistance("target", 3)
    if interactRange ~= nil then
        return interactRange == false
    end
    return false
end

local function RefreshMeleeIndicator()
    local p = GetProfile()
    local frame = EnsureMeleeIndicator()
    if not p or not p.combat_melee_indicator_enabled then
        if IsMeleeIndicatorUnlocked() then
            frame:Show()
            frame.bg:Show()
            frame.text:Show()
            frame:EnableMouse(true)
            return
        end
        frame:Hide()
        return
    end
    if IsBlizzardEditModeActive() then
        frame:Show()
        frame.bg:Show()
        frame.text:Show()
        frame:EnableMouse(true)
        return
    end
    if IsMeleeIndicatorUnlocked() then
        frame:Show()
        frame.bg:Show()
        frame.text:Show()
        frame:EnableMouse(true)
        return
    end
    frame.bg:Hide()
    frame.text:Hide()
    frame:EnableMouse(false)
    if not IsValidMeleeTarget() then
        frame:Hide()
        return
    end
    if IsOutOfMeleeRange() then
        frame:Show()
    else
        frame:Hide()
    end
end

local function StartMeleeIndicatorTicker()
    if meleeIndicatorTicker then
        return
    end
    meleeIndicatorTicker = C_Timer.NewTicker(0.1, RefreshMeleeIndicator)
end

local function EnsureMeleeIndicatorEvents()
    if meleeIndicatorEventsFrame then
        return
    end
    meleeIndicatorEventsFrame = CreateFrame("Frame")
    meleeIndicatorEventsFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    meleeIndicatorEventsFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    meleeIndicatorEventsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    meleeIndicatorEventsFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    meleeIndicatorEventsFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    meleeIndicatorEventsFrame:SetScript("OnEvent", RefreshMeleeIndicator)
end

local function SyncWithBlizzardEditMode()
    SetMountIndicatorEditMode(IsBlizzardEditModeActive())
end

local function HookBlizzardEditMode()
    if not EditModeManagerFrame then
        return
    end
    if EditModeManagerFrame._pqolHooked then
        return
    end
    EditModeManagerFrame._pqolHooked = true
    EditModeManagerFrame:HookScript("OnShow", SyncWithBlizzardEditMode)
    EditModeManagerFrame:HookScript("OnHide", SyncWithBlizzardEditMode)
end

local function CreateSettings()
    local rootCategory, rootLayout = Settings.RegisterVerticalLayoutCategory(ADDON_TITLE)
    Settings.RegisterAddOnCategory(rootCategory)
    settingsCategoryID = rootCategory:GetID()

    local soundCategory, soundLayout = Settings.RegisterVerticalLayoutSubcategory(rootCategory, "Sonido")
    local mountsCategory, mountsLayout = Settings.RegisterVerticalLayoutSubcategory(rootCategory, "Monturas")
    local combatCategory, combatLayout = Settings.RegisterVerticalLayoutSubcategory(rootCategory, "Combate")
    local groupsCategory, groupsLayout = Settings.RegisterVerticalLayoutSubcategory(rootCategory, "Grupos")

    local function AddFeatureHeader(layout, title)
        local header = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", {
            name = "|cffffffff" .. title .. "|r",
        })
        layout:AddInitializer(header)
    end

    local soundSectionExpandedPredicate = nil
    if SettingsLib and SettingsLib.CreateExpandableSection then
        local _, isExpanded = SettingsLib:CreateExpandableSection(soundCategory, {
            name = "Canal de Efectos UI",
            expanded = true,
            colorizeTitle = true,
        })
        soundSectionExpandedPredicate = isExpanded
    else
        AddFeatureHeader(soundLayout, "Canal de Efectos UI")
    end

    local settingEnable = Settings.RegisterProxySetting(
        soundCategory,
        "PACOQOL_sonido_reenviar_efectos",
        Settings.VarType.Boolean,
        "Separar efectos UI del combate",
        false,
        function()
            return IsForwardEnabled()
        end,
        function(value)
            local p = GetProfile()
            p.sonido_reenviar_efectos = value and true or false
        end
    )

    local enableTooltip = "Reenvía los sonidos de interfaz a otro canal para que no se mezclen con SFX de combate."
    local soundEnableCheckbox = Settings.CreateCheckbox(soundCategory, settingEnable, enableTooltip)
    if soundSectionExpandedPredicate then
        soundEnableCheckbox:AddShownPredicate(soundSectionExpandedPredicate)
    end

    local channels = {
        Master = "Principal",
        Music = "Música",
        Ambience = "Ambiente",
        Dialog = "Diálogo",
    }

    local function GetChannelOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("Master", channels.Master)
        container:Add("Music", channels.Music)
        container:Add("Ambience", channels.Ambience)
        container:Add("Dialog", channels.Dialog)
        return container:GetData()
    end

    local settingChannel = Settings.RegisterProxySetting(
        soundCategory,
        "PACOQOL_sonido_canal_efectos",
        Settings.VarType.String,
        "Canal de salida",
        "Master",
        function()
            return GetForwardChannel()
        end,
        function(value)
            local p = GetProfile()
            p.sonido_canal_efectos = value
        end
    )

    local dropdown = Settings.CreateDropdown(
        soundCategory,
        settingChannel,
        GetChannelOptions,
        "Canal donde se reproducirán los sonidos UI reenviados."
    )

    dropdown:AddModifyPredicate(function()
        return IsForwardEnabled()
    end)
    if soundSectionExpandedPredicate then
        dropdown:AddShownPredicate(soundSectionExpandedPredicate)
    end

    local settingAudioSync = Settings.RegisterProxySetting(
        soundCategory,
        "PACOQOL_sonido_mantener_audio_sincronizado",
        Settings.VarType.Boolean,
        "Mantener audio sincronizado",
        false,
        function()
            local p = GetProfile()
            return p and p.sonido_mantener_audio_sincronizado == true
        end,
        function(value)
            local p = GetProfile()
            p.sonido_mantener_audio_sincronizado = value and true or false
            UpdateAudioSync()
        end
    )
    local soundSyncCheckbox = Settings.CreateCheckbox(
        soundCategory,
        settingAudioSync,
        "Reinicia audio si cambia el dispositivo de salida para evitar desincronización."
    )
    if soundSectionExpandedPredicate then
        soundSyncCheckbox:AddShownPredicate(soundSectionExpandedPredicate)
    end

    local mountsSectionExpandedPredicate = nil
    if SettingsLib and SettingsLib.CreateExpandableSection then
        local _, isExpanded = SettingsLib:CreateExpandableSection(mountsCategory, {
            name = "Indicador de Zona Montable",
            expanded = true,
            colorizeTitle = true,
        })
        mountsSectionExpandedPredicate = isExpanded
    else
        AddFeatureHeader(mountsLayout, "Indicador de Zona Montable")
    end

    local settingMountIndicator = Settings.RegisterProxySetting(
        mountsCategory,
        "PACOQOL_ui_indicador_zona_montura",
        Settings.VarType.Boolean,
        "Indicador de zona montable",
        false,
        function()
            local p = GetProfile()
            return p and p.ui_indicador_zona_montura == true
        end,
        function(value)
            local p = GetProfile()
            p.ui_indicador_zona_montura = value and true or false
            RefreshMountIndicator()
        end
    )

    local mountIndicatorCheckbox = Settings.CreateCheckbox(
        mountsCategory,
        settingMountIndicator,
        "Muestra un icono cuando puedes montar en la zona actual."
    )
    if mountsSectionExpandedPredicate then
        mountIndicatorCheckbox:AddShownPredicate(mountsSectionExpandedPredicate)
    end

    local settingMountUnlock = Settings.RegisterProxySetting(
        mountsCategory,
        "PACOQOL_ui_indicador_zona_montura_desbloqueado",
        Settings.VarType.Boolean,
        "Desbloquear icono",
        false,
        function()
            return IsMountIndicatorUnlocked()
        end,
        function(value)
            local p = GetProfile()
            p.ui_indicador_zona_montura_desbloqueado = value and true or false
            SetMountIndicatorEditMode(IsBlizzardEditModeActive())
        end
    )

    local mountUnlockCheckbox = Settings.CreateCheckbox(
        mountsCategory,
        settingMountUnlock,
        "Permite mover el icono fuera del Modo Edición de Blizzard."
    )
    if mountsSectionExpandedPredicate then
        mountUnlockCheckbox:AddShownPredicate(mountsSectionExpandedPredicate)
    end

    local settingMountScale = Settings.RegisterProxySetting(
        mountsCategory,
        "PACOQOL_ui_indicador_zona_montura_escala",
        Settings.VarType.Number,
        "Tamaño del icono",
        1,
        function()
            local p = GetProfile()
            return (p and p.ui_indicador_zona_montura_escala) or 1
        end,
        function(value)
            local p = GetProfile()
            p.ui_indicador_zona_montura_escala = value
            ApplyMountIndicatorScale()
        end
    )

    local sliderOptions = Settings.CreateSliderOptions(0.5, 2, 0.05)
    sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return string.format("%.2f", value)
    end)
    local mountScaleSlider =
        Settings.CreateSlider(mountsCategory, settingMountScale, sliderOptions, "Escala visual del icono.")
    if mountsSectionExpandedPredicate then
        mountScaleSlider:AddShownPredicate(mountsSectionExpandedPredicate)
    end

    local combatSectionExpandedPredicate = nil
    if SettingsLib and SettingsLib.CreateExpandableSection then
        local _, isExpanded = SettingsLib:CreateExpandableSection(combatCategory, {
            name = "Indicador de Rango Melee",
            expanded = true,
            colorizeTitle = true,
        })
        combatSectionExpandedPredicate = isExpanded
    else
        AddFeatureHeader(combatLayout, "Indicador de Rango Melee")
    end

    local settingMeleeEnable = Settings.RegisterProxySetting(
        combatCategory,
        "PACOQOL_combat_melee_indicator_enabled",
        Settings.VarType.Boolean,
        "indicador rango de melee",
        false,
        function()
            local p = GetProfile()
            return p and p.combat_melee_indicator_enabled == true
        end,
        function(value)
            local p = GetProfile()
            p.combat_melee_indicator_enabled = value and true or false
            RefreshMeleeIndicator()
        end
    )
    local meleeEnableCheckbox = Settings.CreateCheckbox(
        combatCategory,
        settingMeleeEnable,
        "Muestra una cruz cuando el objetivo está fuera de rango melee."
    )
    if combatSectionExpandedPredicate then
        meleeEnableCheckbox:AddShownPredicate(combatSectionExpandedPredicate)
    end

    local settingMeleeUnlock = Settings.RegisterProxySetting(
        combatCategory,
        "PACOQOL_combat_melee_indicator_unlocked",
        Settings.VarType.Boolean,
        "Desbloquear cruz",
        false,
        function()
            return IsMeleeIndicatorUnlocked()
        end,
        function(value)
            local p = GetProfile()
            p.combat_melee_indicator_unlocked = value and true or false
            RefreshMeleeIndicator()
        end
    )
    local meleeUnlockCheckbox = Settings.CreateCheckbox(
        combatCategory,
        settingMeleeUnlock,
        "Permite mover la cruz fuera del Modo Edición."
    )
    if combatSectionExpandedPredicate then
        meleeUnlockCheckbox:AddShownPredicate(combatSectionExpandedPredicate)
    end

    local settingMeleeSize = Settings.RegisterProxySetting(
        combatCategory,
        "PACOQOL_combat_melee_indicator_size",
        Settings.VarType.Number,
        "Tamaño",
        32,
        function()
            local p = GetProfile()
            return (p and p.combat_melee_indicator_size) or 32
        end,
        function(value)
            local p = GetProfile()
            p.combat_melee_indicator_size = value
            ApplyMeleeIndicatorStyle()
            RefreshMeleeIndicator()
        end
    )
    local meleeSizeOptions = Settings.CreateSliderOptions(12, 96, 1)
    meleeSizeOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return string.format("%d", value)
    end)
    local meleeSizeSlider = Settings.CreateSlider(combatCategory, settingMeleeSize, meleeSizeOptions, "Tamaño de la cruz.")
    if combatSectionExpandedPredicate then
        meleeSizeSlider:AddShownPredicate(combatSectionExpandedPredicate)
    end
    meleeSizeSlider:AddModifyPredicate(function()
        local p = GetProfile()
        return p and p.combat_melee_indicator_enabled == true
    end)

    local settingMeleeOpacity = Settings.RegisterProxySetting(
        combatCategory,
        "PACOQOL_combat_melee_indicator_opacity",
        Settings.VarType.Number,
        "Opacidad",
        1,
        function()
            local p = GetProfile()
            return (p and p.combat_melee_indicator_opacity) or 1
        end,
        function(value)
            local p = GetProfile()
            p.combat_melee_indicator_opacity = value
            ApplyMeleeIndicatorStyle()
            RefreshMeleeIndicator()
        end
    )
    local meleeOpacityOptions = Settings.CreateSliderOptions(0.05, 1, 0.05)
    meleeOpacityOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return string.format("%.2f", value)
    end)
    local meleeOpacitySlider =
        Settings.CreateSlider(combatCategory, settingMeleeOpacity, meleeOpacityOptions, "Opacidad de la cruz.")
    if combatSectionExpandedPredicate then
        meleeOpacitySlider:AddShownPredicate(combatSectionExpandedPredicate)
    end
    meleeOpacitySlider:AddModifyPredicate(function()
        local p = GetProfile()
        return p and p.combat_melee_indicator_enabled == true
    end)

    local groupsSectionExpandedPredicate = nil
    if SettingsLib and SettingsLib.CreateExpandableSection then
        local _, isExpanded = SettingsLib:CreateExpandableSection(groupsCategory, {
            name = "Automatización",
            expanded = true,
            colorizeTitle = true,
        })
        groupsSectionExpandedPredicate = isExpanded
    else
        AddFeatureHeader(groupsLayout, "Automatización")
    end

    local settingAutoConfirmRoleChecks = Settings.RegisterProxySetting(
        groupsCategory,
        "PACOQOL_grupos_auto_confirm_role_checks",
        Settings.VarType.Boolean,
        "Auto-confirmar rol",
        false,
        function()
            return IsAutoConfirmRoleChecksEnabled()
        end,
        function(value)
            local p = GetProfile()
            p.grupos_auto_confirm_role_checks = value and true or false
        end
    )

    local autoConfirmRoleChecksCheckbox = Settings.CreateCheckbox(
        groupsCategory,
        settingAutoConfirmRoleChecks,
        "Confirma automáticamente tu rol cuando aparece una comprobación de rol (incluye LFG y solicitudes del líder al apuntar al grupo)."
    )
    if groupsSectionExpandedPredicate then
        autoConfirmRoleChecksCheckbox:AddShownPredicate(groupsSectionExpandedPredicate)
    end

    local info = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", {
        name = "Comando: /pqol",
    })
    rootLayout:AddInitializer(info)
end

SLASH_PACOPAOQOL1 = "/pqol"
SlashCmdList.PACOPAOQOL = function(msg)
    if InCombatLockdown() then
        Print("No se puede abrir configuración en combate.")
        return
    end

    if settingsCategoryID then
        Settings.OpenToCategory(settingsCategoryID)
    end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(_, event, loadedName)
    if event == "PLAYER_LOGIN" then
        HookBlizzardEditMode()
        SyncWithBlizzardEditMode()
        return
    end

    if loadedName ~= addonName then
        return
    end

    EnsureDB()
    RegisterMountIndicatorEvents()
    ApplyMountIndicatorPosition()
    ApplyMountIndicatorScale()
    EnsureMeleeIndicator()
    ApplyMeleeIndicatorPosition()
    EnsureMeleeIndicatorEvents()
    ApplyMeleeIndicatorStyle()
    StartMeleeIndicatorTicker()
    UpdateAudioSync()
    InitAutoConfirmRoleChecks()
    CreateSettings()
    HookBlizzardEditMode()
    SyncWithBlizzardEditMode()
    RefreshMountIndicator()
    RefreshMeleeIndicator()
    Print("Cargado. Usa /pqol para configurar.")
end)

