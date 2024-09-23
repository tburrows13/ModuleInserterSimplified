local gui = require("__ModuleInserterSimplified__.scripts.gui-lite")
local mod_gui = require("__core__.lualib.mod-gui")

local ModuleGui = {}

function ModuleGui.create_module_table(player, player_data)
  local column_count = 0
  for _, tier_list in pairs(storage.modules_by_tier) do
    column_count = math.max(column_count, #tier_list)
  end

  local module_table = {
    type = "table",
    column_count = column_count,
    style = "filter_slot_table",
    children = {},
  }
  for _, tier_list in pairs(storage.modules_by_tier) do
    for i = 1, column_count do
      local module = tier_list[i]
      if module then
        local style = "slot_button"
        if player.cursor_stack and player.cursor_stack.valid_for_read and module.name == player.cursor_stack.name:sub(12) then
          style = "yellow_slot_button"
        elseif not player_data.modules_enabled[module.name] then
          style = "red_slot_button"
        end
        table.insert(module_table.children, {
          type = "sprite-button",
          style = style,
          name = module.name,
          sprite = "item/mis-insert-" .. module.name,
          tooltip = { "", "\n\n[font=default-semibold]", module.localised_name, "[/font]\n", {"mis-gui.module-tooltip"} },
          tags = { name = module.name },
          handler = { [defines.events.on_gui_click] = ModuleGui.module_clicked },
        })
      else
        table.insert(module_table.children, { type = "empty-widget" })
      end
    end
  end
  return module_table
end

function ModuleGui.create(player)
  local player_data = storage.player_data[player.index]

  ModuleGui.destroy_legacy(player)
  ModuleGui.destroy(player, player_data)

  local elems = gui.add(player.gui.screen, {
    type = "frame",
    name = "mis_frame",
    caption = {"mis-gui.title"},
    direction = "vertical",
    --handler = { [defines.events.on_gui_click] = ModuleGui.on_gui_click  },
    children = {
      {
        type = "frame",
        direction = "vertical",
        style = "inside_shallow_frame_with_padding",
        children = {
          {
            type = "frame",
            style = "filter_scroll_pane_background_frame",
            style_mods = {minimal_height = 5},
            children = ModuleGui.create_module_table(player, player_data),
          },
          {
            type = "label",
            caption = {"mis-gui.info"},
            style_mods = {single_line = false, top_padding = 10},
          },
        }
      }
    }
  })

  if not player_data.gui_position then
    -- Calculate starting GUI location
    local offset = 550 * player.display_scale
    player_data.gui_position = {x = 5, y = (player.display_resolution.height - offset)}
  end
  elems.mis_frame.location = player_data.gui_position
end

function ModuleGui.destroy(player, player_data)
  local mis_frame = player.gui.screen.mis_frame
  if mis_frame then
    player_data.gui_position = mis_frame.location
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
    ModuleGui.create(player)  -- Refresh module GUI highlights
  end
end

gui.add_handlers(ModuleGui,
  function(event, handler)
    local player = game.players[event.player_index]
    local player_data = storage.player_data[event.player_index]
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
    local player_data = storage.player_data[player.index]
    ModuleGui.destroy(player, player_data)
  end
end

ModuleGui.events = {
  [defines.events.on_player_cursor_stack_changed] = on_player_cursor_stack_changed,
}

return ModuleGui