local day_to_tick = 5184000
local hour_to_tick = 216000
local min_to_tick = 3600

local nauvis = 'nauvis'
local vulcanus = 'vulcanus'
local fulgora = 'fulgora'
local gleba = 'gleba'
local aquilo = 'aquilo'
local edge = 'solar-system-edge'
local shattered_planet = 'shattered-planet'

local normal = 'normal'
local uncommon = 'uncommon'
local rare = 'rare'
local epic = 'epic'
local legendary = 'legendary'
local not_admin_text = {'wn.permission-denied'}

local function make_location(name)
    return {'wn.statistics-run-location', storage.statistics[name] or 0, name}
end

local function make_tech(name)
    return {'wn.statistics-run-tech', storage.statistics[name] or 0, name,
            game.forces.player.technologies[name].localised_name}
end

local function try_add_trait(trait)
    if not trait then
        return
    end
    storage.traits = storage.traits or {''}
    if table_size(storage.traits) >= 18 then
        storage.traits = {'', storage.traits}
    end
    table.insert(storage.traits, trait)
end

local function try_add_legacy(legacy)
    if not legacy then
        return
    end
    storage.legacies = storage.legacies or {''}
    if table_size(storage.legacies) >= 18 then
        storage.legacies = {'', storage.legacies}
    end
    table.insert(storage.legacies, legacy)
end

local infinite_tech_names = {'steel-plate-productivity', 'plastic-bar-productivity',
                             'low-density-structure-productivity', 'rocket-fuel-productivity',
                             'processing-unit-productivity', 'rocket-part-productivity', 'research-productivity',
                             'scrap-recycling-productivity', 'asteroid-productivity', 'physical-projectile-damage-7',
                             'stronger-explosives-7', 'refined-flammables-7', 'laser-weapons-damage-7',
                             'electric-weapons-damage-4', 'artillery-shell-damage-1', 'railgun-damage-1',
                             'worker-robots-speed-7', 'mining-productivity-3', 'follower-robot-count-5', 'health'}

-- 左上角信息内容
local function player_gui(player)

    if not storage.current_hostname then
        storage.current_hostname =
            '\nQ群541826511\n查看倒计时，输入 /time_left\n自杀，输入 /suicide\n踢玩家，输入 /ti <玩家名>\n死亡传送 输入/teleport nauvis/vulcanus/gleba/nauvis/aquilo\n'
    end
    player.gui.top.clear()
    player.gui.top.add {
        type = 'sprite-button',
        -- sprite = 'space-location/solar-system-edge',
        sprite = 'virtual-signal/signal-heart',
        -- sprite = 'item/raw-fish',
        name = 'info',
        tooltip = {'wn.introduction', storage.warp_minutes_per_tech, storage.warp_minutes_per_rocket,
                   storage.current_hostname}
    }
    player.gui.top.add {
        type = 'sprite-button',
        sprite = 'virtual-signal/signal-star',
        name = 'statistics',
        tooltip = {'', {'wn.statistics-title'},
                   {'wn.statistics-run', math.ceil(game.tick / day_to_tick), storage.run_auto, storage.run_perfect}}
    }

    player.gui.top.add {
        type = 'sprite-button',
        sprite = 'virtual-signal/signal-science-pack',
        name = 'science',
        tooltip = {'', {'wn.statistics-title-tech'},
                   {'', make_tech('automation-science-pack'), make_tech('logistic-science-pack'),
                    make_tech('chemical-science-pack'), make_tech('production-science-pack'),
                    make_tech('utility-science-pack'), make_tech('space-science-pack'),
                    make_tech('metallurgic-science-pack'), make_tech('agricultural-science-pack'),
                    make_tech('electromagnetic-science-pack'), make_tech('military-science-pack'),
                    make_tech('cryogenic-science-pack'), make_tech('promethium-science-pack'), '\n'},

                   {'', make_tech('epic-quality'), make_tech('legendary-quality'), '\n'},

                   {'', make_tech('mining-productivity-3'), make_tech('plastic-bar-productivity'),
                    make_tech('steel-plate-productivity'), make_tech('low-density-structure-productivity'),
                    make_tech('rocket-fuel-productivity', 'processing-unit-productivity'),
                    make_tech('rocket-part-productivity'), make_tech('asteroid-productivity'),
                    make_tech('scrap-recycling-productivity'), '\n', make_tech('research-productivity'), '\n'},

                   {'', make_tech('physical-projectile-damage-7'), make_tech('stronger-explosives-7'),
                    make_tech('refined-flammables-7'), make_tech('laser-weapons-damage-7'),
                    make_tech('electric-weapons-damage-4'), make_tech('artillery-shell-damage-1'),
                    make_tech('railgun-damage-1'), '\n'}}
    }

    if not storage.traits then
        storage.traits = {''}
    end
    player.gui.top.add {
        type = 'sprite-button',
        sprite = 'virtual-signal/signal-info',
        name = 'traits',
        tooltip = storage.traits
    }

    if not storage.legacies then
        storage.legacies = {''}
    end
    player.gui.top.add {
        type = 'sprite-button',
        sprite = 'virtual-signal/signal-skull',
        name = 'legacies',
        tooltip = storage.legacies
    }

    player.gui.top.add {
        type = 'sprite-button',
        sprite = 'entity/space-platform-hub',
        name = 'galaxy',
        tooltip = {'', {'wn.galaxy-trait-platform-amount', storage.max_platform_count},
                   {'wn.galaxy-trait-platform-size', storage.max_platform_size}, {'wn.galaxy-trait-title'},
                   {'wn.galaxy-trait-more'}}
    }
end

local function players_gui()
    for _, player in pairs(game.players) do
        if player.connected then
            player_gui(player)
        else
            player.gui.top.clear()
        end
    end
end

-- 手动重置players_gui
commands.add_command('players_gui', {'wn.players-gui-help'}, function(command)
    local player = game.get_player(command.player_index)
    if not player or player.admin then
        players_gui()
    else
        player.print(not_admin_text)
    end
end)

local function try_enter_space_platform(player)
    local size = table_size(game.forces.player.platforms)
    if size < 1 then
        local pos = game.surfaces.nauvis.find_non_colliding_position('character',
            {storage.respawn_x, storage.respawn_y}, 0, 1)
        player.teleport(pos, game.surfaces.nauvis)
        return
    else
        local index = math.random(size)
        local i = 1
        for _, space_platform in pairs(game.forces.player.platforms) do
            if index == i and space_platform then
                player.enter_space_platform(space_platform)
                return
            end
            i = i + 1
        end
    end
end

-- 重置玩家
local function player_reset(player)
    if not player then
        return
    end
    if game.tick - player.last_online > 48 * hour_to_tick then
        -- pass
    end
    player.disable_flashlight()
    try_enter_space_platform(player)
end

-- 开图
script.on_event(defines.events.on_player_respawned, function(event)
    local player = game.get_player(event.player_index)
    try_enter_space_platform(player)
end)

-- 开图
script.on_event(defines.events.on_pre_player_left_game, function(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end
    if player.surface and not player.surface.platform then
        storage.die_on_pre_player_left_game = storage.die_on_pre_player_left_game or true
        if not storage.die_on_pre_player_left_game then
            return
        end
        if player.character then
            player.character.die()
            -- 删除尸体
            for _, space_platform in pairs(game.forces.player.platforms) do
                if space_platform.surface then
                    local corpses = space_platform.surface.find_entities_filtered {
                        area = {{-8, -8}, {8, 8}},
                        type = 'character-corpse'
                    }
                    for _, corpse in pairs(corpses) do
                        corpse.destroy()
                    end
                end
            end
        else
            player.clear_items_inside()
        end
    end
end)

-- 创建玩家
script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    player_reset(player)
    player_gui(player)
    try_enter_space_platform(player)
end)

local function create_entity(name, x, y)
    local entity = game.surfaces.nauvis.create_entity {
        name = name,
        quality = normal,
        position = {
            x = x,
            y = y
        },
        force = 'player'
    }
    entity.minable = true
    entity.destructible = true
end

-- 重置母星
local function nauvis_reset()
    create_entity('rocket-silo', 5, 5)
    create_entity('cargo-landing-pad', 5, -7)
end

-- 数字格式
local function readable(x)
    if x < 0 then
        return 0
    elseif x < 0.1 then
        return math.ceil(x * 100) * 0.01
    elseif x < 3 then
        return math.floor(x * 10) * 0.1
    elseif x < 10 then
        return math.floor(x)
    elseif x < 100 then
        return math.floor(x / 10) * 10
    elseif x < 1000 then
        return math.floor(x / 100) * 100
    end
end

-- 指数分布
local function random_exp(x)
    return math.pow(2, (math.random() - math.random()) * x)
end

local function random_frequency()
    return readable(0.1 + random_exp(3) * storage.frequency)
end

local function random_size()
    return readable(0.1 + random_exp(3) * storage.size)
end

local function random_richness()
    return readable(0.1 + random_exp(8) * storage.richness)
end

local function random_nature()
    if not storage.nature then
        storage.nature = 3
    end
    return readable(math.pow(2, (math.random() - math.random()) * storage.nature))
end

local function get_mothership()
    for _, platform in pairs(game.forces.player.platforms) do
        if platform.surface.map_gen_settings.width >= 100 then
            return platform
        end
    end
    return nil
end

-- 创建随机表面
script.on_event(defines.events.on_surface_created, function(event)
    local surface = game.get_surface(event.surface_index)
    if not surface then
        return
    end

    local mgs = surface.map_gen_settings
    mgs.seed = math.random(1, 4294967295)

    storage.max_othership_size = storage.max_othership_size or 64
    local mothership = get_mothership()
    local size = mothership and storage.max_platform_size or storage.max_othership_size

    local platform = surface.platform
    if platform then
        local size = storage.max_platform_size
        mgs.width = size
        mgs.height = 512
    end
    surface.map_gen_settings = mgs
end)

local renames = {}
renames['crude-oil'] = 'fluid/crude-oil'
renames['vulcanus_coal'] = 'item/coal'
renames['sulfuric_acid_geyser'] = 'fluid/sulfuric-acid'
renames['lithium_brine'] = 'fluid/lithium-brine'
renames['fluorine_vent'] = 'fluid/fluorine'
renames['aquilo_crude_oil'] = 'fluid/crude-oil'
renames['tungsten_ore'] = 'item/tungsten-ore'
renames['gleba_stone'] = 'item/stone'

local function set_resource(name, mgs, richness_multiplier)

    local size = random_size()
    local richness = random_richness()
    local frequency = random_frequency()
    local value = size * richness * frequency

    local value_string = nil
    if value < 0.04 then
        value_string = {'wn.very-low'}
    elseif value < 0.25 then
        value_string = {'wn.low'}
    elseif value > 25 then
        value_string = {'wn.very-high'}
    elseif value > 4 then
        value_string = {'wn.high'}
    else
        value_string = {'wn.medium'}
    end

    try_add_trait({'wn.traits-richness-size-frequency', renames[name] or ('item/' .. name), richness, size, frequency,
                   value_string})

    richness_multiplier = richness_multiplier or 1
    mgs.autoplace_controls[name].size = size
    mgs.autoplace_controls[name].richness = richness * richness_multiplier
    mgs.autoplace_controls[name].frequency = frequency
end

local function random_nature_mgs(mgs, name)
    mgs.autoplace_controls[name].richness = random_nature()
    mgs.autoplace_controls[name].frequency = random_nature()
    mgs.autoplace_controls[name].size = random_nature()
end

-- 创建随机表面
script.on_event(defines.events.on_surface_cleared, function(event)

    local surface = game.get_surface(event.surface_index)
    if not surface then
        return
    end

    -- 跳过平台
    local platform = surface.platform
    if platform then
        return
    end

    local mgs = surface.map_gen_settings
    mgs.seed = math.random(1, 4294967295)

    -- 星球昼夜
    surface.always_day = false
    surface.freeze_daytime = false
    surface.min_brightness = 0
    surface.wind_speed = 0.02 * (0.5 + math.random())
    surface.wind_orientation = math.random()
    surface.wind_orientation_change = 0.0001 * (0.5 + math.random())
    surface.solar_power_multiplier = 1

    try_add_trait({'wn.traits-planet', surface.name})

    if math.random(1, 6) == 1 then
        -- 潮汐锁定，永夜
        surface.freeze_daytime = true
        surface.daytime = 0.56
        try_add_trait({'wn.traits-eternal-night'})
    elseif math.random(1, 4) == 1 then
        -- 潮汐锁定，永昼
        surface.freeze_daytime = true
        surface.daytime = 0
        try_add_trait({'wn.traits-eternal-day'})
    end

    storage.radius_min = storage.radius_min or 256
    storage.radius_max = storage.radius_max or 4096
    storage.radius = storage.radius or 1024
    -- 刷新星球半径
    local r = storage.radius * random_exp(2)
    r = math.max(storage.radius_min, r)
    r = math.min(storage.radius_max, r)
    r = math.ceil(r)
    storage.radius_of[surface.name] = r
    try_add_trait({'wn.traits-radius', r})

    mgs.width = r * 2 + 32
    mgs.height = r * 2 + 32

    mgs.starting_area = 2 * random_exp(2)

    -- 母星
    if surface == game.surfaces.nauvis then

        surface.peaceful_mode = math.random(1, 5) == 1
        if surface.peaceful_mode then
            try_add_trait({'wn.traits-peaceful-nauvis'})
        end

        local names = {''}
        for _, res in pairs({'iron-ore', 'copper-ore', 'stone', 'coal', 'crude-oil'}) do
            set_resource(res, mgs)
        end

        for _, res in pairs({'uranium-ore'}) do
            set_resource(res, mgs, storage.local_specialty_multiplier)
        end

        for _, res in pairs({'water', 'trees', 'enemy-base', 'rocks', 'nauvis_cliff', 'starting_area_moisture'}) do
            random_nature_mgs(mgs, res)
        end
    end

    -- 火星
    if surface == game.surfaces.vulcanus then

        for _, res in pairs({'vulcanus_coal', 'calcite', 'sulfuric_acid_geyser'}) do
            set_resource(res, mgs)
        end
        for _, res in pairs({'tungsten_ore'}) do
            set_resource(res, mgs, storage.local_specialty_multiplier)
        end
        random_nature_mgs(mgs, 'vulcanus_volcanism')
    end

    -- 雷星
    if surface == game.surfaces.fulgora then
        for _, res in pairs({'scrap'}) do
            set_resource(res, mgs, storage.local_specialty_multiplier)
        end

        random_nature_mgs(mgs, 'fulgora_islands')
        random_nature_mgs(mgs, 'fulgora_cliff')
    end

    -- 草星
    if surface == game.surfaces.gleba then
        surface.peaceful_mode = math.random(1, 5) == 1
        if surface.peaceful_mode then
            try_add_trait({'wn.traits-peaceful-gleba'})
        end

        set_resource('gleba_stone', mgs, storage.local_specialty_multiplier * 2)

        mgs.autoplace_controls['gleba_enemy_base'].richness = math.random() * 6
        mgs.autoplace_controls['gleba_enemy_base'].size = math.random() * 6
        mgs.autoplace_controls['gleba_enemy_base'].frequency = math.random() * 6

        random_nature_mgs(mgs, 'gleba_water')
        random_nature_mgs(mgs, 'gleba_plants')
        random_nature_mgs(mgs, 'gleba_cliff')
    end

    if surface == game.surfaces.aquilo then
        for _, res in pairs({'lithium_brine', 'fluorine_vent', 'aquilo_crude_oil'}) do
            set_resource(res, mgs, storage.local_specialty_multiplier * 0.5)
        end
    end

    surface.map_gen_settings = mgs

    players_gui()

    if surface ~= game.surfaces.nauvis then
        return
    end
    local radius = math.floor(storage.radius * 0.2)
    game.forces.player.chart(game.surfaces.nauvis, {{
        x = -radius,
        y = -radius
    }, {
        x = radius,
        y = radius
    }})
    nauvis_reset()
end)

-- 跃迁
local function run_reset(is_perfect)
    storage.run = storage.run + 1
    if is_perfect then
        storage.run_perfect = storage.run_perfect + 1
    else
        storage.run_auto = storage.run_auto + 1
    end

    -- 清除星球前
    local last_run_ticks = (game.tick - storage.run_start_tick)
    game.print({'wn.warp-success-time', math.floor(last_run_ticks / hour_to_tick),
                math.floor(last_run_ticks / min_to_tick) % 60})
    storage.run_start_tick = game.tick

    if storage.run >= 1 and is_perfect then
        -- 统计玩家
        storage.player_failure_count = storage.player_failure_count or {}
        storage.player_success_count = storage.player_success_count or {}

        for _, player in pairs(game.players) do
            if player.connected then
                if player.surface and player.surface.platform then
                    game.print({'wn.player-success', player.name})
                    if not storage.player_success_count[player.name] then
                        storage.player_success_count[player.name] = 1
                    else
                        storage.player_success_count[player.name] = storage.player_success_count[player.name] + 1
                    end
                else
                    game.print({'wn.player-failure', player.name})
                end
            end
        end
    end

    -- 重置玩家
    for _, player in pairs(game.players) do
        -- if player.surface and not player.surface.platform and player.character and player.character.die then
        if player.surface and player.surface.planet then
            local inventory = player.get_inventory(defines.inventory.character_main)
            if inventory then
                inventory.clear()
            elseif player.character then
                player.character.die()
            else
                player.clear_items_inside()
            end
            player_reset(player)
        else

        end
    end

    -- 删除星球前
    storage.traits = {'', {'wn.traits-title'}}
    storage.legacies = {'', {'wn.legacies-title'}}
    -- 清空标记
    for _, surface in pairs(game.surfaces) do
        for _, tag in pairs(game.forces.player.find_chart_tags(surface)) do
            tag.destroy()
        end
    end

    game.surfaces['nauvis'].clear(true)
    if game.surfaces['vulcanus'] ~= nil then
        game.surfaces['vulcanus'].clear(true)
    end
    if game.surfaces['gleba'] ~= nil then
        game.surfaces['gleba'].clear(true)
    end
    if game.surfaces['fulgora'] ~= nil then
        game.surfaces['fulgora'].clear(true)
    end
    if game.surfaces['aquilo'] ~= nil then
        game.surfaces['aquilo'].clear(true)
    end

    local force = game.forces.player

    -- productivity_techs
    storage.infinite_tech_levels = storage.infinite_tech_levels or {}

    for _, tech_name in pairs(infinite_tech_names) do
        local tech = force.technologies[tech_name]
        storage.infinite_tech_levels[tech_name] = math.max(tech.prototype.level, tech.level - 1)
    end
    -- 重置玩家势力
    force.reset()
    for _, tech_name in pairs(infinite_tech_names) do
        local level = storage.infinite_tech_levels[tech_name]
        local tech = force.technologies[tech_name]
        tech.level = level
        try_add_legacy({'wn.legacy-bonus', tech_name, level - tech.prototype.level, tech.localised_name})
    end

    force.friendly_fire = true
    force.set_spawn_position({storage.respawn_x, storage.respawn_y}, game.surfaces.nauvis)

    -- 瞬移飞船
    for _, platform in pairs(force.platforms) do
        platform.space_location = 'nauvis'
        platform.paused = true
    end

    -- 重置科技

    game.reset_time_played()

    -- 母星污染
    game.forces.enemy.reset_evolution()
    game.map_settings.enemy_expansion.enabled = false
    game.map_settings.pollution.enabled = true
    game.map_settings.pollution.ageing = readable(random_exp(3))
    game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = readable(random_exp(3))
    try_add_trait({'wn.galaxy-trait-pollution-ageing', game.map_settings.pollution.ageing})
    try_add_trait({'wn.galaxy-trait-enemy_attack_pollution_consumption_modifier',
                   game.map_settings.pollution.enemy_attack_pollution_consumption_modifier})

    game.map_settings.asteroids.spawning_rate = readable(random_exp(4))
    game.difficulty_settings.spoil_time_modifier = readable(0.5 + random_exp(4))

    local tech_multiplier = readable(random_exp(4))

    tech_multiplier = math.max(tech_multiplier, 0.25 - storage.run_perfect * 0.01)
    tech_multiplier = math.max(tech_multiplier, 0.1)
    tech_multiplier = math.min(tech_multiplier, 4 + storage.run_perfect * 1)
    game.difficulty_settings.technology_price_multiplier = tech_multiplier

    storage.mining_drill_productivity_bonus_multiplier = storage.mining_drill_productivity_bonus_multiplier or 1
    storage.laboratory_productivity_bonus_multiplier = storage.laboratory_productivity_bonus_multiplier or 1

    force.mining_drill_productivity_bonus = readable((random_exp(2) - 1) *
                                                         storage.mining_drill_productivity_bonus_multiplier)
    force.laboratory_productivity_bonus = readable((random_exp(2) - 1) *
                                                       storage.laboratory_productivity_bonus_multiplier)
    try_add_trait({'', '\n',
                   {'wn.galaxy-trait-technology_price_multiplier', game.difficulty_settings.technology_price_multiplier},
                   {'wn.galaxy-trait-spawning_rate', game.map_settings.asteroids.spawning_rate},
                   {'wn.galaxy-trait-spoil_time_modifier', game.difficulty_settings.spoil_time_modifier},
                   {'wn.galaxy-trait-mining_drill_productivity_bonus', force.mining_drill_productivity_bonus},
                   {'wn.galaxy-trait-laboratory_productivity_bonus', force.laboratory_productivity_bonus}})

    storage.warp_minutes_per_tech_multiplier = storage.warp_minutes_per_tech_multiplier or 10
    storage.warp_minutes_per_tech = math.floor(storage.warp_minutes_per_tech_multiplier *
                                                   math.sqrt(game.difficulty_settings.technology_price_multiplier))
    storage.warp_minutes_total = math.min(10, math.max(5, storage.warp_minutes_per_tech))

    -- 刷新星系参数

    -- max_platform_size for otherships
    storage.max_platform_count_max = storage.max_platform_count_max or 20
    storage.max_platform_count_min = storage.max_platform_count_min or 5
    storage.max_platform_count = math.max(storage.max_platform_count_min,
        math.min(storage.max_platform_count_max, storage.run_perfect))

    -- max_platform_size for mothership
    if storage.run_perfect == 0 then
        storage.max_platform_size = 200
    elseif storage.run_perfect <= 10 then
        storage.max_platform_size = 200 + 80 * storage.run_perfect
    elseif storage.run_perfect <= 100 then
        storage.max_platform_size = 2000 + 10 * storage.run_perfect
    else
        storage.max_platform_size = math.max(3000 + storage.run_perfect, storage.run_perfect * 2)
    end

    -- 初始赠送科技
    local function research_recursive(name)
        game.forces.player.technologies[name].research_recursive()
        game.print({'wn.free-tech', name})
    end

    local force = game.forces.player

    if storage.run >= 1 then
        -- force.technologies['oil-processing'].researched = true
        -- force.technologies['uranium-processing'].researched = true
        force.technologies['space-platform'].researched = true
        -- force.technologies['space-science-pack'].researched = true
        -- force.technologies['space-platform-thruster'].researched = true
        -- force.technologies['planet-discovery-vulcanus'].researched = true
        -- force.technologies['planet-discovery-gleba'].researched = true
        -- force.technologies['planet-discovery-fulgora'].researched = true
        -- force.technologies['planet-discovery-aquilo'].researched = true
        force.unlock_space_location(nauvis)
        force.unlock_space_location(vulcanus)
        force.unlock_space_location(gleba)
        force.unlock_space_location(fulgora)
        -- force.unlock_space_location(aquilo)
    end

    if table_size(force.platforms) == 0 then
        research_recursive('space-platform')
    end

    -- 更新UI信息
    players_gui()

end

-- 第一次运行场景时触发
script.on_init(function()
    game.speed = 1

    storage.run = -1 -- 总跃迁次数
    storage.run_auto = -1 -- 自动跃迁次数
    storage.run_perfect = 0 -- 完美跃迁次数
    storage.run_start_tick = 0

    storage.warp_minutes_per_tech = 10 -- 每个科技增加时间
    storage.warp_minutes_per_rocket = 1 -- 每个火箭减少时间

    storage.respawn_x = 0
    storage.respawn_y = 0

    storage.statistics = {}

    storage.last_warp_tick = 0
    storage.last_warp_count = 0

    storage.richness = 1
    storage.frequency = 1
    storage.size = 1
    storage.local_specialty_multiplier = 0.25

    storage.radius = 2048
    storage.radius_of = {}

    run_reset(false)
end)

script.on_event(defines.events.on_player_left_game, function(event)
    if not event.player then
        return
    end
    event.player.gui.top.clear()
end)

local function get_warp_time_left()
    local minutes_gone = math.floor((game.tick - storage.run_start_tick) / min_to_tick)
    local minutes_left = storage.warp_minutes_total - minutes_gone
    return minutes_left
end

local function print_warp_time_left()
    game.print({'wn.warp-time-left', get_warp_time_left()})
end

-- 玩家进入游戏
script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.get_player(event.player_index)
    player_gui(player)
    print_warp_time_left()

    local welcome = {}
    if player.online_time > 0 then
        local last_delta = math.max(0, math.floor((game.tick - player.last_online) / hour_to_tick))
        local total_time = math.max(0, math.floor(player.online_time / hour_to_tick))
        welcome = {'wn.welcome-player', player.name, total_time, last_delta}

        -- 打印通关次数
        storage.player_failure_count = storage.player_failure_count or {}
        storage.player_success_count = storage.player_success_count or {}

        if storage.player_success_count[player.name] or storage.player_failure_count[player.name] then
            local success = storage.player_success_count[player.name] or 0
            local failure = storage.player_failure_count[player.name] or 0
            game.print({'wn.welcome-player-success', success})
        end
    else
        welcome = {'wn.welcome-new-player', player.name}
        player.insert {
            name = 'processing-unit',
            count = 200
        }
        player.insert {
            name = 'low-density-structure',
            count = 200
        }
        player.insert {
            name = 'rocket-fuel',
            count = 200
        }
        player.insert {
            name = 'space-platform-starter-pack',
            count = 1
        }
        player.insert {
            name = 'rocket-silo',
            count = 1
        }
        player.insert {
            name = 'cargo-landing-pad',
            count = 1
        }
    end
    game.print(welcome)
end)

-- 清空表面
script.on_event(defines.events.on_pre_surface_cleared, function(event)

end)

-- 星球圆形地块生成
script.on_event(defines.events.on_chunk_generated, function(event)
    local surface = event.surface
    -- local chunk_position = event.position
    local left_top = event.area.left_top

    -- 圆形地图
    local r = storage.radius_of[surface.name]
    r = r or storage.radius

    if left_top.x * left_top.x + left_top.y * left_top.y < r * r / 2 then
        return
    end

    local chunk_size = 32

    local tiles = {}
    local cx = 0.5
    local cy = 0.5
    for x = -1, chunk_size, 1 do
        for y = -1, chunk_size, 1 do
            local px = left_top.x + x
            local py = left_top.y + y

            if (px - cx) * (px - cx) + (py - cy) * (py - cy) > r * r then
                local p = {
                    x = px,
                    y = py
                }
                table.insert(tiles, {
                    name = 'empty-space',
                    position = p
                })
            end
        end
    end
    if table_size(tiles) > 0 then
        surface.set_tiles(tiles)
    end
    players_gui() -- 更新...
end)

local function can_reset()
    return game.forces.player.technologies['promethium-science-pack'].researched
end

script.on_event(defines.events.on_rocket_launched, function(event)
    if not event.rocket_silo then
        return
    end
    if not event.rocket then
        return
    end

    local decrease = math.ceil(get_warp_time_left() * (storage.warp_minutes_per_rocket) / 100)
    decrease = math.min(storage.warp_minutes_per_tech, decrease)
    decrease = math.max(1, decrease)
    storage.warp_minutes_total = storage.warp_minutes_total - decrease

    local silo = event.rocket_silo

    game.print({'wn.warp-time-rocket', decrease, get_warp_time_left(), math.floor(silo.position.x),
                math.floor(silo.position.y), silo.surface.name})
end)

script.on_event(defines.events.on_cargo_pod_finished_ascending, function(event)
    if not event.launched_by_rocket then
        return
    end

    local cargo_pod = event.cargo_pod
    if not cargo_pod then
        return
    end

    if event.player_index then
        local player = game.get_player(event.player_index)
        game.print({'wn.on_cargo_pod_finished_ascending_player', player.name})
        return
    end

    local inventory = cargo_pod.get_inventory(defines.inventory.cargo_unit)
    if not inventory then
        return
    end

    local contents = inventory.get_contents()
    if table_size(contents) < 1 then
        return
    elseif table_size(contents) == 1 then
        local content = contents[1]
        game.print({'wn.on_cargo_pod_finished_ascending_items', content.name, content.quality, content.count})
    else
        game.print({'wn.on_cargo_pod_finished_ascending_item_title'})
        for _, content in pairs(contents) do
            game.print({'wn.on_cargo_pod_finished_ascending_item', content.name, content.quality, content.count})
        end
    end
end)

script.on_event(defines.events.on_research_finished, function(event)

    local research = event.research
    local research_name = research.name

    if not event.by_script then
        -- 增加时间
        if research.prototype and not research.prototype.research_trigger then
            local delta_minutes = storage.warp_minutes_per_tech * (research_name == 'health' and 2 or 1)
            storage.warp_minutes_total = storage.warp_minutes_total + delta_minutes
            game.print({'wn.warp-time-tech', delta_minutes, get_warp_time_left()})
        end

        -- 自动添加无限科技
        if research.level > research.prototype.level then
            local queue = game.forces.player.research_queue
            queue[table_size(queue) + 1] = research
            game.forces.player.research_queue = queue
            game.print({'wn.start-tech', research.name})
        end

        storage.statistics[research_name] =
            storage.statistics[research_name] and storage.statistics[research_name] + 1 or 1
    end

    players_gui()
end)

-- 手动重置
commands.add_command('run_auto', {'wn.run-reset-help'}, function(command)
    if not command.player_index then
        return
    end

    local player = game.get_player(command.player_index)
    if not player or player.admin then
        run_reset(false)
    else
        player.print(not_admin_text)
    end
end)

-- 手动重置
commands.add_command('run_perfect', {'wn.run-reset-help'}, function(command)
    if not command.player_index then
        return
    end

    local player = game.get_player(command.player_index)
    if not player or player.admin then
        run_reset(true)
    else
        player.print(not_admin_text)
    end
end)

-- 自杀
commands.add_command('suicide', {'wn.suicide-help'}, function(command)
    if not command.player_index then
        return
    end

    local player = game.get_player(command.player_index)
    if player.character then
        player.character.die()
        game.print({'wn.suicide-notice', player.name})
    end
end)

-- 查询剩余时间
commands.add_command('time_left', {'wn.suicide-help'}, function(command)
    if not command.player_index then
        return
    end

    local player = game.get_player(command.player_index)
    if player.character then
        local time_left = get_warp_time_left()
        player.print({'wn.warp-time-left', time_left})
    end
end)

-- 踢人
commands.add_command('ti', {'wn.ti-help'}, function(command)
    if not command.player_index then
        return
    end
    local player = game.get_player(command.player_index)
    if not command.parameter then
        return
    end
    local player2 = game.get_player(command.parameter)
    if not player2 then
        player.print({'wn.ti-player-not-found', command.parameter})
        return
    end

    if player.online_time > player2.online_time * 10 then
        player.print({'wn.ti-success', player.name, player2.name})
        game.kick_player(player2)
    else
        player.print({'wn.ti-failure', player.name, player2.name})
    end
end)

-- 传送
commands.add_command('teleport', {'wn.ti-help'}, function(command)
    if not command.player_index then
        return
    end

    local player = game.get_player(command.player_index)
    if not command.parameter then
        return
    end

    local surface = game.get_surface(command.parameter)
    if not surface then
        player.print({'wn.teleport-surface-not-found', command.parameter})
        return
    end

    for _, inventory_def in pairs({defines.inventory.character_main, defines.inventory.character_armor,
                                   defines.inventory.character_trash}) do
        local inventory = player.get_inventory(inventory_def)
        if inventory and not inventory.is_empty then
            player.print({'wn.teleport-inventory-not-empty'})
            return
        end
    end

    if player.character then
        local pos = surface.find_non_colliding_position('character', {0, 0}, 0, 1)
        player.teleport(pos, surface)
        player.clear_items_inside()
        game.print({'wn.teleport-notice', player.name, surface.name})
    end
end)

script.on_nth_tick(60 * 60, function()
    -- 通知 1分钟一次
    local minutes_left = get_warp_time_left()

    if minutes_left < 100 then
        if (minutes_left < 10) then

            if storage.warp_minutes_total > 1000 then
                game.reset_time_played()
            end

            if minutes_left < 1 then
                run_reset(false)
            else
                print_warp_time_left()
                game.print({'wn.warp-time-warning-2'})
            end
        else
            if minutes_left % 10 == 0 then
                print_warp_time_left()
                game.print({'wn.warp-time-warning-1'})
            end
        end
    else
        if minutes_left % 100 == 0 then
            print_warp_time_left()
        end
    end
end)

script.on_event(defines.events.on_space_platform_changed_state, function(event)
    -- 平台上限
    local platform = event.platform
    if event.old_state == 0 then
        local force = platform.force
        if table_size(force.platforms) > storage.max_platform_count then
            platform.destroy(1)
            game.print({'wn.too-many-platforms', storage.max_platform_count})
        end
    end

    -- 首次到达
    local platform = event.platform
    local location = platform.space_location
    if not location then
        return
    end

    local name = location.name

    if not storage.statistics[name] then
        storage.statistics[name] = 1
    else
        storage.statistics[name] = storage.statistics[name] + 1
    end

    players_gui()

    -- 前往下一个地点
    if name == edge then
        if (can_reset()) then
            run_reset(true)
        end
    end
end)
