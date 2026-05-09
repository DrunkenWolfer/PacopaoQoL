local _, ns = ...

-- Lista provisional de habilidades de Druida (claves en ingles para evitar problemas de identificadores).
-- Comentario a la derecha: nombre en espanol.
ns.RegisterClassSoundKits("DRUID", {
    MOONFIRE = 83387, -- Fuego lunar
    SUNFIRE = 0, -- Fuego solar
    WRATH = 0, -- Colera
    STARFIRE = 0, -- Fuego estelar
    STARSURGE = 0, -- Oleada de estrellas
    STARFALL = 0, -- Lluvia de estrellas
    NEW_MOON = 0, -- Luna nueva
    HALF_MOON = 0, -- Media luna
    FULL_MOON = 0, -- Luna llena
    SOLAR_BEAM = 0, -- Rayo solar
    LUNAR_BEAM = 60153, -- Rayo lunar
    CELESTIAL_ALIGNMENT = 0, -- Alineacion celestial
    INCARNATION_CHOSEN_OF_ELUNE = 0, -- Encarnacion: Elegido de Elune
    CONVOKE_THE_SPIRITS = 0, -- Convocar a los espiritus

    RAKE = 0, -- Aranazo
    SHRED = 0, -- Destrozar
    RIP = 0, -- Desgarrar
    FEROCIOUS_BITE = 0, -- Mordedura feroz
    THRASH = 184313, -- Vapulear/Flagelo
    SWIPE = 184313, -- Zarpazo
    TIGERS_FURY = 0, -- Furia del tigre
    BERSERK = 0, -- Berserk
    INCARNATION_AVATAR_OF_ASHAMANE = 0, -- Encarnacion: Avatar de Ashamane
    PRIMAL_WRATH = 0, -- Colera primigenia

    MANGLE = 322955, -- Magullar
    IRONFUR = 64070, -- Pelaje de hierro
    MAUL = 1324548, -- Magullar (Maul)
    RAZE = 0, -- Devastar
    FRENZIED_REGENERATION = 60600, -- Regeneracion frenetica
    BARKSKIN = 20412, -- Corteza
    SURVIVAL_INSTINCTS = 15228, -- Instintos de supervivencia
    INCARNATION_GUARDIAN_OF_URSOC = 7350646, -- Encarnacion: Guardian de Ursoc

    REJUVENATION = 0, -- Rejuvenecimiento
    REGROWTH = 0, -- Recrecimiento
    LIFEBLOOM = 0, -- Flor de vida
    WILD_GROWTH = 0, -- Crecimiento salvaje
    SWIFTMEND = 0, -- Alivio presto
    TRANQUILITY = 0, -- Tranquilidad
    FLOURISH = 0, -- Florecer
    NATURES_SWIFTNESS = 0, -- Presteza de la naturaleza
    NATURES_CURE = 0, -- Cura de la naturaleza
    INNERVATE = 0, -- Estimular
    MARK_OF_THE_WILD = 48469, -- Marca de lo Salvaje
    WILD_CHARGE = 183856, -- Carga salvaje

    REBIRTH = 0, -- Renacer
    CYCLONE = 0, -- Ciclon
    ENTANGLING_ROOTS = 0, -- Raices enmaranadoras
    HIBERNATE = 0, -- Hibernar
    SKULL_BASH = 23968, -- Zarpazo craneal
    STAMPEDING_ROAR = 0, -- Rugido de estampida
    INCAPACITATING_ROAR = 63318, -- Rugido incapacitante
    MIGHTY_BASH = 0, -- Testarazo poderoso
    TYPHOON = 60154, -- Tifon
    URSOLS_VORTEX = 102793, -- Vortice de Ursol
})

-- Relacion spellID -> clave interna (agnostico al idioma del cliente).
ns.RegisterClassSpellKeys("DRUID", {
    [8921] = "MOONFIRE",
    [164812] = "MOONFIRE",
    [93402] = "SUNFIRE",
    [5176] = "WRATH",
    [194153] = "STARFIRE",
    [78674] = "STARSURGE",
    [191034] = "STARFALL",
    [274281] = "NEW_MOON",
    [274282] = "HALF_MOON",
    [274283] = "FULL_MOON",
    [78675] = "SOLAR_BEAM",
    [204066] = "LUNAR_BEAM",
    [194223] = "CELESTIAL_ALIGNMENT",
    [102560] = "INCARNATION_CHOSEN_OF_ELUNE",
    [391528] = "CONVOKE_THE_SPIRITS",

    [1822] = "RAKE",
    [5221] = "SHRED",
    [1079] = "RIP",
    [22568] = "FEROCIOUS_BITE",
    [77758] = "THRASH",
    [106830] = "THRASH",
    [250255] = "THRASH",
    [106785] = "SWIPE",
    [213771] = "SWIPE",
    [5217] = "TIGERS_FURY",
    [106951] = "BERSERK",
    [102543] = "INCARNATION_AVATAR_OF_ASHAMANE",
    [285381] = "PRIMAL_WRATH",

    [33917] = "MANGLE",
    [192081] = "IRONFUR",
    [6807] = "MAUL",
    [400254] = "RAZE",
    [22842] = "FRENZIED_REGENERATION",
    [22812] = "BARKSKIN",
    [61336] = "SURVIVAL_INSTINCTS",
    [102558] = "INCARNATION_GUARDIAN_OF_URSOC",
    [16979] = "WILD_CHARGE",

    [774] = "REJUVENATION",
    [8936] = "REGROWTH",
    [33763] = "LIFEBLOOM",
    [48438] = "WILD_GROWTH",
    [18562] = "SWIFTMEND",
    [740] = "TRANQUILITY",
    [197721] = "FLOURISH",
    [132158] = "NATURES_SWIFTNESS",
    [88423] = "NATURES_CURE",
    [29166] = "INNERVATE",
    [1126] = "MARK_OF_THE_WILD",
    [102401] = "WILD_CHARGE",

    [20484] = "REBIRTH",
    [33786] = "CYCLONE",
    [339] = "ENTANGLING_ROOTS",
    [2637] = "HIBERNATE",
    [106839] = "SKULL_BASH",
    [93985] = "SKULL_BASH",
    [106898] = "STAMPEDING_ROAR",
    [99] = "INCAPACITATING_ROAR",
    [5211] = "MIGHTY_BASH",
    [132469] = "TYPHOON",
    [102793] = "URSOLS_VORTEX",
})
