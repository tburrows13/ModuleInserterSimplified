local function request_translations(player)
  local selection_tools = game.get_filtered_item_prototypes({{filter = "type", type = "selection-tool"}})
  for name, selection_tool in pairs(selection_tools) do
    if name:sub(1, 11) == "mis-insert-" and name:sub(12, 20) ~= "ee-super-" then
      player.request_translation({"", "mis", name, "|", selection_tool.localised_name})
    end
  end
  player.request_translation({"selection-tool.mis-insert-empty"})
end

script.on_event(defines.events.on_string_translated,
  function(event)
    if not event.translated then return end
    local player_index = event.player_index
    local translations = global.translations
    translations[player_index] = translations[player_index] or {}

    local input = event.localised_string
    if input[2] ~= "mis" then return end
    local output = event.result
    local divider_location = output:find("|")
    local localised_name = output:sub(divider_location + 1)
    translations[player_index][input[3]] = localised_name
  end
)

local function generate_global_data()
  local modules = game.get_filtered_item_prototypes({{filter = "type", type = "module"}})
  local entities = game.get_filtered_entity_prototypes({{filter = "type", type = {"mining-drill", "furnace", "assembling-machine", "lab", "beacon", "rocket-silo"}}})
  local module_tiers = {}
  local allowed_with_recipe = {}
  local allowed_in_entity = {}
  for name, module in pairs(modules) do
    if not module.has_flag("hidden") and name:sub(1, 9) ~= "ee-super-" then
      local module_type = name
      local module_tier = 1 -- module.tier
      local i, j = name:find("%-%d+$")  -- Finds "-5" at the end of the string
      if i then
        module_type = name:sub(1, i-1)
        module_tier = tonumber(name:sub(i+1)) or 1  -- Don't use module.tier because Nullius starts at 0
      end
      local tier_list = module_tiers[module_type]
      if tier_list then
        tier_list[module_tier] = name
      else
        module_tiers[module_type] = {[module_tier] = name}
      end
    end

    -- Compute recipe limitations
    local limitations = module.limitations
    if limitations and next(limitations) then
      local module_allowed_with_recipe = {}
      for _, recipe in pairs(limitations) do
        module_allowed_with_recipe[recipe] = true
      end
      module_allowed_with_recipe.limitation_message_key = {"item-limitation." .. module.limitation_message_key}
      allowed_with_recipe[name] = module_allowed_with_recipe
    end

    -- Compute entity limitations
    local module_effects = module.module_effects
    local module_allowed_in_entity = {}
    for _, entity in pairs(entities) do
      local entity_allowed = true
      local allowed_effects = entity.allowed_effects
      if allowed_effects then
        for effect, _ in pairs(module_effects) do
          if not allowed_effects[effect] then
            entity_allowed = false
            break
          end
        end
      else
        entity_allowed = false
      end
      if entity_allowed then
        module_allowed_in_entity[entity.name] = true
      end
    end
    module_allowed_in_entity.limitation_message_key = {"inventory-restriction.cant-insert-module", module.localised_name}
    allowed_in_entity[name] = module_allowed_in_entity
  end


  local tier = 1
  local module_list = {}
  local in_module_list = {}
  local se_installed = game.active_mods["space-exploration"]
  while true do
    local added = false
    for _, tier_module_list in pairs(module_tiers) do
      local name = tier_module_list[tier]
      if name then
        added = true
        table.insert(module_list, name)
        in_module_list[name] = true
      end
    end
    if not added then break end
    if se_installed and tier == 3 then table.insert(module_list, "empty-2") end
    if se_installed and tier == 6 then table.insert(module_list, "empty-3") end
    tier = tier + 1
  end

  table.insert(module_list, "empty")  -- Fake module to represent removing modules

  log(serpent.block(module_list))

  global.module_list = module_list
  global.in_module_list = in_module_list
  global.allowed_with_recipe = allowed_with_recipe
  global.allowed_in_entity = allowed_in_entity

  global.players_shift_scroll_warning = global.players_shift_scroll_warning or {}

  global.translations = {}
  for _, player in pairs(game.is_multiplayer() and game.connected_players or game.players) do
    request_translations(player)
  end
end

script.on_init(
  function()
    generate_global_data()
    global.players_last_module = {}
  end
)
script.on_configuration_changed(generate_global_data)
script.on_event(defines.events.on_game_created_from_scenario, generate_global_data)

script.on_event(defines.events.on_player_joined_game,
  function(event)
    local player = game.get_player(event.player_index)
    request_translations(player)
  end
)