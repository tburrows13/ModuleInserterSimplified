Config = {}

function Config.process_technology(technology, player_index, old_modules_enabled)
  old_modules_enabled = old_modules_enabled or {}
  local player_data = storage.player_data[player_index]
  local modules_enabled = player_data.modules_enabled

  for _, effect in pairs(technology.prototype.effects) do
    if effect.type == "unlock-recipe" then
      local recipe = prototypes.recipe[effect.recipe]
      if recipe then
        for _, product in pairs(recipe.products) do
          if product.type == "item" then
            local module_name = product.name
            local unlocked_module = storage.modules_by_name[module_name]
            if unlocked_module and old_modules_enabled[module_name] ~= false then
              modules_enabled[module_name] = true
              if player_data.elems and player_data.elems[module_name] then
                player_data.elems[module_name].state = true
              end
            end
          end
        end
      end
    end
  end
end

local function on_research_finished(event)
  local technology = event.research
  for _, player in pairs(technology.force.players) do
    Config.process_technology(technology, player.index)
    if player.gui.screen.mis_frame then
      ModuleGui.create(player)  -- Refresh module GUI highlights
    end
  end
end

Config.events = {
  [defines.events.on_research_finished] = on_research_finished
}

return Config