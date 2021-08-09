ModUtil.RegisterMod("EncounterBalancer")

local config = {
    Enabled = true,
    EliteScaling = true, -- makes encounters increasingly full of elites as the biome progresses
    WaveScaling = true, -- forces a # of waves in an encounter to force average for the biome
    WaveAverages = {
        Tartarus = 1.9, -- default is 2, since it's 1-3 range
        Asphodel = 2.25, -- default is 2.5, since it's 2-3 range
        Elysium = 2.25, -- default is 2.5, since it's a 2-3 range
    },
    Debug = true, -- requires PrintUtil
}
EncounterBalancer.config = config

EncounterBalancer.BiomeData = {
    Tartarus = {
        Intro = 1,
        LastCombat = 12,
        Length = 11,
    },
    Asphodel = {
        Intro = 16,
        LastCombat = 22,
        Length = 6,
    },
    Elysium = {
        Intro = 26,
        LastCombat = 34,
        Length = 8,
    }
}

EncounterBalancer.WaveTracking = {
    Tartarus = {},
    Asphodel = {},
    Elysium = {},
}

ModUtil.WrapBaseFunction("GenerateEncounter", function( baseFunc, currentRun, room, encounter)
    local runDepth = GetRunDepth(currentRun)
    local currentBiome = room.RoomSetName
    
    local validRoom = currentBiome == "Tartarus" or currentBiome == "Asphodel" or currentBiome == "Elysium"
    local validEncounter = encounter.Generated and encounter.MinWaves and encounter.MaxWaves and encounter.MinWaves ~= encounter.MaxWaves
    
    if validRoom and validEncounter and EncounterBalancer.config.Enabled and EncounterBalancer.config.EliteScaling and EncounterBalancer.BiomeData[currentBiome] then
        local relativeBiomeDepth = (runDepth - EncounterBalancer.BiomeData[currentBiome].Intro) / EncounterBalancer.BiomeData[currentBiome].Length
        if relativeBiomeDepth <= 0.25 then
            encounter.MinEliteTypes = 0
        elseif relativeBiomeDepth <= 0.5 then
            encounter.MinEliteTypes = 1
        elseif relativeBiomeDepth <= 0.85 then
            encounter.MinEliteTypes = 2
        else
            encounter.MinEliteTypes = 3
        end
        encounter.MaxEliteTypes = math.max(encounter.MinEliteTypes, encounter.MaxEliteTypes)
    end

    if validRoom and EncounterBalancer.config.Enabled and EncounterBalancer.config.WaveScaling and EncounterBalancer.config.WaveAverages[currentBiome] then
        local emptyTrackerFlag = false
        if TableLength(EncounterBalancer.WaveTracking[currentBiome]) > 0 then
            local sum = 0;
            for i, waves in ipairs(EncounterBalancer.WaveTracking[currentBiome]) do
                sum = sum + waves
            end
            local average = sum / TableLength(EncounterBalancer.WaveTracking[currentBiome])

            if validEncounter then
                -- too high, need fewer waves
                if average > EncounterBalancer.config.WaveAverages[currentBiome] and encounter.MaxWaves then
                    encounter.MaxWaves = math.floor(EncounterBalancer.config.WaveAverages[currentBiome])
                -- too low, need more waves
                elseif average < EncounterBalancer.config.WaveAverages[currentBiome] and encounter.MinWaves then
                    encounter.MinWaves = math.ceil(EncounterBalancer.config.WaveAverages[currentBiome])
                end
            end
        end
    end

    baseFunc( currentRun, room, encounter)

    if validRoom and encounter.WaveCount and validEncounter then
        table.insert(EncounterBalancer.WaveTracking[currentBiome], encounter.WaveCount)
    end
end, EncounterBalancer)

ModUtil.WrapBaseFunction("StartEncounter", function( baseFunc, currentRun, currentRoom, currentEncounter )
    if PrintUtil and EncounterBalancer.config.Debug then
        local runDepth = GetRunDepth(currentRun)
        local currentBiome = currentRoom.RoomSetName
        local validRoom = currentBiome == "Tartarus" or currentBiome == "Asphodel" or currentBiome == "Elysium"
        if validRoom then
            local eliteTypes = currentEncounter.MinEliteTypes or 0
            local waves = currentEncounter.WaveCount or 0

            local currentBiome = currentRoom.RoomSetName
            local sum = 0;
            for i, waves in ipairs(EncounterBalancer.WaveTracking[currentBiome]) do
                sum = sum + waves
            end
            local average;
            if sum > 0 then
                average = sum / TableLength(EncounterBalancer.WaveTracking[currentBiome])
            else
                average = 0
            end

            local text_config_table = DeepCopyTable(UIData.CurrentRunDepth.TextFormat)

            PrintUtil.createOverlayLine(
                "MinEliteTypeCount",
                "MIN ELITES: " .. eliteTypes,
                MergeTables(
                    text_config_table,
                    {
                        x_pos = 1905,
                        y_pos = 140,
                    }
                )
            )

            PrintUtil.createOverlayLine(
                "WaveCount",
                "WAVES: " .. waves,
                MergeTables(
                    text_config_table,
                    {
                        x_pos = 1905,
                        y_pos = 165,
                    }
                )
            )
            PrintUtil.createOverlayLine(
                "BiomeWaveAverage",
                "BIOME AVG: " .. average,
                MergeTables(
                    text_config_table,
                    {
                        x_pos = 1905,
                        y_pos = 190,
                    }
                )
            )
        end
    end
    baseFunc( currentRun, currentRoom, currentEncounter )
end, EncounterBalancer)