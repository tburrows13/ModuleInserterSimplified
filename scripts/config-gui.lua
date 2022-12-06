local gui = require("__ModuleInserterSimplified__.scripts.flib-gui")

local Gui = {}

function Gui.build_module_table()
  -- [x] | M Productivity 1 [x] | M Efficiency 1 [x] | M Speed 1 [x]
  -- [ ] | M Productivity 2 [x] | M Efficiency 2 [ ] | M Speed 2 [x]
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
          state = module.enabled,
          caption = module.localised_name,
          tags = { name = module.name },
          handler = { [defines.events.on_gui_checked_state_changed] = Gui.module_toggled },
          --[[children = {
            {
              type = "sprite",
              sprite = "item/" .. module.name,
            }
          }]]
        })
      else
        --table.insert(module_table.children, { type = "empty-widget" })
        table.insert(module_table.children, { type = "label", caption = "Empty" })
      end
    end
  end
  return module_table
end

function Gui.build(player)
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
              caption = { "mod-name.ModuleInserterSimplified" },
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
            {
              type = "checkbox",
              name = "mis_automatically_enable",
              state = true,
              caption = { "mis-config-gui.automatically-enable" },
              actions = {
                on_checked_state_changed = { gui = "config", action = "checkbox_toggled" }
              }
            },
            {
              type = "flow",
              children = {
                {
                  type = "label",
                  caption = "Automatically hide modules more than X tiers old"
                },
                {
                  type = "drop-down",
                  items = { 1, 2, 3 },
                }
              }
            },
            {
              type = "flow",
              children = {
                {
                  type = "label",
                  caption = "[item=mis-insert-empty-1] every X tiers",
                },
                {
                  type = "drop-down",
                  items = { 1, 2, 3 },
                  selected_index = 3,
                }
              }
            },
            Gui.build_module_table()
          }
        },
      }
    }
  })

  local player_data = {}
  elems.mis_frame.force_auto_center()
  player_data.elems = elems
  global.player_data[player.index] = player_data
  return player_data
end


function Gui.open(player, player_data)
  if not player_data or not player_data.elems.mis_frame.valid then
    player_data = Gui.build(player)
  end
  local elems = player_data.elems
  player.opened = elems.mis_frame
  elems.mis_frame.visible = true
  elems.mis_frame.bring_to_front()
end

function Gui.close(player, player_data)
  local elems = player_data.elems
  elems.mis_frame.visible = false
  if player.opened == elems.mis_frame then
    player.opened = nil
  end
  elems.mis_frame.destroy()
end

function Gui.module_toggled(player, player_data, event)
  local module_name = event.element.tags.name
  local module = global.modules_by_name[module_name]
  module.enabled = event.element.state
  Config.handle_empties()
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