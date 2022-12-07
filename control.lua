require "__ModuleInserterSimplified__.scripts.init-global"
require "__ModuleInserterSimplified__.scripts.cycle-module"
require "__ModuleInserterSimplified__.scripts.insert-module"
ConfigButtonGui = require "__ModuleInserterSimplified__.scripts.config-button-gui"
Gui = require "__ModuleInserterSimplified__.scripts.config-gui"
Config = require "__ModuleInserterSimplified__.scripts.config-handler"

on_module_inserted = script.generate_event_name()
remote.add_interface("ModuleInserterSimplified", {get_events = function() return {on_module_inserted = on_module_inserted} end})
