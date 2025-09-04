-- local handler = require("event_handler")
-- local functions = require("functions")
-- 常数
local hour_to_tick = 216000
local min_to_tick = 3600

local vulcanus = 'vulcanus'
local fulgora = 'fulgora'
local gleba = 'gleba'
local aquilo = 'aquilo'
local edge = 'solar-system-edge'
local shattered_planet = 'shattered-planet'

local normal = 'normal'
-- local uncommon = 'uncommon'
local rare = 'rare'
-- local epic = 'epic'
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
    player.gui.top.clear()
    player.gui.top.add {
        type = "sprite-button",
        -- sprite = "space-location/solar-system-edge",
        sprite = "virtual-signal/signal-info",
        -- sprite = "item/raw-fish",
        name = "info",
        tooltip = {"wn.introduction", storage.mining_needed}
    }
    player.gui.top.add {
        type = "sprite-button",
        sprite = "virtual-signal/signal-heart",
        -- sprite = "entity/market",
        name = "statistics",
        tooltip = {"", {"wn.statistics-title"}, {"wn.statistics-run", storage.run}, make_tech('cryogenic-science-pack'),
                   make_tech('promethium-science-pack'), make_tech('epic-quality'), make_tech('legendary-quality'),
                   "\n", make_tech('mining-productivity-3'), make_tech('steel-plate-productivity'),
                   make_tech('plastic-bar-productivity'), make_tech('rocket-fuel-productivity'),
                   make_tech('processing-unit-productivity'), make_tech('low-density-structure-productivity'),
                   make_tech('rocket-part-productivity'), "\n", make_tech('asteroid-productivity'),
                   make_tech('scrap-recycling-productivity'), make_tech('research-productivity')}
    }

    player.gui.top.add {
        type = "sprite-button",
        sprite = "space-location/solar-system-edge",
        name = "galaxy",
        tooltip = {"", {"wn.galaxy-trait-title"}, {"wn.galaxy-trait-platform-amount", storage.max_platform_count},
                   {"wn.galaxy-trait-platform-size", storage.max_platform_size}, "\n",
                   {"wn.galaxy-trait-technology_price_multiplier", game.difficulty_settings.technology_price_multiplier},
                   {"wn.galaxy-trait-spawning_rate", game.map_settings.asteroids.spawning_rate},
                   {"wn.galaxy-trait-spoil_time_modifier", game.difficulty_settings.spoil_time_modifier}}
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

local random_asteroids = {1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 5, 6, 7, 7}
local random_techprice = {0.1, 0.2, 0.5, 0.5, 0.5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3, 3,
                          3, 3, 5, 5, 5, 10, 10, 20, 50, 100}
local random_spoiltime = {0.1, 0.2, 0.2, 0.5, 0.5, 0.5, 0.5, 1, 1, 1, 1, 1, 1, 2, 2, 3, 4, 5, 10, 20, 30, 50, 100}

-- 星系信息
local function galaxy_reset()
    -- 更新主线任务
    storage.mining_current = 0
    storage.mining_needed = math.min(100, math.max(10, storage.run))

    game.map_settings.asteroids.spawning_rate = random_asteroids[math.random(1, #random_asteroids)]
    game.difficulty_settings.technology_price_multiplier = random_techprice[math.random(1, #random_techprice)]
    game.difficulty_settings.spoil_time_modifier = random_spoiltime[math.random(1, #random_spoiltime)]

    storage.arrived_edge = false

    -- 刷新星系参数
    -- storage.solar_power_multiplier = math.random(1, 4) * math.random(1, 4) * math.random(1, 4) * 0.1
    storage.max_platform_count = 1 -- math.random(1, 6)
    storage.max_platform_size = math.max(100 + storage.run, storage.run * 2) -- math.random(2, 5) * math.random(2, 5) * 32

    local force = game.forces.player

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
end

-- 重置玩家
local function player_reset(player)
    if game.tick - player.last_online > 48 * hour_to_tick then

    end
    -- player.clear_items_inside() -- 清空玩家
    player.disable_flashlight()
    player.teleport({storage.respawn_x, storage.respawn_y}, game.surfaces.nauvis)

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
    player_reset(player)
    player_gui(player)
end)

-- 删除表面
script.on_event(defines.events.on_surface_deleted, function(event)
    local surface = game.get_surface(event.surface_index)
    if surface then
        game.print({"wn.farewell-surface", {"space-location-name." .. surface.name}})
    end
end)

local function protect(entity)
    entity.minable = false
    entity.destructible = false
end

local function create_entity(name, x, y)
    local panel = game.surfaces.nauvis.create_entity {
        name = name,
        quality = normal,
        position = {
            x = x,
            y = y
        },
        force = 'player'
    }
    protect(panel)
end

-- 重置母星
local function nauvis_reset()

    local force = game.forces.player
    for i, tech in pairs(force.technologies) do
        force.technologies[tech.name].researched = false
    end

    local nauvis = game.surfaces.nauvis

    -- 太阳能
    create_entity('solar-panel', -4.5, -14.5)
    create_entity('solar-panel', 4.5, -14.5)
    create_entity('solar-panel', -1.5, -14.5)
    create_entity('solar-panel', 1.5, -14.5)
    create_entity('solar-panel', -4.5, -17.5)
    create_entity('solar-panel', 4.5, -17.5)
    create_entity('solar-panel', -1.5, -17.5)
    create_entity('solar-panel', 1.5, -17.5)

    create_entity('laser-turret', 4, -10)
    create_entity('laser-turret', -4, -10)
    create_entity('substation', 6, -12)
    create_entity('substation', -6, -12)
    create_entity('accumulator', 4, -12)
    create_entity('accumulator', -4, -12)

    -- 市场
    create_entity('market', storage.market_x, storage.market_y)
    create_entity('market', storage.market_x + 3, storage.market_y)

    local nauvis = game.surfaces.nauvis
    nauvis.peaceful_mode = storage.run <= 1
    local markets = nauvis.find_entities_filtered {
        area = {{-32, -32}, {32, 32}},
        type = "market"
    }

    if #markets ~= 2 then
        game.print({"wn.market-not-found"})
        return
    end

    local market = markets[1]
    market.clear_market_items()

    local items_1 = {'wood', 'stone', 'coal', 'iron-ore', 'copper-ore'}

    for _, item in pairs(items_1) do
        market.add_market_item {
            price = {{
                name = 'coin',
                count = 1
            }},
            offer = {
                type = "give-item",
                item = item
            }
        }
    end

    local items_2 = {'raw-fish', 'biter-egg', 'uranium-ore'}

    for _, item in pairs(items_2) do
        market.add_market_item {
            price = {{
                name = 'coin',
                quality = rare,
                count = 1
            }},
            offer = {
                type = "give-item",
                item = item
            }
        }
    end

    local market = markets[2]

    market.add_market_item {
        price = {{
            name = 'coin',
            quality = normal,
            count = 25
        }},
        offer = {
            type = "give-item",
            item = 'modular-armor'
        }
    }
    market.add_market_item {
        price = {{
            name = 'coin',
            quality = normal,
            count = 1
        }},
        offer = {
            type = "give-item",
            item = 'solar-panel-equipment'
        }
    }
    market.add_market_item {
        price = {{
            name = 'coin',
            quality = normal,
            count = 2
        }},
        offer = {
            type = "give-item",
            item = 'battery-equipment'
        }
    }
    market.add_market_item {
        price = {{
            name = 'coin',
            quality = normal,
            count = 4
        }},
        offer = {
            type = "give-item",
            item = 'night-vision-equipment'
        }
    }
end

local function random_richness()
    return (0.1 + 5 * math.random() * math.random() * math.random()) * storage.richness
end

local function random_radius()
    return (1 + 8 * math.random() * math.random() * math.random()) * storage.radius
end

-- 创建随机表面
script.on_event(defines.events.on_surface_cleared, function(event)
    local surface = game.get_surface(event.surface_index)
    if not surface then
        return
    end

    local mgs = surface.map_gen_settings
    mgs.seed = math.random(1, 4294967295)

    local r
    if surface.name == 'nauvis' then
        r = storage.radius
    else
        r = storage.radius * (0.5 + math.random() + 2 * math.random() * math.random())
        r = math.max(512, r)
        r = math.min(2048, r)
    end

    storage.radius_of[surface.name] = r

    local platform = surface.platform
    if platform then
        local size = storage.max_platform_size
        size = math.max(size, 128)
        mgs.width = size
        mgs.height = size
    else
        mgs.width = r * 2
        mgs.height = r * 2
    end
    -- 重置mgs

    -- nauvis
    -- 'iron-ore', 'copper-ore', 'stone', 'coal', 'crude-oil', 'uranium-ore',

    if surface == game.surfaces.vulcanus then
        local richness = random_richness()

        for _, res in pairs({'vulcanus_coal', 'calcite', 'sulfuric_acid_geyser', 'tungsten_ore'}) do
            mgs.autoplace_controls[res].richness = richness
        end

        local volcanism = 'vulcanus_volcanism'
        mgs.autoplace_controls[volcanism].richness = random_richness()
    end

    if surface == game.surfaces.fulgora then
        for _, res in pairs({'scrap'}) do
            local richness = random_richness()
            mgs.autoplace_controls[res].richness = richness
        end

        local fulgora_islands = 'fulgora_islands'
        mgs.autoplace_controls[fulgora_islands].richness = random_richness()
    end

    if surface == game.surfaces.gleba then
        local res = 'gleba_stone'
        local richness = random_richness()
        mgs.autoplace_controls[res].richness = richness

        local enemy = 'gleba_enemy_base'
        mgs.autoplace_controls[enemy].richness = math.random() * 6
        mgs.autoplace_controls[enemy].size = math.random() * 6
        mgs.autoplace_controls[enemy].frequency = math.random() * 6

        local water = 'gleba_water'
        local richness = random_richness()

        mgs.autoplace_controls[water].richness = richness

        local plants = 'gleba_plants'
        local richness = random_richness()

        mgs.autoplace_controls[plants].richness = richness
    end

    if surface == game.surfaces.aquilo then
        local richness = random_richness()
        for _, res in pairs({'lithium_brine', 'fluorine_vent', 'aquilo_crude_oil'}) do
            mgs.autoplace_controls[res].richness = richness
        end
    end

    surface.map_gen_settings = mgs

    if surface.index ~= 1 then
        return
    end
    local radius = math.floor(storage.radius * 0.7)
    game.forces.player.chart(game.surfaces.nauvis, {{
        x = -radius,
        y = -radius
    }, {
        x = radius,
        y = radius
    }})

    nauvis_reset()
end)

local change_seed = function()
    local rng = math.random(1111, 4294967295)
    local mgs = game.surfaces["nauvis"].map_gen_settings
    mgs.seed = rng
    game.surfaces["nauvis"].map_gen_settings = mgs
    storage.radius_of["nauvis"] = random_radius()

    if game.surfaces["vulcanus"] ~= nil then
        local mgs = game.surfaces["vulcanus"].map_gen_settings
        mgs.seed = rng
        game.surfaces["vulcanus"].map_gen_settings = mgs
        storage.radius_of["vulcanus"] = random_radius()

    end
    if game.surfaces["gleba"] ~= nil then
        local mgs = game.surfaces["gleba"].map_gen_settings
        mgs.seed = rng
        game.surfaces["gleba"].map_gen_settings = mgs
        storage.radius_of["gleba"] = random_radius()

    end
    if game.surfaces["fulgora"] ~= nil then
        local mgs = game.surfaces["fulgora"].map_gen_settings
        mgs.seed = rng
        game.surfaces["fulgora"].map_gen_settings = mgs
        storage.radius_of["fulgora"] = random_radius()

    end
    if game.surfaces["aquilo"] ~= nil then
        local mgs = game.surfaces["aquilo"].map_gen_settings
        mgs.seed = rng
        game.surfaces["aquilo"].map_gen_settings = mgs
        storage.radius_of["aquilo"] = random_radius()

    end
end

-- 跃迁
local function run_reset()

    storage.run = storage.run + 1
    storage.run_start_tick = game.tick

    -- 召回玩家到母星
    for _, player in pairs(game.players) do
        player.teleport({storage.respawn_x, storage.respawn_y}, game.surfaces.nauvis)
    end

    change_seed()
    -- We clear the main surfaces instead of deleting them because the seed can't be changed if they are deleted..
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
    -- We delete space platforms
    -- for _, surface in pairs(game.surfaces) do
    -- 	if surface.platform then
    -- 		game.delete_surface(surface)
    -- 	end
    -- end

    -- nauvis_reset()

    -- 重置玩家势力
    local enemy = game.forces.enemy
    enemy.reset_evolution()

    local force = game.forces.player
    force.reset()
    force.friendly_fire = true
    force.set_spawn_position({storage.respawn_x, storage.respawn_y}, game.surfaces.nauvis)

    -- 重置科技

    -- -- 删除平台
    -- for _, platform in pairs(force.platforms) do
    --     game.print({"wn.farewell-platform", platform.name})
    --     platform.destroy(1)
    -- end

    game.print({"wn.warp-success-time", math.floor(game.tick / hour_to_tick),
                math.floor((game.tick % min_to_tick) / min_to_tick)})
    game.reset_time_played()

    -- 更新本run
    galaxy_reset()

    -- 更新UI信息
    players_gui()

    -- 重置玩家
    for _, player in pairs(game.players) do
        player_reset(player)
    end
end

-- 第一次运行场景时触发
script.on_init(function()
    game.speed = 1
    storage.run = -1

    storage.respawn_x = 0
    storage.respawn_y = -5

    storage.statistics = {}

    storage.speed_penalty_enabled = false
    storage.speed_penalty_day = 5

    storage.mining_current = 0
    storage.mining_needed = 10

    storage.last_warp_tick = 0
    storage.last_warp_count = 0

    storage.market_x = -2
    storage.market_y = -12

    -- storage.requester_x = 1
    -- storage.requester_y = -11

    -- storage.storage_x = 1
    -- storage.storage_y = -12

    -- storage.provider_x = 1
    -- storage.provider_y = -13

    -- storage.pad_x = 0
    -- storage.pad_y = 0

    storage.richness = 1
    storage.radius = 1024
    storage.radius_of = {}

    -- 母星污染
    game.map_settings.pollution.enabled = true

    game.map_settings.pollution.ageing = 0.1
    game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 0.1

    run_reset()
end)

script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "suicide" then
    end
end)

-- 玩家进入游戏
script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.get_player(event.player_index)

    local welcome = {}
    if player.online_time > 0 then
        local last_delta = math.max(0, math.floor((game.tick - player.last_online) / hour_to_tick))
        local total_time = math.max(0, math.floor(player.online_time / hour_to_tick))
        welcome = {"wn.welcome-player", player.name, total_time, last_delta}
    else
        welcome = {"wn.welcome-new-player", player.name}
    end
    game.print(welcome)
end)

script.on_event(defines.events.on_pre_surface_cleared, function(event)
    -- if event.surface_index == 1 then
    --     -- We need to kill all players _before_ the surface is cleared, so that
    --     -- their inventory, and crafting queue, end up on the old surface
    --     for _, pl in pairs(game.players) do
    --         if pl.connected and pl.character ~= nil then
    --             -- We call die() here because otherwise we will spawn a duplicate
    --             -- character, who will carry over into the new surface
    --             pl.character.die()
    --         end
    --         -- Setting [ticks_to_respawn] to 1 seems to consistantly kill offline
    --         -- players. Calling this for online players will cause them instead be
    --         -- respawned the next tick, skipping the 10 respawn second timer.
    --         pl.ticks_to_respawn = 1
    --         --  Need to teleport otherwise offline players will force generate many chunks on new surface at their position on old surface when they rejoin.
    --         pl.teleport({0, 0}, "nauvis")
    --     end
    -- end
end)

-- 星球圆形地块生成
script.on_event(defines.events.on_chunk_generated, function(event)
    local surface = event.surface
    -- local chunk_position = event.position
    local left_top = event.area.left_top

    if surface == game.surfaces.nauvis then
        -- -- 无敌虫巢和树和石头
        -- local entities_list = { 'unit-spawner', 'tree', 'simple-entity', }

        -- for _, entity_type in pairs(entities_list)
        -- do
        --     local entities = surface.find_entities_filtered({
        --         area = event.area,
        --         type = entity_type
        --     })
        --     if entities then
        --         for i, entity in pairs(entities) do
        --             entity.minable = false
        --             entity.destructible = false
        --         end
        --     end
        -- end

        -- 超富矿
        local ores = game.surfaces[1].find_entities_filtered {
            area = event.area,
            name = {"iron-ore", "copper-ore", "stone", "coal", "uranium-ore"}
        }

        if ores then
            for i, entity in pairs(ores) do
                entity.amount = (entity.amount + math.random()) * 10 -- math.min(4294967295, entity.amount * 10000 + 10000 * math.random())
            end
        end
    end

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
    if #tiles > 0 then
        surface.set_tiles(tiles)
    end
end)

local function startswith(str, start)
    return string.sub(str, 1, #start) == start
end

local function endswith(str, ending)
    return ending == "" or string.sub(str, -#ending) == ending
end

local function print_mining_productivity_level()
    game.print({"wn.warp-process", storage.mining_current, storage.mining_needed})
end

local function can_reset()
    return storage.mining_current >= storage.mining_needed and storage.arrived_edge
end

local function try_reset()
    if can_reset() then
        run_reset()
        return true
    else
        return false
    end
end

script.on_event(defines.events.on_research_finished, function(event)

    local research_name = event.research.name
    if research_name == "mining-productivity-3" then
        storage.mining_current = event.research.level - 1
        if (can_reset()) then
            -- run_reset()
            if (not event.by_script) then
                print_mining_productivity_level()
            end

            game.print({"wn.warp-command-hint"})
        else
            if (not event.by_script) then
                print_mining_productivity_level()
            end

        end
    elseif research_name == "mining-productivity-2" then
        storage.mining_current = 2
        if (not event.by_script) then
            print_mining_productivity_level()
        end

    elseif research_name == "mining-productivity-1" then
        storage.mining_current = 1
        if (not event.by_script) then
            print_mining_productivity_level()
        end

    end

    if not storage.statistics[research_name] then
        storage.statistics[research_name] = 1
    else
        storage.statistics[research_name] = storage.statistics[research_name] + 1
    end
    players_gui()
end)

-- 手动重置
commands.add_command("run_reset", {"wn.run-reset-help"}, function(command)
    local player = game.get_player(command.player_index)
    if not player or player.admin then
        run_reset()
    else
        player.print(not_admin_text)
    end
end)

-- 手动跃迁
commands.add_command("warp", {"wn.warp-help"}, function(command)
    local player_name = "<server>"
    local player = nil
    if command.player_index then
        player = game.get_player(command.player_index)
        player_name = player.name
    end

    if player and player.online_time < 60 * 60 * 60 * 6 then
        player.print({"wn.warp-permission-denied"})
    end

    local count = 3
    if not can_reset() then
        if player then
            player.print({"wn.warp-condition-false"})
        end
    else
        storage.last_warp = game.tick
        if game.tick - storage.last_warp > 60 * 10 then
            storage.last_warp_count = 0
            game.print({"wn.player-warp-1", player_name})
        elseif storage.last_warp_count < count then
            storage.last_warp_count = storage.last_warp_count + 1
            game.print({"wn.player-warp-2", player_name, storage.last_warp_count})
        else
            game.print({"wn.player-warp-3", player_name})
            run_reset()
        end
    end
end)

script.on_nth_tick(60 * 60 * 60, function()
    -- 奖金发放 60分钟一次
    local salary = storage.run;
    if salary <= 0 then
        salary = 1
    end
    for _, player in pairs(game.connected_players) do -- Table iteration.
        player.insert {
            name = "coin",
            count = salary
        }
    end
    game.print({"wn.give-salary", salary})
end)

script.on_nth_tick(60 * 60 * 180, function()
    -- 修改游戏运行速度
    if not storage.speed_penalty_enabled then
        return
    end

    local time_played = game.tick - storage.run_start_tick

    local game_speed = 60 * 60 * 60 * 24 * storage.speed_penalty_day / (1 + time_played)
    game_speed = math.min(game_speed, 1)
    game_speed = math.max(game_speed, 0.125)

    if game.speed < 1 then
        game.speed = game_speed
        game.print({"wn.game-speed-penalty", game_speed})
    end
end)

script.on_event(defines.events.on_space_platform_changed_state, function(event)
    -- 平台上限
    local platform = event.platform
    if event.old_state == 0 then
        local force = platform.force
        if #force.platforms > storage.max_platform_count then
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
    game.print({"wn.congrats-first-visit", name})
    players_gui()

    -- 前往下一个地点
    if name == edge then
        storage.arrived_edge = true
    end
end)
