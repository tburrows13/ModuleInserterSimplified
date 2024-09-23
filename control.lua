local handler = require "__core__.lualib.event_handler"

ModuleGui = require "__ModuleInserterSimplified__.scripts.module-gui"
Config = require "__ModuleInserterSimplified__.scripts.config-handler"
CycleModule =   require "__ModuleInserterSimplified__.scripts.cycle-module"


on_module_inserted = script.generate_event_name()
remote.add_interface("ModuleInserterSimplified", {get_events = function() return {on_module_inserted = on_module_inserted} end})

handler.add_libraries{
  require "__ModuleInserterSimplified__.scripts.init-storage",
  CycleModule,
  require "__ModuleInserterSimplified__.scripts.insert-module",
  ModuleGui,
  Config,
}