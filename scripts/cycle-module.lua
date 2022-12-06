local function control_conflict_warn(player)
  local previous_warnings = global.players_shift_scroll_warning
  if not previous_warnings[player.index] then
    player.print({"mis.control-conflict-warn"})
    previous_warnings[player.index] = true
  end
end

local function get_next_index(index, direction, modules_length)
  local next_index = index + direction
  if next_index > modules_length then
    next_index = next_index - modules_length
  elseif next_index < 1 then
    next_index = next_index + modules_length
  end
  return next_index
end

local function cycle_module(player, direction)
  local selection_tool = player.cursor_stack
  if selection_tool and selection_tool.valid_for_read then
    if selection_tool.name:sub(1, 10) == "mis-insert" then
      local prefix = selection_tool.name:sub(1, 11)
      local item = selection_tool.name:sub(12)
      local modules = global.modules
      local modules_length = #modules
      local first_index = global.modules_by_name[item].index
      local next_index = first_index

      local next_module
      repeat
        next_index = get_next_index(next_index, direction, modules_length)
        next_module = modules[next_index]
      until next_module.enabled or first_index == next_index

      if not next_module.enabled then return end  -- No other modules to cycle to

      local next_module_name = next_module.name
      local next_selection_tool = prefix .. next_module_name
      selection_tool.set_stack(next_selection_tool)
      local label = global.translations[player.index][next_selection_tool]
      selection_tool.label = label and label or next_module_name
      global.players_last_module[player.index] = next_module_name

      control_conflict_warn(player)
    end
  end
end

script.on_event("mis-cycle-module-forwards", function(event) cycle_module(game.get_player(event.player_index), 1) end)
script.on_event("mis-cycle-module-backwards", function(event) cycle_module(game.get_player(event.player_index), -1) end)
