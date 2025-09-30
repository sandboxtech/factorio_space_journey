-- local handler = require("event_handler")
-- local functions = require("functions")
-- 常数
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
local not_admin_text = {"wn.permission-denied"}

local function make_location(name)
    return {"wn.statistics-run-location", storage.statistics[name] or 0, name}
end

local function make_tech(name)
    return {"wn.statistics-run-tech", storage.statistics[name] or 0, name}
end

-- 左上角信息内容
local function player_gui(player)

    if not storage.current_hostname then
        storage.current_hostname = 'dx.moe.xin:37001'
    end

    player.gui.top.clear()
    player.gui.top.add {
        type = "sprite-button",
        -- sprite = "space-location/solar-system-edge",
        sprite = "virtual-signal/signal-info",
        -- sprite = "item/raw-fish",
        name = "info",
        tooltip = {"wn.introduction", storage.warp_minutes_per_tech, storage.warp_minutes_per_rocket,
                   storage.current_hostname}
    }
    player.gui.top.add {
        type = "sprite-button",
        sprite = "virtual-signal/signal-heart",
        -- sprite = "entity/market",
        name = "statistics",
        tooltip = {"", {"wn.statistics-title"},
                   {"wn.statistics-run", math.ceil(game.tick / day_to_tick), storage.run_auto, storage.run_perfect},

                   {"wn.statistics-title-tech"},
                   {"", make_tech('automation-science-pack'), make_tech('logistic-science-pack'),
                    make_tech('chemical-science-pack'), make_tech('production-science-pack'),
                    make_tech('utility-science-pack'), make_tech('space-science-pack'),
                    make_tech('metallurgic-science-pack'), make_tech('agricultural-science-pack'),
                    make_tech('electromagnetic-science-pack'), make_tech('cryogenic-science-pack'),
                    make_tech('promethium-science-pack'), "\n"},
                   {"", make_tech('epic-quality'), make_tech('legendary-quality'), "\n"},
                   {"", make_tech('mining-productivity-3'), make_tech('steel-plate-productivity'),
                    make_tech('plastic-bar-productivity'), make_tech('rocket-fuel-productivity'),
                    make_tech('processing-unit-productivity'), make_tech('low-density-structure-productivity'),
                    make_tech('rocket-part-productivity'), make_tech('asteroid-productivity'),
                    make_tech('scrap-recycling-productivity'), make_tech('research-productivity'), "\n"},

                   {"", make_tech('physical-projectile-damage-7'), make_tech('stronger-explosives-7'),
                    make_tech('refined-flammables-7'), make_tech('laser-weapons-damage-7'),
                    make_tech('electric-weapons-damage-4'), make_tech('artillery-shell-damage-1'),
                    make_tech('railgun-damage-1'), "\n"}}

    }

    player.gui.top.add {
        type = "sprite-button",
        sprite = "space-location/solar-system-edge",
        name = "galaxy",
        tooltip = {"", {"wn.galaxy-trait-platform-amount", storage.max_platform_count},
                   {"wn.galaxy-trait-platform-size", storage.max_platform_size}, {"wn.galaxy-trait-title"},
                   {"wn.galaxy-trait-technology_price_multiplier", game.difficulty_settings.technology_price_multiplier},
                   {"wn.galaxy-trait-spawning_rate", game.map_settings.asteroids.spawning_rate},
                   {"wn.galaxy-trait-spoil_time_modifier", game.difficulty_settings.spoil_time_modifier},
                   {"wn.galaxy-trait-solar_power_multiplier", storage.solar_power_multiplier}, {"wn.galaxy-trait-more"}}
    }
end

local function players_gui()
    for _, player in pairs(game.players) do
        player_gui(player)
    end
end

-- 手动重置players_gui
commands.add_command("players_gui", {"wn.players-gui-help"}, function(command)
    local player = game.get_player(command.player_index)
    if not player or player.admin then
        players_gui()
    else
        player.print(not_admin_text)
    end
end)

-- 重置玩家
local function player_reset(player)
    if not player then
        return
    end
    if game.tick - player.last_online > 48 * hour_to_tick then
        -- pass
    end
    player.clear_items_inside() -- 清空玩家
    player.disable_flashlight()
    -- local pos = game.surfaces.nauvis.find_non_colliding_position('character', {storage.respawn_x, storage.respawn_y}, 0,
    --     1)
    -- player.teleport(pos, game.surfaces.nauvis)
end

-- 开图
script.on_event(defines.events.on_player_respawned, function(event)
    local player = game.get_player(event.player_index)
    if player then
        local radius = 256
        player.force.chart(player.surface, {{
            x = -radius,
            y = -radius
        }, {
            x = radius,
            y = radius
        }})
    end
end)

-- 创建玩家
script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    player_reset(player)
    player_gui(player)
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
    entity.minable = false
    entity.destructible = false
end

-- 重置母星
local function nauvis_reset()
    create_entity('rocket-silo', 5, 5)
end

-- 数字格式
local function readable(x)
    if x < 0.1 then
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
        storage.nature = 5
    end
    return readable(math.pow(2, (math.random() - math.random()) * storage.nature))
end

-- 创建随机表面
script.on_event(defines.events.on_surface_created, function(event)
    local surface = game.get_surface(event.surface_index)
    if not surface then
        return
    end

    local mgs = surface.map_gen_settings
    mgs.seed = math.random(1, 4294967295)

    local platform = surface.platform
    if platform then
        local size = storage.max_platform_size
        size = math.max(size, 96)
        mgs.width = size
        mgs.height = 512
    end
    surface.map_gen_settings = mgs
end)

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
    surface.min_brightness = 0.15 * (2 * math.random())
    surface.wind_speed = 0.02 * (0.5 + math.random())
    surface.wind_orientation = math.random()
    surface.wind_orientation_change = 0.0001 * (0.5 + math.random())
    surface.solar_power_multiplier = storage.solar_power_multiplier

    if math.random(1, 5) == 1 then
        -- 潮汐锁定，永昼
        surface.freeze_daytime = true
        surface.daytime = 0
    elseif math.random(1, 10) == 1 then
        -- 潮汐锁定，永夜
        surface.freeze_daytime = true
        surface.daytime = 0.5
        surface.solar_power_multiplier = storage.solar_power_multiplier * 0.1
    end

    if not storage.radius then
        storage.radius = 1024
    end
    -- 刷新星球半径
    local r = storage.radius * random_exp(3)
    r = math.max(192, r)
    r = math.min(2048, r)
    if surface == game.surfaces.nauvis then
        r = r * 1.5 -- 母星更大？
    end
    storage.radius_of[surface.name] = r

    mgs.width = r * 2 + 32
    mgs.height = r * 2 + 32

    -- 母星
    if surface == game.surfaces.nauvis then
        surface.peaceful_mode = false

        for _, res in pairs({'iron-ore', 'copper-ore', 'stone', 'coal', 'crude-oil', 'uranium-ore'}) do
            mgs.autoplace_controls[res].size = random_size()
            mgs.autoplace_controls[res].richness = random_richness()
            mgs.autoplace_controls[res].frequency = random_frequency()
        end

        for _, res in pairs({'water', 'trees', 'enemy-base', 'rocks', 'nauvis_cliff'}) do
            mgs.autoplace_controls[res].richness = random_richness()
            mgs.autoplace_controls[res].frequency = random_frequency()
        end

        mgs.autoplace_controls['nauvis_cliff'].richness = random_nature()
        mgs.autoplace_controls['nauvis_cliff'].frequency = random_nature()
        mgs.autoplace_controls['nauvis_cliff'].size = random_nature()

        mgs.autoplace_controls['starting_area_moisture'].richness = random_nature()
        mgs.autoplace_controls['starting_area_moisture'].frequency = random_nature()
        mgs.autoplace_controls['starting_area_moisture'].size = random_nature()

    end

    -- 火星
    if surface == game.surfaces.vulcanus then

        for _, res in pairs({'vulcanus_coal', 'calcite', 'sulfuric_acid_geyser'}) do
            mgs.autoplace_controls[res].size = random_size()
            mgs.autoplace_controls[res].richness = random_richness()
            mgs.autoplace_controls[res].frequency = random_frequency()
        end
        for _, res in pairs({'tungsten_ore'}) do
            mgs.autoplace_controls[res].size = random_size()
            mgs.autoplace_controls[res].richness = random_richness() * storage.local_specialty_multiplier
            mgs.autoplace_controls[res].frequency = random_frequency()
        end
        mgs.autoplace_controls['vulcanus_volcanism'].size = random_nature()
        mgs.autoplace_controls['vulcanus_volcanism'].frequency = random_nature()
    end

    -- 雷星
    if surface == game.surfaces.fulgora then
        for _, res in pairs({'scrap'}) do
            mgs.autoplace_controls[res].size = random_size()
            mgs.autoplace_controls[res].richness = random_richness() * storage.local_specialty_multiplier
            mgs.autoplace_controls[res].frequency = random_frequency()
        end

        mgs.autoplace_controls['fulgora_islands'].richness = random_nature()
        mgs.autoplace_controls['fulgora_islands'].size = random_nature()
        mgs.autoplace_controls['fulgora_islands'].frequency = random_nature()

        mgs.autoplace_controls['fulgora_cliff'].richness = random_nature()
        mgs.autoplace_controls['fulgora_cliff'].size = random_nature()
        mgs.autoplace_controls['fulgora_cliff'].frequency = random_nature()
    end

    -- 草星
    if surface == game.surfaces.gleba then
        surface.peaceful_mode = false

        mgs.autoplace_controls['gleba_stone'].richness = random_richness()

        mgs.autoplace_controls['gleba_enemy_base'].richness = math.random() * 6
        mgs.autoplace_controls['gleba_enemy_base'].size = math.random() * 6
        mgs.autoplace_controls['gleba_enemy_base'].frequency = math.random() * 6

        mgs.autoplace_controls['gleba_water'].richness = random_nature()
        mgs.autoplace_controls['gleba_water'].size = random_nature()
        mgs.autoplace_controls['gleba_water'].frequency = random_nature()

        mgs.autoplace_controls['gleba_plants'].richness = random_nature()
        mgs.autoplace_controls['gleba_plants'].size = random_nature()
        mgs.autoplace_controls['gleba_plants'].frequency = random_nature()
    end

    if surface == game.surfaces.aquilo then
        for _, res in pairs({'lithium_brine', 'fluorine_vent', 'aquilo_crude_oil'}) do
            mgs.autoplace_controls[res].richness = random_richness() * storage.local_specialty_multiplier * 0.5
        end
    end

    surface.map_gen_settings = mgs

    if surface.index ~= 1 then
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

    storage.run_start_tick = game.tick
    storage.statistics_in_run = {}

    -- 更新主线任务
    -- storage.mining_current = 0
    -- storage.mining_needed = math.min(100, math.max(10, storage.run))

    if storage.run >= 1 and is_perfect then
        -- 统计玩家
        if not storage.player_failure_count then
            storage.player_failure_count = {}
        end
        if not storage.player_success_count then
            storage.player_success_count = {}
        end

        for _, player in pairs(game.players) do
            if player.connected then

                if player.surface.platform then
                    game.print({"wn.player-success", player.name})
                    if not storage.player_success_count[player.name] then
                        storage.player_success_count[player.name] = 1
                    else
                        storage.player_success_count[player.name] = storage.player_success_count[player.name] + 1
                    end

                else
                    game.print({"wn.player-failure", player.name})
                end
            end
        end
    end

    -- 重置玩家
    for _, player in pairs(game.players) do
        if player.surface and not player.surface.platform and player.character and player.character.die then
            player.character.die() -- die?
            player_reset(player)
        else
            if player.get_inventory then
                local inventory = player.get_inventory(defines.inventory.character_main)
                if inventory and inventory.is_empty() then
                    player.insert {
                        name = "processing-unit",
                        count = 100
                    }
                    player.insert {
                        name = "low-density-structure",
                        count = 100
                    }
                    player.insert {
                        name = "rocket-fuel",
                        count = 100
                    }
                end
            end
        end
    end

    game.surfaces["nauvis"].clear(true)
    if game.surfaces["vulcanus"] ~= nil then
        game.surfaces["vulcanus"].clear(true)
    end
    if game.surfaces["gleba"] ~= nil then
        game.surfaces["gleba"].clear(true)
    end
    if game.surfaces["fulgora"] ~= nil then
        game.surfaces["fulgora"].clear(true)
    end
    if game.surfaces["aquilo"] ~= nil then
        game.surfaces["aquilo"].clear(true)
    end

    -- 重置玩家势力

    local force = game.forces.player
    force.reset()
    force.friendly_fire = true
    force.set_spawn_position({storage.respawn_x, storage.respawn_y}, game.surfaces.nauvis)

    -- 重置科技

    -- game.print({"wn.warp-success-time", math.floor(game.tick / hour_to_tick),
    --             math.floor((game.tick % min_to_tick) / min_to_tick)})
    game.reset_time_played()

    -- 母星污染
    game.forces.enemy.reset_evolution()
    game.map_settings.enemy_expansion.enabled = false
    game.map_settings.pollution.enabled = true
    game.map_settings.pollution.ageing = readable(random_exp(3))
    game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = readable(random_exp(3))

    game.map_settings.asteroids.spawning_rate = readable(random_exp(4))
    game.difficulty_settings.spoil_time_modifier = readable(0.3 + random_exp(4))
    game.difficulty_settings.technology_price_multiplier = readable(random_exp(3))

    if not storage.warp_minutes_per_tech_multiplayer then
        storage.warp_minutes_per_tech_multiplayer = 10
    end
    storage.warp_minutes_per_tech = math.ceil(storage.warp_minutes_per_tech_multiplayer *
                                                  game.difficulty_settings.technology_price_multiplier)
    storage.warp_minutes_total = math.max(3, storage.warp_minutes_per_tech)

    -- 刷新星系参数
    storage.solar_power_multiplier = readable(random_exp(4))
    -- storage.max_platform_count = 1 -- math.random(1, 6)
    if storage.run_perfect == 0 then
        storage.max_platform_size = 50
    elseif storage.run_perfect <= 10 then
        storage.max_platform_size = 100 * storage.run_perfect
    elseif storage.run_perfect <= 100 then
        storage.max_platform_size = 2000 + 10 * storage.run_perfect
    else
        storage.max_platform_size = math.max(3000 + storage.run_perfect, storage.run_perfect * 2)
    end

    -- 初始赠送科技
    local function research_recursive(name)
        game.forces.player.technologies[name].research_recursive()
        game.print({"wn.free-tech", name})
    end

    -- local tech_price = game.difficulty_settings.technology_price_multiplier
    -- if tech_price >= 20 then
    --     research_recursive('space-science-pack')
    --     research_recursive('production-science-pack')
    --     research_recursive('utility-science-pack')
    -- elseif tech_price >= 10 then
    --     research_recursive('space-science-pack')
    --     research_recursive('production-science-pack')
    -- elseif tech_price >= 5 then
    --     research_recursive('space-science-pack')
    -- elseif tech_price >= 2 then
    --     research_recursive('chemical-science-pack')
    -- elseif tech_price >= 1 then
    --     research_recursive('logistic-science-pack')
    -- elseif tech_price >= 0.5 then
    --     research_recursive('automation-science-pack')
    -- elseif tech_price >= 0.2 then

    -- end

    local force = game.forces.player
    if storage.run >= 1 then
        force.technologies['oil-processing'].researched = true
        force.technologies['uranium-mining'].researched = true
        force.technologies['space-platform'].researched = true
        -- force.technologies['space-science-pack'].researched = true
        force.technologies['planet-discovery-vulcanus'].researched = true
        force.technologies['planet-discovery-gleba'].researched = true
        force.technologies['planet-discovery-fulgora'].researched = true
        force.technologies['planet-discovery-aquilo'].researched = true
        force.unlock_space_location(nauvis)
        force.unlock_space_location(vulcanus)
        force.unlock_space_location(gleba)
        force.unlock_space_location(fulgora)
        force.unlock_space_location(aquilo)
    end

    if is_perfect then
        research_recursive('space-science-pack')
        force.laboratory_productivity_bonus = 2
    end

    local productivity_techs = {'rocket-fuel-productivity', 'low-density-structure-productivity',
                                'processing-unit-productivity', 'rocket-part-productivity'}

    local productivity_techs_2 = {'steel-plate-productivity', 'plastic-bar-productivity', 'asteroid-productivity',
                                  'scrap-recycling-productivity'}

    for _, techs in pairs({productivity_techs, productivity_techs_2}) do
        for _, tech in pairs(techs) do
            if math.random(10) == 1 then
                force.technologies[tech].researched = true
                force.technologies[tech].level = 100
                break
            end
        end
    end

    -- 更新UI信息
    players_gui()

end

-- 第一次运行场景时触发
script.on_init(function()
    game.speed = 1
    storage.max_platform_count = 1

    storage.run = -1 -- 总跃迁次数
    storage.run_auto = -1 -- 自动跃迁次数
    storage.run_perfect = 0 -- 完美跃迁次数

    storage.warp_minutes_per_tech = 10 -- 每个科技增加时间
    storage.warp_minutes_per_rocket = 1 -- 每个火箭减少时间

    storage.respawn_x = 0
    storage.respawn_y = 0

    storage.statistics = {}
    storage.statistics_in_run = {}

    storage.last_warp_tick = 0
    storage.last_warp_count = 0

    storage.richness = 1
    storage.frequency = 1
    storage.size = 1
    storage.local_specialty_multiplier = 0.2

    storage.radius = 2048
    storage.radius_of = {}

    run_reset(false)
end)

script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "suicide" then
        -- 紫砂
    end
end)

script.on_event(defines.events.on_player_left_game, function(event)
    if not event.player then
        return
    end
    event.player.gui.top.clear()
end)

local function get_warp_time_left()
    local minutes_gone = math.ceil((game.tick - storage.run_start_tick) / min_to_tick)
    local minutes_left = storage.warp_minutes_total - minutes_gone
    return minutes_left
end

local function print_warp_time_left()
    game.print({'wn.warp-time-left', get_warp_time_left()})
end

-- 玩家进入游戏
script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.get_player(event.player_index)

    if table_size(game.connected_players) <= 1 then
        for _, player in pairs(game.players) do
            -- player.clear_console()
            print_warp_time_left()
        end
    end

    local welcome = {}
    if player.online_time > 0 then
        local last_delta = math.max(0, math.floor((game.tick - player.last_online) / hour_to_tick))
        local total_time = math.max(0, math.floor(player.online_time / hour_to_tick))
        welcome = {"wn.welcome-player", player.name, total_time, last_delta}

        -- 打印通关次数
        if not storage.player_failure_count then
            storage.player_failure_count = {}
        end
        if not storage.player_success_count then
            storage.player_success_count = {}
        end

        if storage.player_success_count[player.name] or storage.player_failure_count[player.name] then
            local success = storage.player_success_count[player.name] or 0
            local failure = storage.player_failure_count[player.name] or 0
            game.print({"wn.welcome-player-success", success})
        end
    else
        welcome = {"wn.welcome-new-player", player.name}
        -- [item=processing-unit]
        -- [item=low-density-structure]
        -- [item=rocket-fuel]
        -- [item=space-platform-starter-pack]
        player.insert {
            name = "processing-unit",
            count = 200
        }
        player.insert {
            name = "low-density-structure",
            count = 200
        }
        player.insert {
            name = "rocket-fuel",
            count = 200
        }
        player.insert {
            name = "space-platform-starter-pack",
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

    -- if surface == game.surfaces.nauvis then
    --     -- 母星富矿
    --     local ores = game.surfaces[1].find_entities_filtered {
    --         area = event.area,
    --         name = {"iron-ore", "copper-ore", "stone", "coal", "uranium-ore"}
    --     }
    --     if ores then
    --         for i, entity in pairs(ores) do
    --             entity.amount = (entity.amount + math.random()) * 4
    --         end
    --     end
    -- end

    -- 圆形地图
    local r = storage.radius_of[surface.name]
    if not r then
        r = storage.radius
    end

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
end)

local function can_reset()
    return game.forces.player.technologies['promethium-science-pack'].researched
end

script.on_event(defines.events.on_rocket_launched, function(event)
    local decrease = math.ceil(get_warp_time_left() * (storage.warp_minutes_per_rocket) / 100)
    decrease = math.min(storage.warp_minutes_per_tech, decrease)
    decrease = math.max(1, decrease)
    storage.warp_minutes_total = storage.warp_minutes_total - decrease
    game.print({'wn.warp-time-rocket', decrease, get_warp_time_left()})
end)

script.on_event(defines.events.on_player_died, function(event)
    local decrease = storage.warp_minutes_per_death
    storage.warp_minutes_total = storage.warp_minutes_total - decrease
    game.print({'wn.warp-time-death', decrease, get_warp_time_left()})
end)

script.on_event(defines.events.on_research_finished, function(event)

    local research = event.research
    local research_name = research.name

    if not event.by_script then
        -- 增加时间
        if research.prototype and not research.prototype.research_trigger then
            storage.warp_minutes_total = storage.warp_minutes_total + storage.warp_minutes_per_tech
            game.print({'wn.warp-time-tech', storage.warp_minutes_per_tech, get_warp_time_left()})
        end

        -- 自动添加无限科技
        if research.level > 5 then
            local queue = game.forces.player.research_queue
            queue[table_size(queue) + 1] = research
            game.forces.player.research_queue = queue
            game.print({'wn.start-tech', research.name})
        end

        if not storage.statistics[research_name] then
            storage.statistics[research_name] = 1
        else
            storage.statistics[research_name] = storage.statistics[research_name] + 1
        end
    end
    players_gui()
end)

-- 手动重置
commands.add_command("run_auto", {"wn.run-reset-help"}, function(command)
    local player = game.get_player(command.player_index)
    if not player or player.admin then
        run_reset(false)
    else
        player.print(not_admin_text)
    end
end)

-- 手动重置
commands.add_command("run_perfect", {"wn.run-reset-help"}, function(command)
    local player = game.get_player(command.player_index)
    if not player or player.admin then
        run_reset(true)
    else
        player.print(not_admin_text)
    end
end)

-- 自杀
commands.add_command("suiside", {"wn.suicide-help"}, function(command)
    local player = game.get_player(command.player_index)
    if player.character then
        player.character.die()
    end
end)

-- 查询剩余时间
commands.add_command("time_left", {"wn.suicide-help"}, function(command)
    local player = game.get_player(command.player_index)
    if player.character then
        local time_left = get_warp_time_left()
        player.print({'wn.warp-time-left', time_left})
    end
end)

script.on_nth_tick(60 * 60, function()
    -- 通知 1分钟一次
    local minutes_left = get_warp_time_left()

    if minutes_left < 100 then
        if (minutes_left < 10) then
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
            game.print({"wn.too-many-platforms", storage.max_platform_count})
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
    if not storage.statistics_in_run then
        storage.statistics_in_run = {}
    end
    if not storage.statistics_in_run[name] then
        storage.statistics_in_run[name] = true
        game.print({"wn.congrats-first-visit", name})
    end
    players_gui()

    -- 前往下一个地点
    if name == edge then
        if (can_reset()) then
            run_reset(true)
        end
    end
end)
