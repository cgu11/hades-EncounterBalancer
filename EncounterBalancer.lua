ModUtil.RegisterMod("EncounterBalancer")

local config = {
    Enabled = true,
    EliteScaling = true, -- makes encounters increasingly full of elites as the biome progresses
    WaveScaling = true, -- forces a # of waves in an encounter to force average for the biome
    WaveAverages = {
        Tartarus = 2, -- default is 2, since it's 1-3 range
        Asphodel = 2.5, -- default is 2.5, since it's 2-3 range
        Elysium = 2.5, -- default is 2.5, since it's a 2-3 range
    },
}
EncounterBalancer.config = config

-- these include end shops
EncounterBalancer.BiomeDepths = {
    Tartarus = 10, -- weird because of offsets in beginning
    Asphodel = 7,
    Elysium = 9,
}

EncounterBalancer.WaveTracking = {
    Tartarus = {},
    Asphodel = {},
    Elysium = {},
}

ModUtil.WrapBaseFunction("GenerateEncounter", function( baseFunc, currentRun, room, encounter)
    local currentBiomeDepth = GetBiomeDepth(currentRun)
    local currentBiome = room.RoomSetName
    if EncounterBalancer.config.Enabled and EncounterBalancer.config.EliteScaling and EncounterBalancer.BiomeDepths[currentBiome] then
        local relativeBiomeDepth = currentBiomeDepth / EncounterBalancer.BiomeDepths[currentBiome]
        encounter.MinEliteTypes = math.floor(6*relativeBiomeDepth - 1)
    end

    if EncounterBalancer.config.Enabled and EncounterBalancer.config.WaveScaling and EncounterBalancer.config.WaveAverages[currentBiome] then
        local emptyTrackerFlag = false
        if TableLength(EncounterBalancer.WaveTracking[currentBiome] > 0) then
            local sum = 0;
            for i, waves in ipairs(EncounterBalancer.WaveTracking[currentBiome]) do
                sum = sum + waves
            end
            local average = sum / TableLength(EncounterBalancer.WaveTracking[currentBiome])
            -- too high, need fewer waves
            if average > EncounterBalancer.config.WaveAverages[currentBiome] then
                encounter.MaxWaves = math.floor(EncounterBalancer.config.WaveAverages[currentBiome])
            -- too low, need more waves
            elseif average < EncounterBalancer.config.WaveAverages[currentBiome] then
                encounter.MinWaves = math.ceil(EncounterBalancer.config.WaveAverages[currentBiome])
            end
        end
    end

    baseFunc( currentRun, room, encounter)

    if encounter.WaveCount then
        table.insert(EncounterBalancer.WaveTracking[currentBiome], encounter.WaveCount)
    end
end, EncounterBalancer)