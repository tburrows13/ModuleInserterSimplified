local CycleModule = {}

local function control_conflict_warn(player)
  local previous_warnings = storage.players_shift_scroll_warning
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
      local quality = selection_tool.quality
      local modules = storage.modules
      local modules_length = #modules
      local first_index = storage.modules_by_name[item].index
      local next_index = first_index
      local modules_enabled = storage.player_data[player.index].modules_enabled

      local next_module
      repeat
        next_index = get_next_index(next_index, direction, modules_length)
        next_module = modules[next_index]
      until modules_enabled[next_module.name] or first_index == next_index

      if not modules_enabled[next_module.name] then return end  -- No other modules to cycle to

      local next_module_name = next_module.name

      CycleModule.set_cursor_module(player, next_module_name, quality)

      control_conflict_warn(player)
    end
  end
end

local function cycle_quality(player, direction)
  local selection_tool = player.cursor_stack
  if selection_tool and selection_tool.valid_for_read then
    if selection_tool.name:sub(1, 10) == "mis-insert" then
      local item = selection_tool.name:sub(12)
      local quality = selection_tool.quality
      local next_quality
      if direction == 1 then
        next_quality = quality.next and quality.next.name
      else
        for _, quality_prototype in pairs(prototypes.quality) do
          if quality_prototype.next and quality_prototype.next.name == quality.name then
            next_quality = quality_prototype.name
            break
          end
        end
      end
      if next_quality then
        CycleModule.set_cursor_module(player, item, next_quality)
      end
    end
  end
end

local function on_lua_shortcut(event)
  if event.prototype_name and event.prototype_name ~= "mis-give-module-inserter" then return end
  local player = game.get_player(event.player_index)
  local cursor_stack = player.cursor_stack
  local next_module
  local next_quality = "normal"
  if cursor_stack and cursor_stack.valid_for_read then
    next_module = cursor_stack.name  -- Get selection tool from currently held module
    next_quality = cursor_stack.quality.name
  end
  if not next_module then
    local cursor_ghost = player.cursor_ghost
    if cursor_ghost then
      next_module = cursor_ghost.name
      next_quality = cursor_ghost.quality.name
    end
  end
  local cleared = player.clear_cursor()
  if cleared then
    if not (next_module and storage.modules_by_name[next_module]) then
      local next_module_and_quality = storage.players_last_module[event.player_index]  -- Get selection tool from last used selection tool
      next_module = next_module_and_quality and next_module_and_quality.name
      next_quality = next_module_and_quality and next_module_and_quality.quality or "normal"
    end
    if not next_module or not prototypes.item[next_module] then
      next_module = storage.modules[1].name  -- TODO: skip enabled modules?
    end
    CycleModule.set_cursor_module(player, next_module, next_quality)
  end
end

function CycleModule.set_cursor_module(player, module, quality)
  local cursor_stack = player.cursor_stack

  local selection_tool = "mis-insert-" .. module

  -- Check if it exists
  cursor_stack.set_stack({name = selection_tool, quality = quality})
  local label = storage.translations[player.index][selection_tool]
  cursor_stack.label = label and label or module
  storage.players_last_module[player.index] = {name = module, quality = quality}

  ModuleGui.create(player)  -- Refresh module GUI highlights
end

CycleModule.events = {
  ["mis-cycle-module-forwards"] = function(event) cycle_module(game.get_player(event.player_index), 1) end,
  ["mis-cycle-module-backwards"] = function(event) cycle_module(game.get_player(event.player_index), -1) end,
  ["mis-cycle-quality-forwards"] = function(event) cycle_quality(game.get_player(event.player_index), 1) end,
  ["mis-cycle-quality-backwards"] = function(event) cycle_quality(game.get_player(event.player_index), -1) end,
  [defines.events.on_lua_shortcut] = on_lua_shortcut,
  ["mis-give-module-inserter"] = on_lua_shortcut,
}

return CycleModule