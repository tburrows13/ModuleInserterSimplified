local InsertModule = {}

local function on_object_destroyed(event)
  local entity = storage.proxy_targets[event.registration_number]
  if not (entity and entity.valid) then return end
  storage.proxy_targets[event.registration_number] = nil

  local module_inventory = entity.get_module_inventory()
  if not module_inventory then return end
  --module_inventory.sort_and_merge()
end

local function get_property(entity, property)
  if entity.name == "entity-ghost" then
    return entity["ghost_" .. property]
  end
  return entity[property]
end

local function get_recipe(entity)
  if entity.type == "assembling-machine"
  or entity.type == "rocket-silo"
  or entity.type == "furnace"
  or (entity.type == "entity-ghost" and entity.ghost_type == "assembling-machine") then
    return entity.get_recipe()
  end
end

local function check_module_allowed(module, entity, player)
  if module == "remove-modules" then return true end

  -- Don't print warning if no module inventory
  local module_inventory_size = get_property(entity, "prototype").module_inventory_size
  if not module_inventory_size or module_inventory_size == 0 then return false end

  -- Check if allowed with recipe
  local allowed_with_recipe = storage.allowed_with_recipe[module]
  local recipe = get_recipe(entity)
  local recipe_name = recipe and recipe.name
  if recipe_name and allowed_with_recipe and not allowed_with_recipe[recipe_name] then
    player.create_local_flying_text{
      text = allowed_with_recipe.limitation_message_key,
      position = entity.position,
    }
    return false
  end

  -- Check if allowed with entity prototype
  local allowed_in_entity = storage.allowed_in_entity[module]
  if not allowed_in_entity[get_property(entity, "name")] then
    local text = allowed_in_entity.limitation_message_key
    text[3] = get_property(entity, "localised_name")
    player.create_local_flying_text{
      text = text,
      position = entity.position,
    }
    return false
  end
  return true
end

local function convert_item_requests(requests)
  -- Convert list of dicts to dict-by-name of dict-by-quality of count
  local converted = {}
  for _, request in pairs(requests) do
    local name = request.name
    local quality = request.quality
    local count = request.count
    if converted[name] then
      converted[name][quality] = count
    else
      converted[name] = {[quality] = count}
    end
  end
  return converted
end

local function insert_into_entities_in_area(target_module, area, player, surface, upgrade_planner)
  for i, module in pairs(storage.modules) do
    if module.name ~= "remove-modules" then  -- "remove-modules" is a dummy item - don't add it. This index will handle empty module slots
      upgrade_planner.set_mapper(i, "from", {type = "item", name = module.name})
    end
    upgrade_planner.set_mapper(i, "to", {type = "item", name = target_module})
  end

  surface.upgrade_area{
    area = area,
    force = player.force,
    player = player,
    item = upgrade_planner,
  }
end

local function insert_single_into_entities(target_module, entities, player, surface, upgrade_planner)
  for _, entity in pairs(entities) do
    local inventory_size
    local correct_modules_in_inventory = 0
    local requests

    if entity.type == "entity-ghost" then
      inventory_size = entity.ghost_prototype.module_inventory_size
      if inventory_size == 0 then goto continue end
      requests = convert_item_requests(entity.item_requests or {})

    else
      -- Entity is not ghost
      local module_inventory = entity.get_module_inventory()
      inventory_size = #module_inventory
      if inventory_size == 0 then goto continue end

      -- If inventory is full of 'module', return
      correct_modules_in_inventory = module_inventory.get_item_count(target_module)
      if correct_modules_in_inventory == inventory_size then goto continue end
      local request_proxy = entity.surface.find_entity("item-request-proxy", entity.position)
      requests = convert_item_requests(request_proxy and request_proxy.item_requests or {})
    end

    local correct_modules_and_requests = correct_modules_in_inventory + (requests[target_module] and requests[target_module]["normal"] or 0)
    if correct_modules_and_requests == inventory_size then goto continue end

    for i, module in pairs(storage.modules) do
      if module.name ~= "remove-modules" then  -- "remove-modules" is a dummy item - don't add it. This index will handle empty module slots
        upgrade_planner.set_mapper(i, "from", {type = "item", name = module.name})
      end
      upgrade_planner.set_mapper(i, "to", {type = "item", name = target_module, count = correct_modules_and_requests + 1})
    end

    surface.upgrade_area{
      area = entity.bounding_box,
      force = player.force,
      player = player,
      item = upgrade_planner,
    }
    ::continue::
  end
  do return end

  if module == "remove-modules" then
    if entity.type == "entity-ghost" then return end
    -- Remove a single module
    local module_inventory = entity.get_module_inventory()
    local inventory_size = #module_inventory
    if inventory_size == 0 then return end
    for i = 1, inventory_size do
      local module_stack = module_inventory[i]
      if module_stack and module_stack.valid_for_read then
        if module_stack.name ~= module then
          local spilled = surface.spill_item_stack(entity.bounding_box.left_top, module_stack, true, player.force, false)
          if spilled[1] or surface.name:sub(1, 4) == "bpsb" then
            module_stack.clear()
            break
          end
        end
      end
    end
    return
  end
end

local function insert_modules(event, insert_single)
  local selection_tool = event.item
  local prefix = selection_tool:sub(1, 11)
  local item = selection_tool:sub(12)
  if prefix == "mis-insert-" then
    local player = game.get_player(event.player_index)
    local surface = event.surface
    if item == "remove-modules" then
      item = nil
    end

    local inventory = game.create_inventory(1)
    inventory.insert{name = "upgrade-planner"}
    local upgrade_planner = inventory[1]

    if insert_single then
      insert_single_into_entities(item, event.entities, player, surface, upgrade_planner)
    else
      insert_into_entities_in_area(item, event.area, player, surface, upgrade_planner)
    end
    inventory.destroy()
  end
end

local function on_player_alt_selected_area(event)
  local selection_tool = event.item
  local prefix = selection_tool:sub(1, 11)
  if prefix == "mis-insert-" then
    for _, entity in pairs(event.entities) do
      request_proxy = entity.surface.find_entity("item-request-proxy", entity.position)
      if request_proxy then
        request_proxy.destroy{raise_destroy = true}
      end
    end
  end
end

local function on_player_alt_reverse_selected_area(event)
  local selection_tool = event.item
  local prefix = selection_tool:sub(1, 11)
  if prefix == "mis-insert-" then
    for _, entity in pairs(event.entities) do
      request_proxy = entity.surface.find_entity("item-request-proxy", entity.position)
      if request_proxy then
        -- Remove one request
        local requests = request_proxy.item_requests
        local item, count = next(requests)
        if item and count > 0 then
          if count > 1 then
            requests[item] = count - 1
          else
            requests[item] = nil
          end
          request_proxy.item_requests = requests
        end
      end
    end
  end
end


InsertModule.events = {
  [defines.events.on_object_destroyed] = on_object_destroyed,
  [defines.events.on_player_selected_area] = function(event) insert_modules(event) end,
  [defines.events.on_player_reverse_selected_area] = function(event) insert_modules(event, true) end,
  [defines.events.on_player_alt_selected_area] = on_player_alt_selected_area,
  [defines.events.on_player_alt_reverse_selected_area] = on_player_alt_reverse_selected_area,
}

return InsertModule