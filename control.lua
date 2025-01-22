-- local handler = require("event_handler")
-- local functions = require("functions")
-- 常数
local hour_to_tick = 216000
local min_to_tick = 3600
local normal = 'normal'
local uncommon = 'uncommon'
local rare = 'rare'
local epic = 'epic'
local legendary = 'legendary'
local not_admin_text = {"wn.permission-denied"}

-- 左上角信息内容
local function player_gui(player)
    player.gui.top.clear()
    local info = player.gui.top.add {
        type = "sprite-button",
        -- sprite = "space-location/solar-system-edge",
        sprite = "virtual-signal/signal-info",
        name = "info",
        tooltip = storage.info
    }
    local galaxy = player.gui.top.add {
        type = "sprite-button",
        sprite = "space-location/solar-system-edge",
        name = "galaxy",
        tooltip = storage.galaxy
    }
    local rank = player.gui.top.add {
        type = "sprite-button",
        sprite = "entity/character",
        name = "rank",
        tooltip = storage.rank
    }
end

-- 手动重置nauvis
commands.add_command("players_gui", nil, function(command)
    local player = game.get_player(command.player_index)
    if not player or player.admin then
        for _, player in pairs(game.players) do player_gui(player) end
    else
        player.print(not_admin_text)
    end
end)

-- 左上角游戏教程信息
local function info_reset()
    -- storage.info = "\n" .. "[img=item/thruster]已经完成 " .. storage.run ..
    --     " 次跃迁\n\n" ..
    --     "[img=technology/mining-productivity-3]研究采矿产能 " ..
    --     storage.mining_needed ..
    --     " 级，跃迁至下一个星系！\n\n" ..
    --     "[img=space-location/solar-system-edge]每个星系有不同的特色\n\n" ..
    --     "[img=space-location/solar-system-edge]在富饶的星系获取资源\n\n" ..
    --     "[img=space-location/solar-system-edge]通过跃迁离开贫瘠星系\n\n\n" ..
    --     "[img=space-location/nauvis]跃迁时，母星和玩家背包会保留\n\n" ..
    --     "[img=item/lab]跃迁时，科技会重置\n\n" ..
    --     "[img=item/space-platform-foundation]跃迁时，太空平台无法带走\n\n" ..
    --     "[img=item/production-science-pack]跃迁前，记得掠夺外星，在母星屯满各种货物\n\n" ..
    --     "[img=item/requester-chest][img=item/passive-provider-chest]跃迁后，星系市场会刷新[img=quality/epic][img=quality/legendary]货物订单\n\n" ..
    --     "[img=item/storage-chest]跃迁后，星系市场会刷新奖励，需要[img=technology/research-productivity]\n\n" ..
    --     "[img=item/coin]跃迁次数越多，定期发放金币越多\n\n" ..
    --     "[img=entity/big-wriggler-pentapod]BUG反馈 Q群 293280221\n\n"
    storage.info = {"wn.storage-info", storage.run, storage.mining_needed}
end

-- 星系信息
local function galaxy_reset()
    storage.trade_done = 0
    storage.trade_init = 1000
    local random_packs = {
        'automation-science-pack', 'logistic-science-pack',
        'military-science-pack', 'chemical-science-pack',
        'production-science-pack', 'utility-science-pack', 'space-science-pack',
        'metallurgic-science-pack', 'electromagnetic-science-pack', 'spoilage',
        'cryogenic-science-pack', 'promethium-science-pack'
    }
    local random_pack = random_packs[math.random(#random_packs)]

    storage.requester_count = 1000
    storage.requester_type = random_pack
    storage.requester_quality = rare
    storage.requester_text =
        '[item=' .. storage.requester_type .. ',quality=' ..
            storage.requester_quality .. '] x ' .. storage.requester_count

    storage.provider_count = 1
    storage.provider_type = random_pack
    storage.provider_quality = epic
    storage.provider_text = '[item=' .. storage.provider_type .. ',quality=' ..
                                storage.provider_quality .. '] x ' ..
                                storage.provider_count

    storage.reward_flag = 0
    storage.reward_count = 10
    storage.reward_type = 'coin'
    storage.reward_quality = epic
    storage.reward_text = '[item=' .. storage.reward_type .. ',quality=' ..
                              storage.reward_quality .. '] x ' ..
                              storage.reward_count

    -- 刷新星系参数
    storage.solar_power_multiplier = math.random(1, 4) * math.random(1, 4) *
                                         math.random(1, 4) * 0.1
    storage.max_platform_count = math.random(1, 6)
    storage.max_platform_size = math.random(2, 5) * math.random(2, 5) * 32

    storage.galaxy = {
        "", {"wn.galaxy-trait-title"},
        {"wn.galaxy-trait-solar", storage.solar_power_multiplier},
        {"wn.galaxy-trait-platform-amount", storage.max_platform_count},
        {"wn.galaxy-trait-platform-size", storage.max_platform_size}
    }

    local force = game.forces.player

    local productivity_techs = {
        'rocket-fuel-productivity', 'low-density-structure-productivity',
        'processing-unit-productivity', 'rocket-part-productivity'
    }

    local productivity_techs_2 = {
        'steel-plate-productivity', 'plastic-bar-productivity',
        'asteroid-productivity', 'scrap-recycling-productivity'
    }

    for _, techs in pairs({productivity_techs, productivity_techs_2}) do
        for _, tech in pairs(techs) do
            if math.random(10) == 1 then
                force.technologies[tech].researched = true
                force.technologies[tech].level = 100
                storage.galaxy = {
                    "", storage.galaxy, {"wn.galaxy-trait-technology", tech}
                }
                break
            end
        end
    end

    storage.galaxy = {
        "", storage.galaxy, {
            "wn.galaxy-trade", storage.requester_text, storage.provider_text,
            storage.reward_text
        }
    }
end

-- 查看交易信息
commands.add_command("trade", nil, function(command)
    local player = game.get_player(command.player_index)
    if not player then return end
    -- player.print('最大交易次数 ' .. storage.trade_init)
    player.print({"wn.galaxy-trade-max", storage.trade_init})
    -- player.print('完成交易次数 ' .. storage.trade_done)
    player.print({"wn.galaxy-trade-done", storage.trade_done})
    -- player.print('\n星系[item=requester-chest]收购\n' ..
    --     storage.requester_text)
    player.print({"wn.galaxy-trade-request", storage.requester_text})
    -- player.print('\n星系[item=passive-provider-chest]生产\n' ..
    --     storage.provider_text)
    player.print({"wn.galaxy-trade-provide", storage.provider_text})
    -- player.print('\n星系[item=storage-chest]奖励\n' .. storage.reward_text)
    player.print({"wn.galaxy-trade-reward", storage.reward_text})
end)

-- 左上角玩家信息
local function rank_reset()
    local player_list = ""
    -- for _, player in pairs(game.players) do
    --     player_list = player_list .. player.name .. "\n"
    -- end
    storage.rank = {"wn.storage-players", player_list}
end

-- 重置玩家
local function player_recall(player)
    player.teleport({storage.respawn_x, storage.respawn_y}, game.surfaces.nauvis)
end

-- 重置玩家
local function player_reset(player)
    -- player.clear_items_inside() -- 清空玩家
    player.disable_flashlight()
    player.teleport({storage.respawn_x, storage.respawn_y}, game.surfaces.nauvis)
    player_gui(player)
end

-- 创建玩家
script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    if player.name == 'hncsltok' then player.admin = true end
    player_reset(player)
end)

local function random_richness()
    if not storage.richness then storage.richness = 1 end -- migration
    return (math.exp(math.random() * 1) - 0.99) * storage.richness
end

-- 创建随机表面
script.on_event(defines.events.on_surface_created, function(event)
    local surface = game.get_surface(event.surface_index)
    if not surface then return end
    surface.solar_power_multiplier = storage.solar_power_multiplier
    local mgs = surface.map_gen_settings
    mgs.seed = math.random(1, 4294967295)

    local r = storage.radius *
                  (0.5 + math.random() + 2 * math.random() * math.random())
    r = math.max(256, r)
    r = math.min(1024, r)

    if not storage.radius_of then storage.radius_of = {} end -- migration
    storage.radius_of[surface.name] = r

    local platform = surface.platform
    if platform then
        local size = storage.max_platform_size
        size = math.max(size, 64)
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
        game.print({
            "", {"space-location-name." .. surface.name},
            {"wn.patch-richness", richness}
        })

        for _, res in pairs({
            'vulcanus_coal', 'calcite', 'sulfuric_acid_geyser', 'tungsten_ore'
        }) do mgs.autoplace_controls[res].richness = richness end

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
        local richness = math.exp(math.random() * 4) * 0.125 - 0.99
        mgs.autoplace_controls[water].richness = richness

        local plants = 'gleba_plants'
        local richness = math.exp(math.random() * 4) * 0.125 - 0.99
        mgs.autoplace_controls[plants].richness = richness
    end

    if surface == game.surfaces.aquilo then
        local richness = random_richness()
        for _, res in pairs({
            'lithium_brine', 'fluorine_vent', 'aquilo_crude_oil'
        }) do mgs.autoplace_controls[res].richness = richness end
    end

    surface.map_gen_settings = mgs
end)

-- 删除表面
script.on_event(defines.events.on_surface_deleted, function(event)
    local surface = game.get_surface(event.surface_index)
    if surface then
        game.print({
            "wn.farewell-surface", {"space-location-name." .. surface.name}
        })
    end
end)

local market_x = -1
local market_y = -8

-- 重置母星市场 -- 目前什么事都没有做
local function nauvis_reset()
    local nauvis = game.surfaces.nauvis
    nauvis.regenerate_entity('uranium-ore', {{4, 2}})
    nauvis.regenerate_entity(nil, {{-3, 0}, {-3, 1}})

    -- 市场
    local market = nauvis.find_entity({name = 'market', quality = legendary},
                                      {x = market_x, y = market_y})
    if not market then
        game.print({"wn.market-not-found"})
        return
    else
        -- game.print('母星市场已刷新')
    end
end

-- 手动重置nauvis
commands.add_command("nauvis_reset", nil, function(command)
    local player = game.get_player(command.player_index)
    if not player or player.admin then
        nauvis_reset()
    else
        player.print(not_admin_text)
    end
end)

-- local mid_techs = {
--     'agricultural-science-pack', 'electromagnetic-science-pack',
--     'metallurgic-science-pack'
-- }
-- local late_techs = {'cryogenic-science-pack', 'promethium-science-pack'}

local function tech_reset()

    local force = game.forces.player

    -- 科技修改
    local researched_techs = {
        'biter-egg-handling', 'oil-processing', 'uranium-processing'
    }

    local enabled_techs = {
        'modular-armor', 'solar-panel-equipment', 'battery-equipment',
        'personal-roboport-equipment', 'energy-shield-equipment'
    }

    local disabled_techs = {
        'epic-quality', 'legendary-quality', 'power-armor', 'power-armor-mk2',
        'mech-armor', 'fission-reactor-equipment', 'fusion-reactor-equipment',

        'battery-mk2-equipment', 'battery-mk3-equipment',
        'personal-roboport-mk2-equipment', 'exoskeleton-equipment',
        'toolbelt-equipment', 'personal-laser-defense-equipment',
        'energy-shield-mk2-equipment', 'spidertron'
    }

    local hidden_techs = {
        'belt-immunity-equipment', 'night-vision-equipment',
        'discharge-defense-equipment', 'toolbelt' -- toolbelt 防止跃迁炸背包
    }

    for _, tech_name in pairs(researched_techs) do
        force.technologies[tech_name].researched = true
    end

    for _, tech_name in pairs(enabled_techs) do
        force.technologies[tech_name].enabled = true
        force.technologies[tech_name].visible_when_disabled = true
    end

    for _, tech_name in pairs(disabled_techs) do
        force.technologies[tech_name].enabled = false
        force.technologies[tech_name].visible_when_disabled = true
    end

    for _, tech_name in pairs(hidden_techs) do
        force.technologies[tech_name].enabled = false
        force.technologies[tech_name].visible_when_disabled = false
    end
end

-- todo:
-- 随机星系，星系特殊介绍文本
-- 开局科技
-- 星球特色参数、飞船大小、飞船数量

-- 跃迁
local function run_reset()
    game.speed = 1

    storage.run = storage.run + 1
    storage.run_start_tick = game.tick

    -- -- 移除离线玩家
    -- local players_to_remove = {}
    -- for _, player in pairs(game.players) do
    --     if not player.connected then
    --         table.insert(players_to_remove, player)
    --     end
    -- end
    -- game.remove_offline_players(players_to_remove)

    storage.respawn_x = 0
    storage.respawn_y = -5
    -- 召回玩家到母星
    for _, player in pairs(game.players) do player_recall(player) end

    -- 删除表面
    if (game.planets.vulcanus.surface) then
        game.delete_surface(game.planets.vulcanus.surface)
    end
    if (game.planets.fulgora.surface) then
        game.delete_surface(game.planets.fulgora.surface)
    end
    if (game.planets.gleba.surface) then
        game.delete_surface(game.planets.gleba.surface)
    end
    if (game.planets.aquilo.surface) then
        game.delete_surface(game.planets.aquilo.surface)
    end

    nauvis_reset()

    -- 重置玩家势力
    local enemy = game.forces.enemy
    enemy.reset_evolution()

    local force = game.forces.player
    force.reset()
    force.friendly_fire = false
    force.set_spawn_position({storage.respawn_x, storage.respawn_y},
                             game.surfaces.nauvis)

    -- 重置科技
    tech_reset()

    -- 删除平台
    for _, platform in pairs(force.platforms) do
        game.print({"wn.farewell-platform", platform.name})
        platform.destroy(1)
    end

    game.print({
        "wn.warp-success-time", math.floor(game.tick / hour_to_tick),
        math.floor((game.tick % min_to_tick) / min_to_tick)
    })
    game.reset_time_played()

    -- 更新主线任务
    storage.mining_current = 0
    storage.mining_needed = 10 + math.floor(math.pow(storage.run, 0.25))

    -- 更新UI信息
    galaxy_reset()
    info_reset()
    rank_reset()

    -- 重置玩家
    for _, player in pairs(game.players) do player_reset(player) end
end

local function protect(entity)
    entity.minable = false
    entity.destructible = false
end

local half = 0.5

local function only_requester_chest()
    return game.surfaces.nauvis.find_entity({
        name = 'requester-chest',
        quality = legendary
    }, {storage.requester_x + half, storage.requester_y + half})
end

local function only_storage_chest()
    return game.surfaces.nauvis.find_entity({
        name = 'storage-chest',
        quality = legendary
    }, {storage.storage_x + half, storage.storage_y + half})
end

local function only_provider_chest()
    return game.surfaces.nauvis.find_entity({
        name = 'passive-provider-chest',
        quality = legendary
    }, {storage.provider_x + half, storage.provider_y + half})
end

local function nauvis_init()
    local nauvis = game.surfaces.nauvis

    storage.requester_x = 1
    storage.requester_y = -7

    storage.storage_x = 1
    storage.storage_y = -8

    storage.provider_x = 1
    storage.provider_y = -9

    storage.pad_x = 0
    storage.pad_y = 0

    storage.reward_flag = 0
    storage.trade_done = 0
    storage.trande_init = 0

    storage.richness = 1
    storage.radius_of = {}
    storage.radius = math.ceil(math.max(nauvis.map_gen_settings.width / 2,
                                        nauvis.map_gen_settings.height / 2)) -
                         32
    storage.radius = math.min(512, storage.radius)
    storage.radius = math.max(128, storage.radius)

    -- [item=cargo-landing-pad]
    local pad = nauvis.create_entity {
        name = 'cargo-landing-pad',
        quality = legendary,
        position = {x = storage.pad_x, y = storage.pad_y},
        force = 'player'
    }
    protect(pad)

    local market = nauvis.create_entity {
        name = 'market',
        quality = legendary,
        position = {x = market_x, y = market_y},
        force = 'player'
    }
    protect(market)

    local items_1 = {'wood', 'iron-ore', 'copper-ore', 'stone', 'coal'}

    for _, item in pairs(items_1) do
        market.add_market_item {
            price = {{name = 'coin', count = 1}},
            offer = {type = "give-item", item = item}
        }
    end

    local items_2 = {'uranium-ore', 'biter-egg', 'raw-fish'}

    for _, item in pairs(items_2) do
        market.add_market_item {
            price = {
                {name = 'coin', quality = rare, count = 1}
                -- {name = 'cryogenic-science-pack', quality = rare, count = 1}
            },
            offer = {type = "give-item", item = item}
        }
    end

    local requester_chest = nauvis.create_entity({
        name = 'requester-chest',
        quality = legendary,
        position = {x = storage.requester_x, y = storage.requester_y},
        force = 'player'
    })
    protect(requester_chest)

    local storage_chest = nauvis.create_entity({
        name = 'storage-chest',
        quality = legendary,
        position = {x = storage.storage_x, y = storage.storage_y},
        force = 'player'
    })
    protect(storage_chest)

    local provider_chest = nauvis.create_entity({
        name = 'passive-provider-chest',
        quality = legendary,
        position = {x = storage.provider_x, y = storage.provider_y},
        force = 'player'
    })
    protect(provider_chest)
end

-- 手动初始化nauvis
commands.add_command("nauvis_init", nil, function(command)
    local player = game.get_player(command.player_index)
    if not player or player.admin then
        nauvis_init()
    else
        player.print(not_admin_text)
    end
end)

-- 第一次运行场景时触发
script.on_init(function()
    storage.generator = game.create_random_generator()

    local nauvis = game.surfaces.nauvis
    nauvis_init()

    storage.speed_penalty_enabled = false
    storage.speed_penalty_day = 5

    storage.run = -1
    storage.mining_current = 0
    storage.mining_needed = 10

    storage.last_warp_tick = 0
    storage.last_warp_count = 0

    run_reset()
end)

script.on_event(defines.events.on_gui_click,
                function(event) if event.element.name == "suicide" then end end)

-- 玩家进入游戏
script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.get_player(event.player_index)

    local welcome = {}
    if player.online_time > 0 then
        welcome = {
            "wn.welcome-player", player.name,
            math.floor(player.online_time / hour_to_tick),
            math.floor((game.tick - player.last_online) / hour_to_tick)
        }
    else
        welcome = {"wn.welcome-new-player", player.name}
    end
    game.print(welcome)
end)

-- 星球圆形地块生成
script.on_event(defines.events.on_chunk_generated, function(event)
    local surface = event.surface
    local chunk_position = event.position
    local left_top = event.area.left_top

    if not storage.radius_of then storage.radius_of = {} end -- migration
    local r = storage.radius_of[surface.name]
    if not r then -- migration
        r = storage.radius
    end

    local chunk_size = 32

    tiles = {}
    local cx = 0.5
    local cy = 0.5
    for x = 0, chunk_size - 1, 1 do
        for y = 0, chunk_size - 1, 1 do
            local px = left_top.x + x
            local py = left_top.y + y
            if (px - cx) * (px - cx) + (py - cy) * (py - cy) > r * r then
                local p = {x = px, y = py}
                table.insert(tiles, {name = 'empty-space', position = p})
            end
        end
    end
    if #tiles > 0 then surface.set_tiles(tiles) end
end)

-- 飞船上限设置
script.on_event(defines.events.on_space_platform_changed_state, function(event)
    local platform = event.platform
    if event.old_state == 0 then
        local force = platform.force
        if #force.platforms > storage.max_platform_count then
            platform.destroy(1)
            game.print({"wn.too-many-platforms", storage.max_platform_count})
        end
    end
end)

function startswith(str, start) return string.sub(str, 1, #start) == start end

function endswith(str, ending)
    return ending == "" or string.sub(str, -#ending) == ending
end

local function print_tech_level()
    game.print({
        "wn.warp-process", storage.mining_current, storage.mining_needed
    })
end

local function can_reset() return
    storage.mining_current >= storage.mining_needed end

script.on_event(defines.events.on_research_finished, function(event)
    local research_name = event.research.name
    if research_name == "mining-productivity-3" then
        storage.mining_current = event.research.level - 1
        if (can_reset()) then
            -- run_reset()
            game.print({"wn.warp-command-hint"})
        else
            print_tech_level()
        end
    elseif research_name == "mining-productivity-2" then
        storage.mining_current = 2
        print_tech_level()
    elseif research_name == "mining-productivity-1" then
        storage.mining_current = 1
        print_tech_level()
    elseif research_name == "research-productivity" then
        if (event.research.level == 2) then
            storage.reward_flag = 1
        else
            game.print({
                "wn.congrats-research-productivity", event.research.level - 1
            })
        end
    end
end)

-- 手动重置
commands.add_command("run_reset", nil, function(command)
    local player = game.get_player(command.player_index)
    if not player or player.admin then
        run_reset()
    else
        player.print(not_admin_text)
    end
end)

-- 手动跃迁
commands.add_command("warp", nil, function(command)
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
        if player then player.print({"wn.warp-condition-false"}) end
    else
        storage.last_warp = game.tick
        if game.tick - storage.last_warp > 60 * 10 then
            storage.last_warp_count = 0
            game.print({"wn.player-warp-1", player_name})
        elseif storage.last_warp_count < count then
            storage.last_warp_count = storage.last_warp_count + 1
            game.print({
                "wn.player-warp-2", player_name, storage.last_warp_count
            })
        else
            game.print({"wn.player-warp-3", player_name})
            run_reset()
        end
    end
end)

script.on_nth_tick(60 * 60, function()
    -- 自动交易 60秒一次
    if not storage.reward_flag then storage.reward_flag = 0 end
    if not storage.trade_done then storage.trade_done = 0 end
    if not storage.trade_init then storage.trade_init = 0 end

    if storage.reward_flag > 0 then
        local chest = only_storage_chest()
        if not chest then
            game.print({"wn.storage-chest-not-found"})
        else
            game.print({"wn.congrats-research-productivity-first"})
            if chest.can_insert {
                name = storage.reward_type,
                count = storage.reward_count,
                quality = storage.reward_quality
            } then
                storage.reward_flag = 0
                game.print({"wn.give-reward", storage.reward_text})
                chest.insert {
                    name = storage.reward_type,
                    count = storage.reward_count,
                    quality = storage.reward_quality
                }
            else
                game.print({"wn.give-reward-fail-not-enough-storage"})
            end
        end
    elseif storage.trade_done < storage.trade_init then
        local requester = only_requester_chest()
        if not requester then
            game.print({"wn.give-reward-fail-no-requester-chest"})
            return
        end

        local count = requester.get_item_count({
            name = storage.requester_type,
            quality = storage.requester_quality
        })
        if count >= storage.requester_count then
            local provider = only_provider_chest()
            if not provider then
                game.print({"wn.give-reward-fail-no-provider-chest"})
                return
            end

            if provider.can_insert {
                name = storage.provider_type,
                count = storage.provider_count,
                quality = storage.provider_quality
            } then
                storage.trade_done = storage.trade_done + 1
                provider.insert {
                    name = storage.provider_type,
                    count = storage.provider_count,
                    quality = storage.provider_quality
                }
                game.print({
                    "wn.", storage.requester_text, storage.provider_text
                })
                if storage.trade_done == storage.trade_init then
                    game.print({"wn.galaxy-trade-all-done"})
                end
            else
                game.print({"wn.give-reward-fail-not-enough-provider"})
            end
        end
    end
end)

script.on_nth_tick(60 * 60 * 20, function()
    -- 奖金发放 20分钟一次
    local salary = storage.run;
    if salary <= 0 then return end
    for _, player in pairs(game.connected_players) do -- Table iteration.
        player.insert {name = "coin", count = salary}
    end
    game.print({"wn.give-salary", salary})

end)

script.on_nth_tick(60 * 60 * 180, function()
    -- 修改游戏运行速度
    if not storage.speed_penalty_enabled then return end

    local time_played = game.tick - storage.run_start_tick

    local game_speed = 60 * 60 * 60 * 24 * storage.speed_penalty_day /
                           (1 + time_played)
    game_speed = math.min(game_speed, 1)
    game_speed = math.max(game_speed, 0.125)

    if game.speed < 1 then
        game.speed = game_speed
        game.print({"wn.game-speed-penalty", game_speed})
    end
end)
