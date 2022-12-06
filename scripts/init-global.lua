local function request_translations(player)
  local selection_tools = game.get_filtered_item_prototypes({{filter = "type", type = "selection-tool"}})
  local translations = {}
  local translation_names = {}
  for name, selection_tool in pairs(selection_tools) do
    if name:sub(1, 11) == "mis-insert-" then
      table.insert(translation_names, name)
      table.insert(translations, selection_tool.localised_name)
    end
  end
  local request_ids = player.request_translations(translations)

  local translation_requests = {}
  for i, request_id in pairs(request_ids) do
    translation_requests[request_id] = translation_names[i]
  end
  global.translation_requests[player.index] = translation_requests
end

script.on_event(defines.events.on_string_translated,
  function(event)
    if not event.translated then return end
    local player_index = event.player_index
    local translation_requests = global.translation_requests[player_index]
    if not translation_requests or not translation_requests[event.id] then return end
    local name = translation_requests[event.id]

    local translations = global.translations
    translations[player_index] = translations[player_index] or {}
    translations[player_index][name] = event.result
  end
)

local function generate_allowed_with_recipe(module)
  -- Compute recipe limitations
  local limitations = module.limitations
  if limitations and next(limitations) then
    local module_allowed_with_recipe = {}
    for _, recipe in pairs(limitations) do
      module_allowed_with_recipe[recipe] = true
    end
    module_allowed_with_recipe.limitation_message_key = {"item-limitation." .. module.limitation_message_key}
    return module_allowed_with_recipe
  end
end

local function generate_allowed_in_entity(module, entities)
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
  return module_allowed_in_entity
end

local function generate_global_data()
  local modules = game.get_filtered_item_prototypes({{filter = "type", type = "module"}, {filter = "flag", flag = "hidden", mode = "and", invert = true}})
  local selection_tools = game.get_filtered_item_prototypes({{filter = "type", type = "selection-tool"}})
  local entities = game.get_filtered_entity_prototypes({{filter = "type", type = {"mining-drill", "furnace", "assembling-machine", "lab", "beacon", "rocket-silo"}}})

  global.allowed_with_recipe = {}  -- dict(module_name -> dict(recipe_name -> bool)))
  global.allowed_in_entity = {}  -- dict(module_name -> dict(entity_name -> bool)))

  -- Type module: {name, type, tier, enabled, localised_name, index} (name = type + tier)
  global.modules = {}  -- array(<module>)
  global.modules_by_tier = {}  -- dict(tier -> array(<module>))
  global.modules_by_name = {}  -- dict(name -> <module>)


  -- Initial pass, generate global.modules_by_tier
  for name, module in pairs(modules) do
    if not selection_tools["mis-insert-" .. name] then goto continue end
    local module_type = name
    local module_tier = 1 -- module.tier
    local i, j = name:find("%-%d+$")  -- Finds "-5" at the end of the string
    if i then
      module_type = name:sub(1, i-1)
      module_tier = tonumber(name:sub(i+1)) or 1  -- Don't use module.tier because Nullius starts at 0
    end
    local tier_list = global.modules_by_tier[module_tier] or {}
    table.insert(tier_list, {name = name, type = module_type, tier = module_tier, enabled = true, localised_name = module.localised_name})
    global.modules_by_tier[module_tier] = tier_list

    -- Compute limitations for each module
    global.allowed_with_recipe[name] = generate_allowed_with_recipe(module)
    global.allowed_in_entity[name] = generate_allowed_in_entity(module, entities)
    ::continue::
  end

  -- Add mis-empty to each tier
  for tier, tier_list in pairs(global.modules_by_tier) do
    table.insert(tier_list, {name = "empty-" .. tier, type = "empty", tier = tier, enabled = true, localised_name = {"item-name.mis-insert-empty"}})
  end

  -- Flatten global.modules_by_tier into global.modules
  for _, tier_list in pairs(global.modules_by_tier) do
    for _, module in pairs(tier_list) do
      table.insert(global.modules, module)
    end
  end

  -- Generate lookup dict to get module index from name
  for i, module in pairs(global.modules) do
    module.index = i
    global.modules_by_name[module.name] = module
  end

  log(serpent.block(global.modules))
  log(serpent.block(global.modules_by_name))

  global.players_shift_scroll_warning = global.players_shift_scroll_warning or {}
  global.player_data = global.player_data or {}
  global.proxy_targets = global.proxy_targets or {}

  global.translations = {}
  global.translation_requests = {}
  for _, player in pairs(game.is_multiplayer() and game.connected_players or game.players) do
    request_translations(player)
  end
end

script.on_init(
  function()
    generate_global_data()
    global.players_last_module = {}
    global.proxy_targets = {}
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