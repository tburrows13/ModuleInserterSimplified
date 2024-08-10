-- data-final-fixes

local selection_tool_template = {
  type = "selection-tool",
  --name = "",
  --icon = "",
  --icon_size = 64,
  --icon_mipmaps = 1,
  flags = {"hidden", "not-stackable", "only-in-cursor", "spawnable"},
  draw_label_for_cursor_render = true,
  stack_size = 1,
  selection_color = { r = 0, g = 1, b = 0 },
  alt_selection_color = { r = 1, g = 0, b = 0 },
  reverse_selection_color = { r = 0.2, g = 0.8, b = 0.3 },
  alt_reverse_selection_color = { r = 1, g = 0.3, b = 0.2 },
  selection_mode = {"same-force", "any-entity"},
  alt_selection_mode = {"same-force", "any-entity"},
  reverse_selection_mode = {"same-force", "any-entity"},
  alt_reverse_selection_mode = {"same-force", "any-entity"},
  selection_cursor_box_type = "copy",  -- Green
  alt_selection_cursor_box_type = "not-allowed",  -- Red
  reverse_selection_cursor_box_type = "copy",  -- Green
  alt_reverse_selection_cursor_box_type = "not-allowed",  -- Red
  entity_type_filters = {"mining-drill", "furnace", "assembling-machine", "lab", "beacon", "rocket-silo"},--, "item-request-proxy"},
  entity_filter_mode = "whitelist",
  alt_entity_type_filters = {"mining-drill", "furnace", "assembling-machine", "lab", "beacon", "rocket-silo"},--, "item-request-proxy"},
  alt_entity_filter_mode = "whitelist",
  reverse_entity_type_filters = {"mining-drill", "furnace", "assembling-machine", "lab", "beacon", "rocket-silo"},--, "item-request-proxy"},
  reverse_entity_filter_mode = "whitelist",
  alt_reverse_entity_type_filters = {"mining-drill", "furnace", "assembling-machine", "lab", "beacon", "rocket-silo"},--, "item-request-proxy"},
  alt_reverse_entity_filter_mode = "whitelist",
}

local module_tiers = {}
for name, prototype in pairs(data.raw.module) do
  if prototype.subgroup == "py-alienlife-modules" or prototype.subgroup == "py-alienlife-numal" then goto continue end
  module_tiers[prototype.tier] = true
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
