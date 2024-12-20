-- data-final-fixes

local selection_tool_template = {
  type = "selection-tool",
  --name = "",
  --icon = "",
  --icon_size = 64,
  --icon_mipmaps = 1,
  flags = {"not-stackable", "only-in-cursor", "spawnable"},
  hidden = true,
  draw_label_for_cursor_render = true,
  stack_size = 1,
  select = {
    border_color = { r = 0, g = 1, b = 0 },
    cursor_box_type = "copy",  -- Green
    mode = {"same-force", "any-entity"},
    entity_type_filters = {"mining-drill", "furnace", "assembling-machine", "lab", "beacon", "rocket-silo"},--, "item-request-proxy"},
  },
  alt_select = {
    border_color = { r = 1, g = 0, b = 0 },
    cursor_box_type = "not-allowed",  -- Red
    mode = {"same-force", "any-entity"},
    entity_type_filters = {"mining-drill", "furnace", "assembling-machine", "lab", "beacon", "rocket-silo"},--, "item-request-proxy"},
  },
  reverse_select = {
    border_color = { r = 0.2, g = 0.8, b = 0.3 },
    cursor_box_type = "copy",  -- Green
    mode = {"same-force", "any-entity"},
    entity_type_filters = {"mining-drill", "furnace", "assembling-machine", "lab", "beacon", "rocket-silo"},--, "item-request-proxy"},
  },
  alt_reverse_select = {
    border_color = { r = 1, g = 0.3, b = 0.2 },
    cursor_box_type = "not-allowed",  -- Red
    mode = {"same-force", "any-entity"},
    entity_type_filters = {"mining-drill", "furnace", "assembling-machine", "lab", "beacon", "rocket-silo"},--, "item-request-proxy"},
  },
}

for name, prototype in pairs(data.raw.module) do
  if prototype.subgroup == "py-alienlife-modules" or prototype.subgroup == "py-alienlife-numal" or prototype.subgroup == "alien-hyper-module" then goto continue end
  local selection_tool = table.deepcopy(selection_tool_template)
  selection_tool.name = "mis-insert-" .. name
  selection_tool.icon = prototype.icon
  selection_tool.icons = table.deepcopy(prototype.icons)
  selection_tool.icon_size = prototype.icon_size
  selection_tool.icon_mipmaps = prototype.icon_mipmaps
  selection_tool.localised_name = {"mis-tool.insert-module", prototype.localised_name or {"item-name." .. prototype.name}}
  data:extend{selection_tool}
  ::continue::
end

local empty_selection_tool = table.deepcopy(selection_tool_template)
empty_selection_tool.name = "mis-insert-remove-modules"
empty_selection_tool.localised_name = {"item-name.remove-modules"}
empty_selection_tool.icon = "__core__/graphics/cancel.png"
empty_selection_tool.icon_size = 64
empty_selection_tool.icon_mipmaps = 1
empty_selection_tool.selection_cursor_box_type = "not-allowed"  -- Red
empty_selection_tool.reverse_selection_cursor_box_type = "not-allowed"
empty_selection_tool.selection_color = { r = 1, g = 0, b = 0 }
empty_selection_tool.reverse_selection_color = { r = 1, g = 0.3, b = 0.2 }
empty_selection_tool.alt_selection_color = { r = 0, g = 0, b = 0, a = 0 }
empty_selection_tool.alt_reverse_selection_color = { r = 0, g = 0, b = 0, a = 0 }
empty_selection_tool.alt_selection_mode = {"nothing"}
empty_selection_tool.alt_reverse_selection_mode = {"nothing"}

data:extend{empty_selection_tool}
