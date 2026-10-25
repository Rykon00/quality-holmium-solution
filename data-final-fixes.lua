-- Adds one holmium solution recipe per quality (uncommon and better). Each one only accepts
-- holmium ore of exactly that quality (Factorio 2.1 ingredient quality_min / quality_max) and
-- gives more holmium solution. Runs in data-final-fixes so changes other mods made to the
-- vanilla recipe (ingredients, categories, ...) are copied into the new recipes.

local BASE_RECIPE = "holmium-solution"
local ORE = "holmium-ore"
local FLUID = "holmium-solution"
local PREFIX = "qhs-holmium-solution-"

local base = data.raw.recipe[BASE_RECIPE]
if not base then
  log("[quality-holmium-solution] recipe " .. BASE_RECIPE .. " not found, nothing to do")
  return
end

local bonus = settings.startup["qhs-bonus-per-level"].value / 100
local lock_vanilla = settings.startup["qhs-lock-vanilla-to-normal"].value

-- Fix every item ingredient to one quality: the ore to `ore_quality`, everything else to normal.
-- With all item ingredients fixed the engine hides the quality selector (can_set_quality = false).
local function fix_ingredient_qualities(recipe, ore_quality)
  for _, ing in pairs(recipe.ingredients or {}) do
    if ing.type == "item" then
      local q = ing.name == ORE and ore_quality or "normal"
      ing.quality_min = q
      ing.quality_max = q
      ing.quality_change = nil
    end
  end
end

local function has_ore(recipe)
  for _, ing in pairs(recipe.ingredients or {}) do
    if ing.type == "item" and ing.name == ORE then return true end
  end
  return false
end

if not has_ore(base) then
  log("[quality-holmium-solution] " .. BASE_RECIPE .. " has no " .. ORE .. " ingredient, nothing to do")
  return
end

-- Icon layers of the fluid (works for both `icon` and `icons`).
local function fluid_icons()
  local fluid = data.raw.fluid[FLUID]
  if fluid and fluid.icons then return table.deepcopy(fluid.icons) end
  if fluid and fluid.icon then return {{icon = fluid.icon, icon_size = fluid.icon_size or 64}} end
  return {{icon = "__space-age__/graphics/icons/fluid/holmium-solution.png", icon_size = 64}}
end

-- Qualities to generate: every visible quality above normal, in level order.
local qualities = {}
for name, q in pairs(data.raw.quality) do
  if name ~= "normal" and not q.hidden and (q.level or 0) > 0 then
    qualities[#qualities + 1] = q
  end
end
table.sort(qualities, function(a, b)
  if a.level ~= b.level then return a.level < b.level end
  return a.name < b.name
end)

local new_recipes = {}
for _, q in ipairs(qualities) do
  local r = table.deepcopy(base)
  r.name = PREFIX .. q.name
  fix_ingredient_qualities(r, q.name)

  local factor = 1 + q.level * bonus
  for _, res in pairs(r.results or {}) do
    if res.type == "fluid" and res.name == FLUID then
      if res.amount then res.amount = res.amount * factor end
      if res.amount_min then res.amount_min = res.amount_min * factor end
      if res.amount_max then res.amount_max = res.amount_max * factor end
    end
  end

  local icons = fluid_icons()
  if q.icon or q.icons then
    local qi = q.icons and q.icons[1] or {icon = q.icon, icon_size = q.icon_size or 64}
    icons[#icons + 1] = {icon = qi.icon, icon_size = qi.icon_size or 64, scale = 0.25, shift = {-8, 8}}
  end
  r.icons = icons
  r.icon = nil
  r.icon_size = nil

  r.localised_name = {"recipe-name.qhs-holmium-solution", {"quality-name." .. q.name}}
  r.localised_description = {"recipe-description.qhs-holmium-solution",
    {"quality-name." .. q.name}, tostring(math.floor(factor * 100 + 0.5))}
  r.order = (base.order or "b[holmium]-b[holmium-solution]") .. "-" .. string.format("%03d", q.level) .. "-" .. q.name
  r.main_product = FLUID
  r.auto_recycle = false
  r.can_set_quality = false

  new_recipes[#new_recipes + 1] = r
  log(string.format("[quality-holmium-solution] %s: %s holmium ore, x%.2f holmium solution", r.name, q.name, factor))
end

if #new_recipes > 0 then data:extend(new_recipes) end

if lock_vanilla then
  fix_ingredient_qualities(base, "normal")
  base.can_set_quality = false
end

-- Unlock the new recipes together with the vanilla one (holmium-processing).
for _, tech in pairs(data.raw.technology) do
  local effects = tech.effects
  if effects then
    for _, e in pairs(effects) do
      if e.type == "unlock-recipe" and e.recipe == BASE_RECIPE then
        for _, r in ipairs(new_recipes) do
          effects[#effects + 1] = {type = "unlock-recipe", recipe = r.name}
        end
        break
      end
    end
  end
end
