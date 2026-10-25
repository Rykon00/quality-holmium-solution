data:extend({
  {
    -- Extra holmium solution per quality level of the ore, in percent of the vanilla output.
    -- Level = the quality's "level" (uncommon 1, rare 2, epic 3, legendary 5).
    type = "int-setting",
    name = "qhs-bonus-per-level",
    setting_type = "startup",
    default_value = 50,
    minimum_value = 0,
    maximum_value = 1000,
    order = "a",
  },
  {
    -- Vanilla recipe only accepts normal ingredients, so quality ore is not used up there by accident.
    type = "bool-setting",
    name = "qhs-lock-vanilla-to-normal",
    setting_type = "startup",
    default_value = true,
    order = "b",
  },
})
