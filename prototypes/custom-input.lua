data:extend{
  {
    type = "custom-input",
    name = "mis-cycle-module-forwards",
    key_sequence = "SHIFT + mouse-wheel-up",
    --linked_game_control = "cycle-blueprint-forwards",
    order = "b",
    --consuming = "game-only",
  },
  {
    type = "custom-input",
    name = "mis-cycle-module-backwards",
    key_sequence = "SHIFT + mouse-wheel-down",
    --linked_game_control = "cycle-blueprint-backwards",
    order = "c",
    --consuming = "game-only",
  },
  {
    type = "custom-input",
    name = "mis-give-module-inserter",
    key_sequence = "ALT + M",
    localised_name = { "shortcut-name.mis-give-module-inserter" },
    order = "a",
  },
  {
    type = "shortcut",
    name = "mis-give-module-inserter",
    order = "b[blueprints]-h[upgrade-planner]",
    action = "lua",
    associated_control_input = "mis-give-module-inserter",
    --technology_to_unlock = "construction-robotics",
    style = "green",
    icon =
    {
      filename = "__ModuleInserterSimplified__/graphics/module-inserter-x32-white.png",
      priority = "extra-high-no-scale",
      size = 32,
      scale = 0.5,
      mipmap_count = 1,
      flags = {"gui-icon"}
    },
  },
}
