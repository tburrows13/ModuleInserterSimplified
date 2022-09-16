-- data-final-fixes

local selection_tool_template = {
  type = "selection-tool",
  --name = "",
  --icon = "",
  --icon_size = 64,
  --icon_mipmaps = 1,
  flags = {"hidden", "not-stackable", "only-in-cursor"},
  draw_label_for_cursor_render = true,
  stack_size = 1,
  selection_color = { r = 0, g = 1, b = 0 },
  alt_selection_color = { r = 1, g = 0, b = 0 },
  reverse_selection_color = { r = 0.2, g = 0.7, b = 0.4 },
  alt_reverse_selection_color = { r = 1, g = 0.4, b = 0.4 },
  selection_mode = {"same-force", "any-entity"},
  alt_selection_mode = {"same-force", "any-entity"},
  reverse_selection_mode = {"same-force", "any-entity"},
  selection_cursor_box_type = "copy",  -- Green
  alt_selection_cursor_box_type = "not-allowed",  -- Red
  reverse_selection_cursor_box_type = "copy",  -- Green
  entity_type_filters = {"mining-drill", "furnace", "assembling-machine", "lab", "beacon", "rocket-silo"},--, "item-request-proxy"},
  entity_filter_mode = "whitelist",
  alt_entity_type_filters = {"mining-drill", "furnace", "assembling-machine", "lab", "beacon", "rocket-silo"},--, "item-request-proxy"},
  alt_entity_filter_mode = "whitelist",
  reverse_entity_type_filters = {"mining-drill", "furnace", "assembling-machine", "lab", "beacon", "rocket-silo"},--, "item-request-proxy"},
  reverse_entity_filter_mode = "whitelist",
}

for name, prototype in pairs(data.raw.module) do
  local selection_tool = table.deepcopy(selection_tool_template)
  selection_tool.name = "mis-insert-" .. name
  selection_tool.icon = prototype.icon
  selection_tool.icons = table.deepcopy(prototype.icons)
  selection_tool.icon_size = prototype.icon_size
  selection_tool.icon_mipmaps = prototype.icon_mipmaps
  selection_tool.localised_name = {"mis-tool.insert-module", prototype.localised_name or {"item-name." .. prototype.name}}
  data:extend{selection_tool}
end

local selection_tool = table.deepcopy(selection_tool_template)
selection_tool.name = "mis-insert-empty"
selection_tool.localised_name = {"item-name.mis-insert-empty"}
selection_tool.icon = "__core__/graphics/cancel.png"
selection_tool.icon_size = 64
selection_tool.icon_mipmaps = 1
selection_tool.selection_cursor_box_type = "not-allowed"  -- Red
selection_tool.alt_selection_cursor_box_type = "not-allowed"
selection_tool.selection_color = { r = 1, g = 0, b = 0 }
selection_tool.reverse_selection_color = { r = 1, g = 0, b = 0 }

data:extend{selection_tool}

-- For SE
local selection_tool_2 = table.deepcopy(selection_tool)
selection_tool_2.name = "mis-insert-empty-2"
local selection_tool_3 = table.deepcopy(selection_tool)
selection_tool_3.name = "mis-insert-empty-3"
data:extend{selection_tool_2, selection_tool_3}