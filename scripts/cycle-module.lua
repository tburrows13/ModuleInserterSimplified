local CycleModule = {}

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

      CycleModule.set_cursor_module(player, next_module_name)

      control_conflict_warn(player)
    end
  end
end

local function on_lua_shortcut(event)
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
    CycleModule.set_cursor_module(player, next_module)
  end
end

function CycleModule.set_cursor_module(player, module)
  local cursor_stack = player.cursor_stack

  local selection_tool = "mis-insert-" .. module

  -- Check if it exists
  cursor_stack.set_stack(selection_tool)
  local label = global.translations[player.index][selection_tool]
  cursor_stack.label = label and label or module
  global.players_last_module[player.index] = module

  ModuleGui.create(player)  -- Refresh module GUI highlights
end

CycleModule.events = {
  ["mis-cycle-module-forwards"] = function(event) cycle_module(game.get_player(event.player_index), 1) end,
  ["mis-cycle-module-backwards"] = function(event) cycle_module(game.get_player(event.player_index), -1) end,
  [defines.events.on_lua_shortcut] = on_lua_shortcut,
  ["mis-give-module-inserter"] = on_lua_shortcut,
}

return CycleModule