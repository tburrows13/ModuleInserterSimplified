local gui = require("__ModuleInserterSimplified__.scripts.flib-gui")

local Gui = {}

function Gui.build(player)
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      name = "mis_frame",
      direction = "vertical",
      visible = true,
      ref = { "frame" },
      style_mods = { maximal_height = 800 },
      actions = {
        on_closed = { gui = "config", action = "close" },
      },
      children = {
        {
          type = "flow",
          style = "mis_flib_titlebar_flow",
          ref = { "titlebar_flow" },
          actions = {
            on_click = { gui = "config", action = "recenter" },  -- TODO What is this?
          },
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
              style = "close_button",
              sprite = "utility/close_white",
              hovered_sprite = "utility/close_black",
              clicked_sprite = "utility/close_black",
              mouse_button_filter = { "left" },
              tooltip = { "gui.close-instruction" },
              ref = { "close_button" },
              actions = {
                on_click = { gui = "config", action = "close" },
              },
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
              state = true,
              caption = {"mis-config-gui.automatically-enable"},
              ref = { "automatically_enable" },
              actions = {
                on_checked_state_changed = { gui = "config", action = "checkbox_toggled" }
              }
            },
            {
              type = "checkbox",
              state = false,
              caption = {"mis-config-gui.show-cheat-modules"},
              ref = { "show_cheat_modules" },
              actions = {
                on_checked_state_changed = { gui = "config", action = "checkbox_toggled" }
              }
            },
            -- Automatically show X [dropdown?] newest per tier
            -- Show empty every X [dropdown?] tiers
            -- [x] | M Productivity 1 [x] | M Efficiency 1 [x] | M Speed 1 [x]
            -- [ ] | M Productivity 2 [x] | M Efficiency 2 [ ] | M Speed 2 [x]
          }
        },
      }
    }
  })

  local player_data = {}
  refs.titlebar_flow.drag_target = refs.frame
  refs.frame.force_auto_center()
  player_data.refs = refs
  global.player_data[player.index] = player_data
  return player_data
end


function Gui.open(player, player_data)
  if not player_data or not player_data.refs.frame.valid then
    player_data = Gui.build(player)
  end
  local refs = player_data.refs
  player.opened = refs.frame
  refs.frame.visible = true
  refs.frame.bring_to_front()
end

function Gui.close(player, player_data)
  local refs = player_data.refs
  refs.frame.visible = false
  if player.opened == refs.frame then
    player.opened = nil
  end
  --Gui.destroy(player, player_data)
end

function Gui.toggle(player, player_data)
  if player_data and player_data.refs.frame.valid and player_data.refs.frame.visible then
    Gui.close(player, player_data)
  else
    Gui.open(player, player_data)
  end
end

gui.hook_events(
  function(event)
    local action = gui.read_action(event)
    if action then
      local player = game.get_player(event.player_index)
      local player_data = global.player_data[event.player_index]

      local msg = action.action
      if msg == "close" then  -- on_gui_click
        Gui.close(player, player_data)
        --Gui.destroy(player, player_data)
      end
    end
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