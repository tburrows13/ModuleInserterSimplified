local util = require "util"

local InitStorage = {}

local function request_translations(player)
  local selection_tools = prototypes.get_item_filtered({{filter = "type", type = "selection-tool"}})
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
  storage.translation_requests[player.index] = translation_requests
end

local function on_string_translated(event)
  if not event.translated then return end
  local player_index = event.player_index
  local translation_requests = storage.translation_requests[player_index]
  if not translation_requests or not translation_requests[event.id] then return end
  local name = translation_requests[event.id]

  local translations = storage.translations
  translations[player_index] = translations[player_index] or {}
  translations[player_index][name] = event.result
end

local function generate_player_data(player, old_player_data)
  if not old_player_data then old_player_data = {} end
  local modules_enabled = old_player_data.modules_enabled or {}
  local old_modules_enabled = util.copy(modules_enabled)
  for name, module in pairs(storage.modules_by_name) do
    if modules_enabled[name] == nil then
      -- Apply default enabled state
      if module.tier == 1 or module.type == "empty" then
        modules_enabled[name] = true
      else
        modules_enabled[name] = false
      end
    end
  end

  storage.player_data[player.index] = {
    elems = old_player_data.elems,
    modules_enabled = modules_enabled,
    gui_position = nil  -- player resolution can't be read in `on_player_created`, so set when needed the first time
  }

  for _, technology in pairs(player.force.technologies) do
    if technology.researched then
      Config.process_technology(technology, player.index, old_modules_enabled)
    end
  end
end

local function generate_global_data()
  local modules = prototypes.get_item_filtered({{filter = "type", type = "module"}, {filter = "hidden", mode = "and", invert = true}})
  local selection_tools = prototypes.get_item_filtered({{filter = "type", type = "selection-tool"}})

  -- Type module: {name, type, tier, enabled, localised_name, index} (name = type + tier)
  storage.modules = {}  -- array(<module>)
  storage.modules_by_tier = {}  -- dict(tier -> array(<module>))
  storage.modules_by_name = {}  -- dict(name -> <module>)


  -- Initial pass, generate storage.modules_by_tier
  for name, module in pairs(modules) do
    if not selection_tools["mis-insert-" .. name] then goto continue end
    local module_type = name
    local module_tier = 1 -- module.tier
    local i, j = name:find("%-%d+$")  -- Finds "-5" at the end of the string
    if i then
      module_type = name:sub(1, i-1)
      module_tier = module.tier
      if script.active_mods["nullius"] then
        module_tier = tonumber(name:sub(i+1)) or 1  -- Don't use module.tier because Nullius starts at 0
      end
    end
    if name:sub(1, 9) == "ee-super-" then
      module_tier = -1
    end
    local tier_list = storage.modules_by_tier[module_tier] or {}
    table.insert(tier_list, {name = name, type = module_type, tier = module_tier, localised_name = module.localised_name})
    storage.modules_by_tier[module_tier] = tier_list

    ::continue::
  end

  if storage.modules_by_tier[0] then
    -- Move cheat modules from tier 0 to tier n+1
    local number_of_tiers = #storage.modules_by_tier
    storage.modules_by_tier[number_of_tiers + 1] = storage.modules_by_tier[0]
    storage.modules_by_tier[0] = nil
  end

  -- Add remove-modules to tier -1
  storage.modules_by_tier[-2] = {{name = "remove-modules", type = "empty", tier = -2, localised_name = {"item-name.remove-modules"}}}

  -- Flatten storage.modules_by_tier into storage.modules
  for _, tier_list in pairs(storage.modules_by_tier) do
    for _, module in pairs(tier_list) do
      table.insert(storage.modules, module)
    end
  end

  -- Generate lookup dict to get module index from name
  for i, module in pairs(storage.modules) do
    module.index = i
    storage.modules_by_name[module.name] = module
  end

  storage.player_data = storage.player_data or {}
  for _, player in pairs(game.players) do
    generate_player_data(player, storage.player_data[player.index])
  end

  --log(serpent.block(storage.modules))
  --log(serpent.block(storage.modules_by_name))
  --log(serpent.block(storage.modules_by_tier))

  storage.players_shift_scroll_warning = storage.players_shift_scroll_warning or {}
  storage.proxy_targets = storage.proxy_targets or {}

  storage.translations = {}
  storage.translation_requests = {}
  for _, player in pairs(game.connected_players) do
    request_translations(player)
  end
end

InitStorage.on_init =  function()
  generate_global_data()
  storage.players_last_module = {}
  storage.proxy_targets = {}
end

InitStorage.on_configuration_changed = generate_global_data

local function on_player_joined_game(event)
  local player = game.get_player(event.player_index)
  request_translations(player)
end

local function on_player_created(event)
  local player = game.get_player(event.player_index)
  generate_player_data(player)
end

local function on_player_display_resolution_changed(event)
  local player = game.get_player(event.player_index)
  local player_data = storage.player_data[player.index]
  ModuleGui.destroy_legacy(player)
  ModuleGui.destroy(player, player_data)
  player_data.gui_position = nil
end

InitStorage.events = {
  [defines.events.on_string_translated] = on_string_translated,
  [defines.events.on_game_created_from_scenario] = generate_global_data,
  [defines.events.on_player_joined_game] = on_player_joined_game,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_player_display_resolution_changed] = on_player_display_resolution_changed,
}

return InitStorage