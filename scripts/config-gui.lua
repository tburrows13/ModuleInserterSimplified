local gui = require("__ModuleInserterSimplified__.scripts.flib-gui")

local Gui = {}

function Gui.build(player)
  local elems = {}
  gui.add(player.gui.screen, {
    {
      type = "frame",
      name = "mis_frame",
      direction = "vertical",
      visible = true,
      style_mods = { maximal_height = 800 },
      actions = {
        on_closed = { gui = "config", action = "close" },
      },
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
              type = "checkbox",
              name = "mis_show_cheat_modules",
              state = false,
              caption = { "mis-config-gui.show-cheat-modules" },
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
            -- [x] | M Productivity 1 [x] | M Efficiency 1 [x] | M Speed 1 [x]
            -- [ ] | M Productivity 2 [x] | M Efficiency 2 [ ] | M Speed 2 [x]
            {
              type = "table",
              name = "mis_module_table",
              column_count = 4,
            }
          }
        },
      }
    }
  }, elems)

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
  --Gui.destroy(player, player_data)
end

function Gui.toggle(player, player_data)
  if player_data and player_data.elems.mis_frame.valid and player_data.elems.mis_frame.visible then
    Gui.close(player, player_data)
  else
    Gui.open(player, player_data)
  end
end

gui.add_handlers(Gui,
  function(event, handler)
    local player = game.get_player(event.player_index)
    local player_data = global.player_data[event.player_index]
    handler(player, player_data)
  end
)

script.on_event(defines.events.on_gui_closed,
  function(event)
    if event.element and event.element.name == "mis_frame" then
      local player = game.get_player(event.player_index)
      Gui.close(player, global.player_data[event.player_index])
    end
  end
)

return Gui