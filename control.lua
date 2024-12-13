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
local not_admin_text = '权限不足'

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
-- 左上角游戏教程信息
local function info_reset()
    storage.info = "\n" .. "[img=item/thruster]已经完成 " .. storage.run ..
                       " 次跃迁\n\n" ..
                       "[img=technology/mining-productivity-3]研究采矿产能 " ..
                       storage.mining_needed ..
                       " 级，跃迁至下一个星系！\n\n\n" ..
                       "[img=item/space-platform-starter-pack]太空平台最大数量 " ..
                       storage.max_platform_count .. "\n\n" ..
                       "[img=space-location/solar-system-edge]外星系随机词条开发中...\n\n" ..
                       "[img=space-location/nauvis]跃迁时，母星和玩家背包会保留\n\n" ..
                       "[img=item/lab]跃迁时，科技会重置\n\n" ..
                       "[img=item/space-platform-foundation]跃迁时，太空平台无法带走\n\n" ..
                       "[img=item/production-science-pack]跃迁前，记得掠夺外星，在母星屯满各种货物\n\n" ..
                       "[img=item/requester-chest][img=item/passive-provider-chest]跃迁后，星系市场会刷新[img=quality/epic][img=quality/legendary]货物订单\n\n" ..
                       "[img=item/storage-chest]跃迁后，星系市场会刷新奖励，需要[img=technology/research-productivity]\n\n" ..
                       "[img=item/coin]跃迁次数越多，定期发放金币越多\n\n" ..
                       "[img=entity/big-wriggler-pentapod]BUG反馈 Q群 293280221\n\n"
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
    storage.reward_count = 1000
    storage.reward_type = 'coin'
    storage.reward_quality = epic
    storage.reward_text = '[item=' .. storage.reward_type .. ',quality=' ..
                              storage.reward_quality .. '] x ' ..
                              storage.reward_count

    storage.galaxy =
        "\n通过母星中心的[img=item/requester-chest][img=item/passive-provider-chest]\n" ..
            "每分钟自动进行此星系专属的特殊交易\n\n" ..
            "星系收购 " .. storage.requester_text .. "\n" .. "星系生产 " ..
            storage.provider_text .. "\n" ..
            "\n研究[img=technology/research-productivity]之后\n在[img=item/storage-chest]领取星系奖励\n" ..
            "\n星系奖励 " .. storage.reward_text .. "\n" ..
            "\n\n输入指令 /trade 查看更多信息 \n\n"
end

-- 查看交易信息
commands.add_command("trade", nil, function(command)
    local player = game.get_player(command.player_index)
    if not player then return end
    player.print('最大交易次数 ' .. storage.trade_init)
    player.print('完成交易次数 ' .. storage.trade_done)
    player.print('\n星系[item=requester-chest]收购\n' ..
                     storage.requester_text)
    player.print('\n星系[item=passive-provider-chest]生产\n' ..
                     storage.provider_text)
    player.print('\n星系[item=storage-chest]奖励\n' .. storage.reward_text)
end)

-- 左上角玩家信息
local function rank_reset()
    local player_list = ""
    for _, player in pairs(game.players) do
        player_list = player_list .. player.name .. "\n"
    end
    storage.rank =
        "更多功能制作中...\n\n[img=virtual-signal/signal-heart]玩家列表\n\n" ..
            player_list
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

-- 创建随机表面
script.on_event(defines.events.on_surface_created, function(event)
    local function surface_reset(surface)
        local mgs = surface.map_gen_settings
        mgs.seed = math.random(1, 4294967295)
        mgs.width = storage.radius * 2 + 32
        mgs.height = storage.radius * 2 + 32
        surface.map_gen_settings = mgs;
    end
    local surface = game.get_surface(event.surface_index)
    if surface then surface_reset(surface) end
end)

-- 删除表面
script.on_event(defines.events.on_surface_deleted, function(event)
    local surface = game.get_surface(event.surface_index)
    if surface then game.print({"", "永别了，" , "space-location-name.".. surface.name}) end
end)

local market_x = -1
local market_y = -8

-- 重置母星市场 -- 目前什么事都没有做
local function nauvis_reset()
    local nauvis = game.surfaces.nauvis
    -- 市场
    local market = nauvis.find_entity({name = 'market', quality = normal},
                                      {x = market_x, y = market_y})
    if not market then
        game.print('奇怪，找不到母星市场')
        return
    else
        game.print('母星市场已刷新')
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

local function tech_reset()
    -- 科技修改
    local researched_techs = {
        'biter-egg-handling', 'basic-oil-processing', 'uranium-processing'
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

    local force = game.forces.player

    for _, tech_name in pairs(enabled_techs) do
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

-- 跃迁
local function run_reset()
    storage.mining_current = 0
    storage.run = storage.run + 1
    storage.mining_needed = 10 + math.floor(math.pow(storage.run, 0.25))

    -- 移除离线玩家
    local players_to_remove = {}
    for _, player in pairs(game.players) do
        if not player.connected then
            table.insert(players_to_remove, player)
        end
    end
    game.remove_offline_players(players_to_remove)

    storage.respawn_x = 0
    storage.respawn_y = -5

    -- 更新UI信息
    info_reset()
    galaxy_reset()
    rank_reset()
    -- 重置玩家
    for _, player in pairs(game.players) do player_reset(player) end

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

    -- 重置玩家势力
    local enemy = game.forces.enemy
    enemy.reset_evolution()

    local force = game.forces.player
    force.reset()
    force.friendly_fire = false
    force.set_spawn_position({storage.respawn_x, storage.respawn_y}, game.surfaces.nauvis)

    -- 重置科技
    tech_reset()

    -- 删除平台
    for _, platform in pairs(force.platforms) do
        game.print("永别了，太空平台 " .. platform.name)
        platform.destroy(1)
    end

    game.print(
        "跃迁成功！用时" .. math.floor(game.tick / hour_to_tick) ..
            "小时" .. math.floor((game.tick % min_to_tick) / min_to_tick) ..
            "分钟")
    game.reset_time_played()

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

    -- [item=cargo-landing-pad]
    local pad = nauvis.create_entity {
        name = 'cargo-landing-pad',
        quality = legendary,
        position = {x = storage.pad_x, y = storage.pad_y},
        force = 'player'
    }
    protect(pad, true)

    local market = nauvis.create_entity {
        name = 'market',
        quality = legendary,
        position = {x = market_x, y = market_y},
        force = 'player'
    }
    protect(market, true)

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
    protect(requester_chest, true)

    local storage_chest = nauvis.create_entity({
        name = 'storage-chest',
        quality = legendary,
        position = {x = storage.storage_x, y = storage.storage_y},
        force = 'player'
    })
    protect(storage_chest, true)

    local provider_chest = nauvis.create_entity({
        name = 'passive-provider-chest',
        quality = legendary,
        position = {x = storage.provider_x, y = storage.provider_y},
        force = 'player'
    })
    protect(provider_chest, true)
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

    storage.max_platform_count = 3
    storage.run = -1
    storage.mining_current = 0
    storage.mining_needed = 10



    storage.radius = math.ceil(math.max(nauvis.map_gen_settings.width / 2,
                                        nauvis.map_gen_settings.height / 2)) -
                         64
    storage.radius = math.min(2048, storage.radius)
    storage.radius = math.max(256, storage.radius)

    run_reset()
end)

script.on_event(defines.events.on_gui_click,
                function(event) if event.element.name == "suicide" then end end)

-- 玩家进入游戏
script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.get_player(event.player_index)

    local welcome = ""
    if player.online_time > 0 then
        welcome = "欢迎 " .. player.name .. " 回到游戏！\n" ..
                      "在线时长 " ..
                      math.floor(player.online_time / hour_to_tick) ..
                      " 小时\n" .. "距离上次登录 " ..
                      math.floor((game.tick - player.last_online) / hour_to_tick) ..
                      " 小时\n"
    else
        local welcome = "欢迎 " .. player.name .. " 加入游戏！\n"
    end
    game.print(welcome)
end)

-- 星球圆形地块生成
script.on_event(defines.events.on_chunk_generated, function(event)
    local surface = event.surface
    local chunk_position = event.position
    local left_top = event.area.left_top

    local r = storage.radius
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
            game.print("最多拥有" .. storage.max_platform_count ..
                           "个飞船！")
        end
    end
end)

function startswith(str, start) return string.sub(str, 1, #start) == start end
function endswith(str, ending)
    return ending == "" or string.sub(str, -#ending) == ending
end

local function print_tech_level()
    game.print("跃迁进度 " .. storage.mining_current .. "/" ..
                   storage.mining_needed .. " ！")
end

local function can_reset() return
    storage.mining_current >= storage.mining_needed end

script.on_event(defines.events.on_research_finished, function(event)
    local research_name = event.research.name
    if research_name == "mining-productivity-3" then
        storage.mining_current = event.research.level - 1
        if (can_reset()) then
            -- run_reset()
            game.print(
                '已经满足跃迁条件！输入指令 /warp 进行手动跃迁')
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
            game.print(
                '恭喜再次完成 [technology=research-productivity] 等级 ' ..
                    (event.research.level - 1))
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
    local player = game.get_player(command.player_index)
    local player_name = not player and 'server' or player.name
    if can_reset() then
        game.print(player_name .. ' 启动跃迁程序！')
        run_reset()
    else
        if player then player.print('未满足跃迁条件') end
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
            game.print('找不到黄箱？')
        else
            game.print('恭喜完成 [technology=research-productivity]')
            if chest.can_insert {
                name = storage.reward_type,
                count = storage.reward_count,
                quality = storage.reward_quality
            } then
                storage.reward_flag = 0
                game.print(
                    '母星[item=storage-chest,quality=legendary]发放奖励' ..
                        storage.reward_text .. ' 欢迎领取')
                chest.insert {
                    name = storage.reward_type,
                    count = storage.reward_count,
                    quality = storage.reward_quality
                }
            else
                game.print(
                    '[virtual-signal=signal-deny]母星[item=storage-chest,quality=legendary]空间不足，奖励发放失败')
            end
        end

    elseif storage.trade_done < storage.trade_init then

        local requester = only_requester_chest()
        if not requester then
            game.print(
                '[virtual-signal=signal-deny]找不到[item=requester-chest,quality=legendary]？')
            return
        end

        local count = requester.get_item_count({
            name = storage.requester_type,
            quality = storage.requester_quality
        })
        if count >= storage.requester_count then

            local provider = only_provider_chest()
            if not provider then
                game.print(
                    '[virtual-signal=signal-deny]找不到[item=passive-provider-chest,quality=legendary]？')
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
                game.print('交易完成！' .. storage.requester_text ..
                               ' 成功换取 ' .. storage.provider_text)
                if storage.trade_done == storage.trade_init then
                    game.print('[space-age]星系交易全部完成！')
                end
            else
                game.print(
                    '[virtual-signal=signal-deny]母星[item=passive-provider-chest,quality=legendary]空间不足，奖励发放失败')
            end
        end
    end
end)

script.on_nth_tick(60 * 60 * 10, function()

    -- 奖金发放 10分钟一次
    local salary = storage.run;
    if salary <= 0 then return end
    for _, player in pairs(game.connected_players) do -- Table iteration.
        player.insert {name = "coin", count = salary}
    end
    game.print('发放奖金 ' .. salary .. ' 个[item=coin].')

end)
