local gui = require("__ModuleInserterSimplified__.scripts.gui-lite")
local mod_gui = require("__core__.lualib.mod-gui")

local ConfigButtonGui = {}

function ConfigButtonGui.create(player)
  local button_flow = mod_gui.get_button_flow(player)

  ConfigButtonGui.destroy(player)

  gui.add(button_flow, {
    type = "sprite-button",
    name = "mis_configure",
    style = "mis_mod_gui_button_green",
    sprite = "mis_configure_white",
    tooltip = { "", "\n", { "mis-config-gui.configure-tooltip" } },
    handler = { [defines.events.on_gui_click] = ConfigButtonGui.on_gui_click  }
  })
end

function ConfigButtonGui.destroy(player)
  local button_flow = mod_gui.get_button_flow(player)

  if button_flow["mis_configure"] then
    button_flow["mis_configure"].destroy()
  end
end

function ConfigButtonGui.on_gui_click(event)
  local player = game.get_player(event.player_index)
  Gui.toggle(player)
end

gui.add_handlers(ConfigButtonGui)
gui.handle_events()

script.on_event(defines.events.on_player_cursor_stack_changed,
  function(event)
    local player = game.get_player(event.player_index)
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name:sub(1, 11) == "mis-insert-" then
      ConfigButtonGui.create(player)
    else
      ConfigButtonGui.destroy(player)
    end
  end
)