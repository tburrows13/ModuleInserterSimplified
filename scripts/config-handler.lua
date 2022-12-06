local function handle_empties()
  local empty_every = 2  -- TODO: get value from config
  local tiers_since_last_empty = 1
  for tier, tier_list in pairs(global.modules_by_tier) do
    local some_enabled = false
    for _, module in pairs(tier_list) do
      if module.type == "empty" then
        -- We have reached the end of the list of modules of this tier
        if some_enabled and tiers_since_last_empty >= empty_every then
          -- At least one module of this tier is enabled, so we can enable the empty module
          module.enabled = true
          tiers_since_last_empty = 1
        else
          -- All modules of this tier are disabled, so we can disable the empty module
          module.enabled = false
          tiers_since_last_empty = tiers_since_last_empty + 1
        end
      end
      if module.enabled then
        none_enabled = true
      end
    end
  end
end

script.on_event(defines.events.on_research_finished,
  function(event)
    local technology = event.research
    for _, effect in pairs(technology.effects) do
      if effect.type == "unlock-recipe" then
        local recipe = game.recipe_prototypes[effect.recipe]
        if recipe then
          for _, product in pairs(recipe.products) do
            if product.type == "item" then
              local module_name = product.name
              local unlocked_module = global.modules_by_name[module_name]
              if unlocked_module then  -- TODO: check if this setting is enabled
                unlocked_module.enabled = true
                local tier_to_disable = unlocked_module.tier - 2  -- TODO: get value from config
                if tier_to_disable >= 1 then
                  for _, module in pairs(global.modules_by_tier[tier_to_disable]) do
                    if module.type == unlocked_module.type then
                      module.enabled = false
                    end
                  end
                end
                handle_empties()
              end
            end
          end
        end
      end
    end
  end
)
