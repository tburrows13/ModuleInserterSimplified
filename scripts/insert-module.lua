local InsertModule = {}

local function on_entity_destroyed(event)
  local entity = global.proxy_targets[event.registration_number]
  if not (entity and entity.valid) then return end
  global.proxy_targets[event.registration_number] = nil

  local module_inventory = entity.get_module_inventory()
  if not module_inventory then return end
  module_inventory.sort_and_merge()
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
  local allowed_with_recipe = global.allowed_with_recipe[module]
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
  local allowed_in_entity = global.allowed_in_entity[module]
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

local function insert_into_entity(module, entity, player, surface)
  if not check_module_allowed(module, entity, player) then return end

  if entity.type == "entity-ghost" then
    local space_in_inv = entity.ghost_prototype.module_inventory_size
    if space_in_inv and space_in_inv > 0 then
      if module == "remove-modules" then
        entity.item_requests = {}
      else
        script.raise_event(on_module_inserted, {modules = {[module] = space_in_inv}, player = player, entity = entity})
        entity.item_requests = {[module] = space_in_inv}
      end
    end
    return
  end

  local request_proxy = entity.surface.find_entity("item-request-proxy", entity.position)
  if request_proxy then
    request_proxy.destroy{raise_destroy = true}
  end

  local module_inventory = entity.get_module_inventory()
  if not module_inventory then return end
  local count = #module_inventory
  if count == 0 then return end

  for i = 1, count do
    local module_stack = module_inventory[i]
    if module_stack and module_stack.valid_for_read then
      if module_stack.name == module then
        count = count - 1
      else
        local spilled = surface.spill_item_stack(entity.bounding_box.left_top, module_stack, true, player.force, false)
        if spilled[1] then module_stack.clear() end
      end
    end
  end
  if count == 0 or module == "remove-modules" then
    return
  end
  script.raise_event(on_module_inserted, {modules = {[module] = count}, player = player, entity = entity})
  request_proxy = surface.create_entity{
    name = "item-request-proxy",
    position = entity.position,
    force = entity.force,
    player = player,
    target = entity,
    modules = {[module] = count},
    raise_built = true
  }
  if request_proxy then
    global.proxy_targets[script.register_on_entity_destroyed(request_proxy)] = entity
  end

end

local function insert_single_into_entity(module, entity, player, surface, allowed_with_recipe)
  if not check_module_allowed(module, entity, player) then return end

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
          if spilled[1] then
            module_stack.clear()
            break
          end
        end
      end
    end
    return
  end

  if entity.type == "entity-ghost" then
    local space_in_inv = entity.ghost_prototype.module_inventory_size
    if not space_in_inv or space_in_inv == 0 then return end

    local requests = entity.item_requests

    if requests[module] and requests[module] >= space_in_inv then
      -- Already full with the correct module, so cut down to what actually fits
      entity.item_requests = {[module] = space_in_inv}
      return
    end

    -- Reduce requests so that there is space for at least one module
    local request_count = 0
    for _, count in pairs(requests) do
      request_count = request_count + count
    end
    local space_in_req = space_in_inv - request_count  -- Can be negative
    if space_in_req <= 0 then
      -- Remove requests until request_count < space_in_inv
      local diff = space_in_req + 1
      for name, count in pairs(requests) do
        if name ~= module then
          local to_subtract = math.min(diff, count)
          requests[name] = count - to_subtract
          diff = diff - to_subtract
          request_count = request_count - to_subtract
          if requests[name] < 0 then error() end
          if requests[name] == 0 then requests[name] = nil end
          if diff == 0 then break end
        end
      end
    end
    requests[module] = requests[module] and requests[module] + 1 or 1
    script.raise_event(on_module_inserted, {modules = {[module] = 1}, player = player, entity = entity})
    entity.item_requests = requests
    return
  end

  local request_proxy = entity.surface.find_entity("item-request-proxy", entity.position)
  local requests = request_proxy and request_proxy.item_requests or {}
  local module_inventory = entity.get_module_inventory()
  local inventory_size = #module_inventory
  if inventory_size == 0 then return end

  -- (1) If inventory is full of 'module', return
  -- (2) If inventory does not have a space, then make a space
  -- (3) If request does not have a space, then make a space
  -- (4) Create or update request proxy, request one

  local modules_in_inventory = module_inventory.get_item_count(module)
  if modules_in_inventory == inventory_size then return end

  -- Ensure there is space for at least one module
  local space_in_inv = module_inventory.count_empty_stacks()
  if space_in_inv == 0 then
    for i = 1, inventory_size do
      local module_stack = module_inventory[i]
      if module_stack and module_stack.valid_for_read then
        if module_stack.name ~= module then
          local spilled = surface.spill_item_stack(entity.bounding_box.left_top, module_stack, true, player.force, false)
          if spilled[1] then module_stack.clear()
            space_in_inv = 1
            break
          end
        end
      end
    end
    if space_in_inv == 0 then return end
  end

  -- Reduce requests so that there is space for at least one module
  local request_count = 0
  for _, count in pairs(requests) do
    request_count = request_count + count
  end
  local space_in_req = space_in_inv - request_count  -- Can be negative
  if space_in_req <= 0 then
    -- Remove requests until request_count < space_in_inv
    local diff = space_in_req + 1
    for name, count in pairs(requests) do
      if name ~= module then
        local to_subtract = math.min(diff, count)
        requests[name] = count - to_subtract
        diff = diff - to_subtract
        request_count = request_count - to_subtract
        if requests[name] < 0 then error() end
        if requests[name] == 0 then requests[name] = nil end
        if diff == 0 then break end
      end
    end

    if request_count >= space_in_inv then
      -- All requests are of `module`. Try removing a different module item
      for i = 1, inventory_size do
        local module_stack = module_inventory[i]
        if module_stack and module_stack.valid_for_read then
          if module_stack.name ~= module then
            local spilled = surface.spill_item_stack(entity.bounding_box.left_top, module_stack, true, player.force, false)
            if spilled[1] then
              module_stack.clear()
              space_in_inv = space_in_inv + 1
              break
            end
          end
        end
      end
      if request_count >= space_in_inv then
        -- Must be `module`
        requests[module] = requests[module] - math.min(diff, requests[module])
      end
    end
  end

  -- Add single request
  if request_proxy then
    requests[module] = requests[module] and requests[module] + 1 or 1
    script.raise_event(on_module_inserted, {modules = {[module] = 1}, player = player, entity = entity})
    request_proxy.item_requests = requests
  else
    script.raise_event(on_module_inserted, {modules = {[module] = 1}, player = player, entity = entity})
    request_proxy = surface.create_entity{
      name = "item-request-proxy",
      position = entity.position,
      force = entity.force,
      player = player,
      target = entity,
      modules = {[module] = 1},
      raise_built = true
    }
    if request_proxy then
      global.proxy_targets[script.register_on_entity_destroyed(request_proxy)] = entity
    end
  end
end

local function insert_modules(event, insert_single)
  local selection_tool = event.item
  local prefix = selection_tool:sub(1, 11)
  local item = selection_tool:sub(12)
  if prefix == "mis-insert-" then
    local player = game.get_player(event.player_index)
    local surface = event.surface

    for _, entity in pairs(event.entities) do
      if insert_single then
        insert_single_into_entity(item, entity, player, surface)
      else
        insert_into_entity(item, entity, player, surface)
      end
    end
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
  [defines.events.on_entity_destroyed] = on_entity_destroyed,
  [defines.events.on_player_selected_area] = function(event) insert_modules(event) end,
  [defines.events.on_player_reverse_selected_area] = function(event) insert_modules(event, true) end,
  [defines.events.on_player_alt_selected_area] = on_player_alt_selected_area,
  [defines.events.on_player_alt_reverse_selected_area] = on_player_alt_reverse_selected_area,
}

return InsertModule