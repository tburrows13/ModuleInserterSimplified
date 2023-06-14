local function control_conflict_warn(player)
  local previous_warnings = global.players_shift_scroll_warning
  if not previous_warnings[player.index] and player.input_method ~= defines.input_method.game_controller then
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
      local modules_enabled = global.player_data[player.index].modules_enabled

      local next_module
      repeat
        next_index = get_next_index(next_index, direction, modules_length)
        next_module = modules[next_index]
      until modules_enabled[next_module.name] or first_index == next_index

      if not modules_enabled[next_module.name] then return end  -- No other modules to cycle to

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

script.on_event({defines.events.on_lua_shortcut, "mis-give-module-inserter"},
  function(event)
    if event.prototype_name and event.prototype_name ~= "mis-give-module-inserter" then return end
    local player = game.get_player(event.player_index)
    local cursor_stack = player.cursor_stack
    local next_module
    if cursor_stack and cursor_stack.valid_for_read then
      next_module = cursor_stack.name  -- Get selection tool from currently held module
    end
    if not next_module then
      local cursor_ghost = player.cursor_ghost
      if cursor_ghost then
        next_module = cursor_ghost.name
      end
    end
    local cleared = player.clear_cursor()
    if cleared then
      if not (next_module and global.modules_by_name[next_module]) then
        next_module = global.players_last_module[event.player_index]  -- Get selection tool from last used selection tool
      end
      if not next_module or not game.item_prototypes[next_module] then
        next_module = global.modules[1].name  -- TODO: skip enabled modules?
      end
      local next_selection_tool = "mis-insert-" .. next_module
      cursor_stack.set_stack(next_selection_tool)
      local label = global.translations[event.player_index][next_selection_tool]
      cursor_stack.label = label and label or next_module
      global.players_last_module[player.index] = next_module
    end
  end
)
