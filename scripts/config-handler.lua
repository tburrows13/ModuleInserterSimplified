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
              local index = global.modules_by_name[module_name]
              if index then  -- TODO: check if this setting is enabled
                local unlocked_module = global.modules[index]
                unlocked_module.enabled = true
                local tier_to_disable = unlocked_module.tier - 2  -- TODO: get value from config
                if tier_to_disable >= 1 then
                  for _, module in pairs(global.modules_by_tier[tier_to_disable]) do
                    if module.type == unlocked_module.type then
                      module.enabled = false
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
)