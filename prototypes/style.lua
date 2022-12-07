local styles = data.raw["gui-style"].default

styles.mis_flib_titlebar_flow = {
  type = "horizontal_flow_style",
  horizontal_spacing = 8,
}

styles.mis_flib_titlebar_drag_handle = {
  type = "empty_widget_style",
  parent = "draggable_space",
  left_margin = 4,
  right_margin = 4,
  height = 24,
  horizontally_stretchable = "on",
}

styles.mis_mod_gui_button_green = {
  type = "button_style",
  parent = "tool_button_green",
  size = 40,
  padding = 8,
}
