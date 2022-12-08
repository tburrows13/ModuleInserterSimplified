Config = {}

function Config.handle_empties(player_index)
  local player_data = global.player_data[player_index]
  local modules_enabled = player_data.modules_enabled
  local empty_every = player_data.tiers_between_empty  -- TODO: get value from config
  local tiers_since_last_empty = 1
  local some_empty_enabled = false
  for tier, tier_list in pairs(global.modules_by_tier) do
    local some_enabled = false
    for _, module in pairs(tier_list) do
      if module.type == "empty" then
        -- We have reached the end of the list of modules of this tier
        if some_enabled and tiers_since_last_empty >= empty_every then
          -- At least one module of this tier is enabled, so we can enable the empty module
          modules_enabled[module.name] = true
          some_empty_enabled = true
          tiers_since_last_empty = 1
        else
          -- All modules of this tier are disabled, so we can disable the empty module
          modules_enabled[module.name] = false
          tiers_since_last_empty = tiers_since_last_empty + 1
        end
      end
      if modules_enabled[module.name] then
        some_enabled = true
      end
    end
  end
  if not some_empty_enabled then
    -- Enable the last one if there aren't any others
    modules_enabled[global.modules[#global.modules].name] = true
  end
end

function Config.process_technology(technology, player_index)
  local player_data = global.player_data[player_index]
  local modules_enabled = player_data.modules_enabled
  local changes_made = false

  for _, effect in pairs(technology.effects) do
    if effect.type == "unlock-recipe" then
      local recipe = game.recipe_prototypes[effect.recipe]
      if recipe then
        for _, product in pairs(recipe.products) do
          if product.type == "item" then
            local module_name = product.name
            local unlocked_module = global.modules_by_name[module_name]
            if unlocked_module then  -- TODO: check if this setting is enabled
              modules_enabled[module_name] = true
              changes_made = true
              local tier_to_disable = unlocked_module.tier - 2  -- TODO: get value from config
              if tier_to_disable >= 1 then
                for _, module in pairs(global.modules_by_tier[tier_to_disable]) do
                  if module.type == unlocked_module.type then
                    modules_enabled[module.name] = false
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  if changes_made then
    Config.handle_empties(player_index)
  end
end

script.on_event(defines.events.on_research_finished,
  function(event)
    local technology = event.research
    for _, player in pairs(technology.force.players) do
      Config.process_technology(technology, player.index)
    end
  end
)

return Config