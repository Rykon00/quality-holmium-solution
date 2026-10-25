-- Functional test for quality-holmium-solution, run by tools/load_check.py --test-mod tests/functional-test.
-- Places powered chemical plants with each recipe, feeds them ore of a given quality and checks the
-- holmium solution produced after two crafts. Writes "[functional-test] PASS|FAIL ..." and ends with DONE.

local TAG = "[functional-test] "
local START = 10
local CHECK = START + 1500 -- 10 s recipe -> two crafts after 1200 ticks at crafting speed 1

local function pass(msg) log(TAG .. "PASS " .. msg) end
local function fail(msg) log(TAG .. "FAIL " .. msg) end

-- Expected per craft with the default setting (+50% per quality level).
local function expected_per_craft(quality)
  local base = prototypes.recipe["holmium-solution"].products[1].amount
  local level = prototypes.quality[quality].level
  local bonus = settings.startup["qhs-bonus-per-level"].value / 100
  return base * (1 + level * bonus)
end

local cases = {}

local function setup()
  if not script.active_mods["space-age"] then
    pass("skipped: needs Space Age")
    log(TAG .. "DONE")
    return
  end
  local surface = game.surfaces[1]
  local force = game.forces.player
  force.technologies["holmium-processing"].researched = true

  for _, name in pairs({"holmium-solution", "qhs-holmium-solution-uncommon", "qhs-holmium-solution-rare",
                        "qhs-holmium-solution-epic", "qhs-holmium-solution-legendary"}) do
    local r = force.recipes[name]
    if not r then fail("recipe " .. name .. " missing")
    elseif not r.enabled then fail("recipe " .. name .. " not unlocked by holmium-processing")
    elseif r.prototype.can_set_quality then fail("recipe " .. name .. " still has a quality selector")
    else pass("recipe " .. name .. " unlocked, fixed ingredient qualities") end
  end

  local eei = surface.create_entity{name = "electric-energy-interface", position = {-30, -6}, force = force}
  eei.electric_buffer_size = 1e10
  eei.power_production = 1e9
  eei.energy = 1e10

  local list = {
    {recipe = "holmium-solution", quality = "normal", crafts = true},
    {recipe = "qhs-holmium-solution-uncommon", quality = "uncommon", crafts = true},
    {recipe = "qhs-holmium-solution-rare", quality = "rare", crafts = true},
    {recipe = "qhs-holmium-solution-epic", quality = "epic", crafts = true},
    {recipe = "qhs-holmium-solution-legendary", quality = "legendary", crafts = true},
    {recipe = "qhs-holmium-solution-rare", quality = "normal", crafts = false},
    {recipe = "holmium-solution", quality = "rare", crafts = false},
  }
  for i, c in ipairs(list) do
    local x = -30 + i * 5
    surface.create_entity{name = "substation", position = {x + 2, 3}, force = force}
    local plant = surface.create_entity{name = "chemical-plant", position = {x, 0}, force = force}
    plant.set_recipe(c.recipe)
    c.inserted = plant.insert{name = "holmium-ore", count = 4, quality = c.quality}
    plant.insert{name = "stone", count = 2}
    plant.insert_fluid{name = "water", amount = 20}
    c.plant = plant
    cases[#cases + 1] = c
  end
end

local function check()
  for _, c in ipairs(cases) do
    local label = c.recipe .. " with " .. c.quality .. " ore"
    local amount = c.plant.get_fluid_count("holmium-solution")
    if c.crafts then
      local want = expected_per_craft(c.quality) * 2
      if c.inserted ~= 4 then fail(label .. ": could not insert the ore (" .. c.inserted .. ")")
      elseif math.abs(amount - want) > 0.01 then
        fail(string.format("%s: %.1f holmium solution, expected %.1f (crafts: %d)", label, amount, want, c.plant.products_finished))
      else pass(string.format("%s: %.1f holmium solution", label, amount)) end
    else
      if c.inserted ~= 0 or amount > 0 then
        fail(string.format("%s: accepted %d ore, made %.1f solution, expected neither", label, c.inserted, amount))
      else pass(label .. ": ore rejected") end
    end
  end
  log(TAG .. "DONE")
end

script.on_nth_tick(START, function(e)
  if e.tick == START then setup() end
end)
script.on_nth_tick(CHECK, function(e)
  if e.tick == CHECK and #cases > 0 then check() end
end)
