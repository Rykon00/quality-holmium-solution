-- Existing saves: forces that already have the vanilla holmium solution recipe get the new
-- quality recipes too (technology effects are not re-applied when a mod is added).
local PREFIX = "qhs-holmium-solution-"

local function sync_force(force)
  local base = force.recipes["holmium-solution"]
  if not (base and base.enabled) then return end
  for name, recipe in pairs(force.recipes) do
    if name:sub(1, #PREFIX) == PREFIX then recipe.enabled = true end
  end
end

local function sync_all()
  for _, force in pairs(game.forces) do sync_force(force) end
end

script.on_init(sync_all)
script.on_configuration_changed(sync_all)
