local gui = require("__ModuleInserterSimplified__.scripts.flib-gui")

local Gui = {}

local function array_to_n(n)
  local t = {}
  for i = 1, n do
    t[i] = i
  end
  return t
end

function Gui.build_module_table(player)
  local player_data = global.player_data[player.index]
  local modules_enabled = player_data.modules_enabled

  -- Get max tier
  local column_count = 0
  for _, tier_list in pairs(global.modules_by_tier) do
    column_count = math.max(column_count, #tier_list - 1) -- -1 because we don't show the empty
  end

  local module_table = {
    type = "table",
    name = "mis_module_table",
    column_count = column_count,
    children = {}
  }

  for _, tier_list in pairs(global.modules_by_tier) do
    for i = 1, column_count do
      local module = tier_list[i]
      if module and module.type ~= "empty" then
        table.insert(module_table.children, {
          type = "checkbox",
          name = module.name,
          state = modules_enabled[module.name],
          caption = "[item=" .. module.name .. "]",
          tooltip = module.localised_name,
          tags = { name = module.name },
          handler = { [defines.events.on_gui_checked_state_changed] = Gui.module_toggled },
          style_mods = { right_margin = 14 },
          --[[children = {
            {
              type = "sprite",
              sprite = "item/" .. module.name,
            }
          }]]
        })
      else
        table.insert(module_table.children, { type = "empty-widget" })
        --table.insert(module_table.children, { type = "label", caption = "Empty" })
      end
    end
  end
  return module_table
end

function Gui.build(player)
  local player_data = global.player_data[player.index]

  local elems = gui.add(player.gui.screen, {
    {
      type = "frame",
      name = "mis_frame",
      direction = "vertical",
      visible = true,
      style_mods = { maximal_height = 800 },
      handler = { [defines.events.on_gui_closed] = Gui.close },
      children = {
        {
          type = "flow",
          name = "mis_titlebar_flow",
          style = "mis_flib_titlebar_flow",
          drag_target = "mis_frame",
          children = {
            {
              type = "label",
              style = "frame_title",
              caption = { "mis-config-gui.title" },
              ignored_by_interaction = true,
            },
            { type = "empty-widget", style = "mis_flib_titlebar_drag_handle", ignored_by_interaction = true },
            {
              type = "sprite-button",
              name = "mis_close_button",
              style = "close_button",
              sprite = "utility/close_white",
              hovered_sprite = "utility/close_black",
              clicked_sprite = "utility/close_black",
              mouse_button_filter = { "left" },
              tooltip = { "gui.close-instruction" },
              handler = { [defines.events.on_gui_click] = Gui.close },
            },
          },
        },
        {
          type = "frame",
          style = "inside_shallow_frame_with_padding",
          direction = "vertical",
          children = {
            --[[{
              type = "checkbox",
              name = "mis_automatically_enable",
              state = player_data.automatically_enable,
              caption = { "mis-config-gui.automatically-enable" },
              tooltip = { "mis-config-gui.automatically-enable-tooltip" },
              handler = { [defines.events.on_gui_checked_state_changed] = Gui.automatically_enable_toggled },
            },
            {
              type = "flow",
              style = "centering_horizontal_flow",
              children = {
                {
                  type = "label",
                  caption = { "mis-config-gui.automatically-disable" },
                  tooltip = { "mis-config-gui.automatically-disable-tooltip" },
                },
                {
                  type = "drop-down",
                  items = array_to_n(#global.modules_by_tier),
                  selected_index = player_data.automatically_disable_tier_below,
                  handler = { [defines.events.on_gui_selection_state_changed] = Gui.automatically_disable_tier_below_changed },
                  style_mods = { width = (#global.modules_by_tier < 10) and 60 or 70 },
                }
              }
            },
            {
              type = "flow",
              style = "centering_horizontal_flow",
              children = {
                {
                  type = "label",
                  caption = "Include [item=mis-insert-empty-1] every X tiers",
                },
                {
                  type = "drop-down",
                  items = array_to_n(#global.modules_by_tier),
                  selected_index = 3,
                  style_mods = { width = (#global.modules_by_tier < 10) and 60 or 70 },
                }
              }
            },]]
            --[[{
              type = "label",
              caption = 
            }]]
            Gui.build_module_table(player)
          }
        },
      }
    }
  })

  elems.mis_frame.force_auto_center()
  player_data.elems = elems
  return player_data
end


function Gui.open(player, player_data)
  if not player_data or not player_data.elems or not player_data.elems.mis_frame.valid then
    player_data = Gui.build(player)
  end
  local elems = player_data.elems
  player.opened = elems.mis_frame
  elems.mis_frame.visible = true
  elems.mis_frame.bring_to_front()
end

function Gui.close(player, player_data)
  local elems = player_data.elems
  if elems and elems.mis_frame and elems.mis_frame.valid then
    elems.mis_frame.destroy()
  end
  player_data.elems = nil
end

function Gui.toggle(player)
  local player_data = global.player_data[player.index]
  if player_data and player_data.elems and player_data.elems.mis_frame.valid then
    Gui.close(player, player_data)
  else
    Gui.open(player, player_data)
  end
end

function Gui.automatically_enable_toggled(player, player_data, event)
  player_data.automatically_enable = event.element.state
end

function Gui.automatically_disable_tier_below_changed(player, player_data, event)
  player_data.automatically_disable_tier_below = event.element.selected_index
end

function Gui.module_toggled(player, player_data, event)
  local module_name = event.element.tags.name
  player_data.modules_enabled[module_name] = event.element.state
  Config.handle_empties(player.index)
end

gui.add_handlers(Gui,
  function(event, handler)
    local player = game.get_player(event.player_index)
    local player_data = global.player_data[event.player_index]
    handler(player, player_data, event)
  end
)

gui.handle_events()

return Gui