local gui = require("__ModuleInserterSimplified__.scripts.gui-lite")
local mod_gui = require("__core__.lualib.mod-gui")

local ModuleGui = {}

function ModuleGui.create_module_table(player)
  local player_data = global.player_data[player.index]
  local column_count = 0
  for _, tier_list in pairs(global.modules_by_tier) do
    column_count = math.max(column_count, #tier_list - 1) -- -1 because we don't show the empty
  end

  local module_table = {
    type = "table",
    column_count = column_count,
    style = "slot_table",
    children = {},
  }
  for _, tier_list in pairs(global.modules_by_tier) do
    for i = 1, column_count do
      local module = tier_list[i]
      if module and module.type ~= "empty" then
        local style = "slot_button"
        if not player_data.modules_enabled[module.name] then
          style = "red_slot_button"
        end
        table.insert(module_table.children, {
          type = "sprite-button",
          style = style,
          name = module.name,
          sprite = "item/" .. module.name,
          --state = modules_enabled[module.name],
          --caption = "[item=" .. module.name .. "]",
          tooltip = { "", "\n[font=default-semibold]", module.localised_name, "[/font]" },
          tags = { name = module.name },
          handler = { [defines.events.on_gui_click] = ModuleGui.module_clicked },
          --style_mods = { height = 24, right_margin = i == column_count and 0 or 12 },
        })
      else
        table.insert(module_table.children, { type = "empty-widget" })
        --table.insert(module_table.children, { type = "label", caption = "Empty" })
      end
    end
  end
  return module_table
end

function ModuleGui.create(player)
  ModuleGui.destroy_legacy(player)
  ModuleGui.destroy(player)

  local elems = gui.add(player.gui.screen, {
    type = "frame",
    name = "mis_frame",
    caption = {"mis-gui.title"},
    direction = "vertical",
    --handler = { [defines.events.on_gui_click] = ModuleGui.on_gui_click  },
    children = {
      ModuleGui.create_module_table(player)
    }
  })

  local window_height, tool_window_height = 232, 92  -- easier to just hardcode it
  local offset = (window_height + tool_window_height + 10) * player.display_scale
  elems.mis_frame.location = {x = 5, y = (player.display_resolution.height - offset)}

end

function ModuleGui.destroy(player)
  local mis_frame = player.gui.screen.mis_frame
  if mis_frame then
    mis_frame.destroy()
  end
end

function ModuleGui.destroy_legacy(player)
  local button_flow = mod_gui.get_button_flow(player)

  if button_flow["mis_configure"] then
    button_flow["mis_configure"].destroy()
  end
end

function ModuleGui.module_clicked(player, player_data, element, mouse_button)
  if mouse_button == defines.mouse_button_type.left then
    CycleModule.set_cursor_module(player, element.name)
  elseif mouse_button == defines.mouse_button_type.right then
    local module_enabled = not player_data.modules_enabled[element.name]
    player_data.modules_enabled[element.name] = module_enabled
    local style = "slot_button"
    if not module_enabled then
      style = "red_slot_button"
    end
    element.style = style
  end
end

gui.add_handlers(ModuleGui,
  function(event, handler)
    local player = game.players[event.player_index]
    local player_data = global.player_data[event.player_index]
    handler(player, player_data, event.element, event.button)
  end
)
gui.handle_events()

local function on_player_cursor_stack_changed(event)
  local player = game.get_player(event.player_index)
  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name:sub(1, 11) == "mis-insert-" then
    ModuleGui.create(player)
  else
    ModuleGui.destroy(player)
  end
end

ModuleGui.events = {
  [defines.events.on_player_cursor_stack_changed] = on_player_cursor_stack_changed,
}

return ModuleGui