local function control_conflict_warn(player)
  local previous_warnings = global.players_shift_scroll_warning
  if not previous_warnings[player.index] then
    player.print({"mis.control-conflict-warn"})
    previous_warnings[player.index] = true
  end
end

local function cycle_module(player, direction)
  local selection_tool = player.cursor_stack
  if selection_tool and selection_tool.valid_for_read then
    if selection_tool.name:sub(1, 10) == "mis-insert" then
      local prefix = selection_tool.name:sub(1, 11)
      local item = selection_tool.name:sub(12)
      local module_list = global.module_list
      local module_list_length = #module_list
      local next_index
      for i, module_name in pairs(module_list) do
        if module_name == item then
          next_index = i + direction
        end
      end
      if next_index > module_list_length then
        next_index = next_index - module_list_length
      elseif next_index < 1 then
        next_index = next_index + module_list_length
      end

      local next_module = module_list[next_index]
      local next_selection_tool = prefix .. next_module
      selection_tool.set_stack(next_selection_tool)
      local label = global.translations[player.index][next_selection_tool]
      selection_tool.label = label and label or next_module
      global.players_last_module[player.index] = next_module

      control_conflict_warn(player)
    end
  end
end

script.on_event("mis-cycle-module-forwards", function(event) cycle_module(game.get_player(event.player_index), 1) end)
script.on_event("mis-cycle-module-backwards", function(event) cycle_module(game.get_player(event.player_index), -1) end)
