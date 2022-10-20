require "__ModuleInserterSimplified__.scripts.init-global"
require "__ModuleInserterSimplified__.scripts.cycle-module"
require "__ModuleInserterSimplified__.scripts.insert-module"
Gui = require "__ModuleInserterSimplified__.scripts.config-gui"

on_module_inserted = script.generate_event_name()
remote.add_interface("ModuleInserterSimplified", {get_events = function() return {on_module_inserted = on_module_inserted} end})
