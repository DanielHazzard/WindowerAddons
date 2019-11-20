_addon.name = 'Auto_Burst'
_addon.author = 'Daniel_H'
_addon.version = '1.3'
_addon_description = ''
_addon.commands = {'ab', 'autoburst'}

-- CUSTOM VARIABLES
local packets = require("packets")
local res = require("resources")
require('strings')

-- USER SETTINGS MAKE SURE TO EDIT -------------------- --
local AssistedPlayer = "" -- IF LEFT BLANK IT WILL SCAN THE PARTY FOR A MEMBER ENGAGED AND USE THAT

burstMagic = {
        -- LEVEL 3  and 4
        ["radiance"] = "Thunder",
        ["light"] = "Thunder",
        ["umbra"] = "Blizzard",
        ["darkness"] = "Blizzard",
        -- LEVEL 2
        ["gravitation"] = "Stone",
        ["fragmentation"] = "Thunder",
        ["distortion"] = "Blizzard",
        ["fusion"] = "Fire",
        -- LEVEL 1
        ["compression"] = "Aspir",
        ["liquefaction"] = "Fire",
        ["induration"] = "Blizzard",
        ["reverberation"] = "Water",
        ["transfixion"] = "Banish",
        ["scission"] = "Stone",
        ["detonation"] = "Aero",
        ["impaction"] = "Thunder",
}

tierOrder = {
    [4] = "VI",
    [3] = "V",
    [1] = "IV",
    [2] = "III",
    [5] = "II",
    [6] = "I",
}

BurstJobs = S{
    'RDM',
    'SCH',
    'BLM',
    'GEO'
}

-- ASPIR WILL BE USED WHEN CURRENT MP IS BELOW THE DEFINED AMOUNT
Aspir_MPAmount = 300

-- ATTEMPT ASPIR WHEN POSSIBLE AND WHEN NOT BUSY (IE. NOT BURSTING)
Aspir_NoBurst = true

local knownMP_monsters = S{"Apex Crab"}-- ADD NAMES BY ADDING A COMMA AFTER THE PREVIOUS THEN ADDED THE NAME IN QUOTATION MARKS

-- ---------------------------------------------------- --
local isCasting = false

local DebugEnabled = false

local player = windower.ffxi.get_player()
local party_info = windower.ffxi.get_party_info()
local party = windower.ffxi.get_party()

local Party_Indexes = {
    'p0', 'p1', 'p2', 'p3', 'p4', 'p5',
    'p6', 'p7', 'p8', 'p9', 'p10', 'p11',
    'p12', 'p13', 'p14', 'p15', 'p16', 'p17'
}

function debugMSG(message)
    if DebugEnabled == true then
        windower.add_to_chat(1, ('\31\200\31\05Debug: \31\200\31\207 ' .. message))
    end
end

function CheckIfBursting()
    if BurstJobs:contains(player.main_job) then
        return true
    else
        return false
    end
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

-- SKILLCHAINS TABLE
skillchains = {
    [288] = 'light', [385] = 'light',
    [289] = 'darkness', [386] = 'darkness',
    [290] = 'gravitation', [387] = 'gravitation',
    [291] = 'fragmentation', [388] = 'fragmentation',
    [292] = 'distortion', [389] = 'distortion',
    [293] = 'fusion', [390] = 'fusion',
    [294] = 'compression', [391] = 'compression',
    [295] = 'liquefaction', [392] = 'liquefaction',
    [296] = 'induration', [393] = 'induration',
    [297] = 'reverberation', [394] = 'reverberation',
    [298] = 'transfixion', [395] = 'transfixion',
    [299] = 'scission', [396] = 'scission',
    [300] = 'detonation', [397] = 'detonation',
    [301] = 'impaction', [398] = 'impaction',
    [767] = 'radiance', [769] = 'radiance',
    [770] = 'umbra', [768] = 'umbra',
}

function BuffActive(BuffID)
    if T(windower.ffxi.get_player().buffs):contains(BuffID) == true then
        return true
    else
        return false
    end
end

function playerDisabled()
    if BuffActive(0) == true then -- KO
        return true
    elseif BuffActive(2) == true then -- SLEEP
        return true
    elseif BuffActive(6) == true then -- SILENCE
        return true
    elseif BuffActive(7) == true then -- PETRIFICATION
        return true
    elseif BuffActive(10) == true then -- STUN
        return true
    elseif BuffActive(14) == true then -- CHARM
        return true
    elseif BuffActive(28) == true then -- TERRORIZE
        return true
    elseif BuffActive(29) == true then -- MUTE
        return true
    elseif BuffActive(193) == true then -- LULLABY
        return true
    elseif BuffActive(262) == true then -- OMERTA
        return true
    end
    return false
end

function CanUseJobAbility(checkedname)
    ability_recasts = windower.ffxi.get_ability_recasts()
    abilityData = res.abilites:with('name', checkedname)
    if (abilityData == nil) or (ability_recasts(abilityData.recast_id) ~= 0) or (playerDisabled() == true) then
        return false
    else
        return true
    end
end

function CanUseSpell(spellName)
    -- FIRST CHECK THAT YOU CAN ACTUALLY CAST SPELL ( IE YOU HAVE REQUIRED LEVELS/JP/LEARNED )
    spell = res.spells:with('en', spellName)
    -- IF player, spell OR spell.levels IS NIL OR PLAYER IS DISABLED ( Stunned, Silenced, Petrified ETC ) THEN RETURN false AND CANCEL SPELL
    if (player == nil) or (spell == nil) or (spell.levels[player.main_job_id] == nil) or (playerDisabled() == true) then
        debugMSG("either player, spell or spell.levels was nil, or you have a disabling status active active. " .. spellName)
        return false
    end
    -- CHECK IF SPELL IS A JOB POINTED ONE IF NOT THEN JUST COMPARE LEVELS AND CHECK YOU OWN THE SPELL
    if spell.levels[player.main_job_id] == 100 then -- IS A JOB POINT SPELL THAT REQUIRES 100 JOB POINTS BEING SPENT
        if S{"Thunder VI", "Blizzard VI", "Fire VI", "Stone VI", "Water VI", "Aero VI"}:contains(spell.en) and player.job_points.blm.jp_spent >= 100 then
            debugMSG("Was a JOB POINT 100 BLM spell, and was successfully located. " .. spellName)
            return true
        elseif S{"Thunder V", "Blizzard V", "Fire V", "Stone V", "Water V", "Aero V"}:contains(spell.en) and (player.job_points.rdm.jp_spent >= 100 or player.job_points.geo.jp_spent >= 100) then
            debugMSG("Was a JOB POINT 100 RDM/GEO spell, and was successfully located. " .. spellName)
            return true
        else
            debugMSG("Was a JOB POINT 100 spell, and was not located. " .. spellName)
            return false
        end
    elseif spell.levels[player.main_job_id] == 550 then -- IS A JOB POINT SPELL THAT REQUIRES 550 JOB POINTS BEING SPENT
        if spell.en == "Aspir III" and (player.job_points.blm.jp_spent >= 550 or player.job_points.geo.jp_spent >= 550) then
            debugMSG("Was a JOB POINT 550 spell, and was successfully located. " .. spellName)
            return true
        else
            debugMSG("Was a JOB POINT 550 spell, and was not located. " .. spellName)
            return false
        end
    elseif spell.levels[player.main_job_id] == 1200 then -- IS A JOB POINT SPELL THAT REQUIRES 1200 JOB POINTS BEING SPENT
        if spell.en == "Death" and player.job_points.blm.jp_spent >= 1200 then
            debugMSG("Was the DEATH spell, and was successfully located. " .. spellName)
            return true
        else
            debugMSG("Was the DEATH spell, and was not located. " .. spellName)
            return false
        end
    else -- IS NOT A JOB POINT SPELL
        if spell.levels[player.main_job_id] <= player.main_job_level then -- YOU ARE THE REQUIRED LEVEL OR ABOVE IT
            if windower.ffxi.get_spells()[spell.id] then -- YOU POSSESS THE SPELL IE YOU USED A SCROLL TO LEARN IT OR SPENT MERIT POINTS
                debugMSG("Was a NORMAL spell, and was successfully located. " .. spellName)
                return true
            else
                debugMSG("Was a NORMAL spell, and was not located. " .. spellName)
                return false
            end
        end
    end
    -- IF YOU DON'T GET TRUE ELSEWHERE RETURN FALSE
    return false
end

function SpellRecast(spellName)
    SpellRecasts = windower.ffxi.get_spell_recasts()
    GrabbedSpell = res.spells:with('name', spellName)
    debugMSG(spellName .. " recast currently " .. SpellRecasts[spell.id])
    if SpellRecasts[spell.id] == 0 then
        return true
    else
        return false
    end
    return false
end

function castSpell(spell, burst)
    target = windower.ffxi.get_mob_by_target('t')
    if burst == "none" then
        windower.add_to_chat(1, ('\31\200\31\05Attempting MP Recovery:\31\200\31\207 ' .. spell))
    else
        windower.add_to_chat(1, ('\31\200\31\05Burst located:\31\200\31\207 ' .. firstToUpper(burst) .. " Attempting cast: \31\200\31\05" .. spell .. '\31\200\31\207 '))
    end
    if target ~= nil and target.is_npc then
        windower.send_command('wait 2; input /ma "' .. spell .. '" <t>')
    else
        windower.send_command('wait 2; input /ma "' .. spell .. '" <bt>')
    end
end

function GrabAssistTarget()

    for i = 0, 17 do
        grabbedMember = party[Party_Indexes[i]]
        if grabbedMember then
            player_entity = windower.ffxi.get_mob_by_name(grabbedMember.name)
            if player_entity and player_entity.status == 1 then
                return player_entity.name
            end
        end
    end
    return "none"
end

function RunAssistCmd()
    -- IF ENABLED ASSIST THE SELECTED PLAYER
    if (AssistedPlayer ~= "" or AssistedPlayer == "none" or AssistedPlayer == "party") then
        player_entity = windower.ffxi.get_mob_by_name(AssistedPlayer)
        if player_entity and player_entity.status == 1 then
            if DebugEnabled then debugMSG("Assist enabled, targetting " .. AssistedPlayer) end
            windower.send_command('input /assist ' .. AssistedPlayer)
            coroutine.sleep(1)
        end
    else -- ASSIST ISN'T SET SO FIND ONE
        AssistName = GrabAssistTarget()
        if AssistName ~= "none" then
            if DebugEnabled then debugMSG("Assist enabled, targetting " .. AssistName) end
            windower.send_command('input /assist ' .. AssistName)
            coroutine.sleep(1)
        end
    end
end

function run_burst(skillchain)
    if CheckIfBursting() == true and not isCasting == true then -- IF PLAYER IS ONE OF THE CORRECT JOBS THEN ENABLE BURSTING
        RunAssistCmd()
        -- GRAB THE TARGET INFO NEEDED FOR THE ASPIR CHECK
        target = windower.ffxi.get_mob_by_target('t')
        -- CANCEL THE RUN BURST ID SKILLCHAIN IS SOMEHOW EMPTY
        if skillchain == nil or target == nil then return end
        -- FIRST RUN THE CHECKS TO SEE IF YOU NEED MP AND ASPIR CAN RECOVER MP
        if S{'darkness', 'umbra', 'compression', 'gravitation'}:contains(skillchain) and player.vitals.mp <= Aspir_MPAmount and target ~= nil and knownMP_monsters:contains(target.name) and BuffActive(1) ~= true then
            windower.add_to_chat(1, ('\31\200\31\05Low MP Notice: \31\200\31\207 Attempting to recover MP with Aspir.'))
            if CanUseSpell("Aspir III") and SpellRecast("Aspir III") == true then
                completed_Spell = "Aspir III"
            elseif CanUseSpell("Aspir II") and SpellRecast("Aspir II") == true then
                completed_Spell = "Aspir II"
            elseif CanUseSpell("Aspir") and SpellRecast("Aspir") == true then
                completed_Spell = "Aspir"
            end
        else
            -- SINCE ASPIR IS NOT NEEDED OR NOT POSSIBLE ON THE SET ENEMY CONTINUE ONTO THE BURST ACTION
            for i, v in ipairs(tierOrder) do
                generatedSpell = ""
                if v == "I" then
                    generatedSpell = burstMagic[skillchain]
                else
                    generatedSpell = burstMagic[skillchain] .. " " .. v
                end
                if DebugEnabled then debugMSG("Checking spell, " .. generatedSpell) end
                if CanUseSpell(generatedSpell) == true and SpellRecast(generatedSpell) == true then
                    completed_Spell = generatedSpell
                    break
                end
            end
        end
        if completed_Spell ~= "" then
            castSpell(completed_Spell, skillchain)
        end
    end
end

windower.register_event('incoming chunk', function(id, data)
    if id == 0x028 then
        local action_message = packets.parse('incoming', data)
        if action_message["Category"] == 4 then
            isCasting = false
        elseif action_message["Category"] == 8 then
            isCasting = true
            if action_message["Target 1 Action 1 Message"] == 0 then
                isCasting = false
            end
        end
    end
end)

windower.register_event('addon command', function(input, ...)
    local args = {...}
    if args ~= nil then
        local cmd = string.lower(input)
        if cmd == "assist" then
            AssistedPlayer = args[1]
        elseif cmd == "verify" then
            debugMSG("Running check")
            DebugEnabled = true
            run_burst("light")
        end
    end
end)

function PartyPet(actorData)

    for i = 0, 17 do
        grabbedMember = party[Party_Indexes[i]]
        if grabbedMember then
            player_entity = windower.ffxi.get_mob_by_name(grabbedMember.name)
            if player_entity and player_entity.pet_index ~= nil then
                if player_entity.pet_index == actor.index then
                    return true
                end
            end
        end
    end
    return false
end

windower.register_event('action', function(data)
    player = windower.ffxi.get_player()
    if data.category == 3 or data.category == 4 or data.category == 11 or data.category == 13 then
        if data.target_count > 0 then
            actor = windower.ffxi.get_mob_by_id(data.actor_id)-- GRAB ACTOR DATA
            if actor ~= nil and (actor.in_party or actor.in_alliance or PartyPet(actor)) then
                if data.targets[1].actions ~= nil then
                    local action = data.targets[1].actions[1]
                    if action.has_add_effect then
                        if DebugEnabled then debugMSG("Burst PACKET located, " .. skillchains[action.add_effect_message]) end
                        run_burst(skillchains[action.add_effect_message])
                    end
                end
            end
        end
    end
end)

windower.register_event('mp change', function(new, old)
    if Aspir_NoBurst == true and player.vitals.mp <= Aspir_MPAmount then
        RunAssistCmd()
        target = windower.ffxi.get_mob_by_target('t')
        -- CANCEL THE RUN BURST ID SKILLCHAIN IS SOMEHOW EMPTY
        if target ~= nil and knownMP_monsters:contains(target.name) and BuffActive(1) ~= true then
            if CanUseSpell("Aspir III") and SpellRecast("Aspir III") == true then
                completed_Spell = "Aspir III"
            elseif CanUseSpell("Aspir II") and SpellRecast("Aspir II") == true then
                completed_Spell = "Aspir II"
            elseif CanUseSpell("Aspir") and SpellRecast("Aspir") == true then
                completed_Spell = "Aspir"
            end
            if completed_Spell ~= "" then
                castSpell(completed_Spell, 'none')
            end
        end
    end
end)
