# Quality Holmium Solution

Higher quality holmium ore gives more holmium solution. No new buildings: the mod adds
one holmium solution recipe per quality to the chemical plant (same crafting categories
as the vanilla recipe).

Each new recipe only accepts holmium ore of exactly its quality (Factorio 2.1 ingredient
`quality_min` / `quality_max`), so ore of the wrong quality is never used up for the
wrong amount. All other item ingredients (stone) must be normal quality.

## Output

Default (`50%` extra per quality level, vanilla recipe: 2 ore + 1 stone + 10 water -> 100 solution):

| Ore quality | Level | Holmium solution per craft |
|---|---|---|
| Normal (vanilla recipe) | 0 | 100 |
| Uncommon | 1 | 150 |
| Rare | 2 | 200 |
| Epic | 3 | 250 |
| Legendary | 5 | 350 |

Qualities added by other mods get a recipe too (every visible quality with level > 0).
Productivity bonuses apply on top, like for the vanilla recipe.

## Settings (startup)

| Setting | Default | |
|---|---|---|
| `qhs-bonus-per-level` | 50 | Extra output per quality level of the ore, in percent of the vanilla amount. |
| `qhs-lock-vanilla-to-normal` | on | The vanilla recipe only accepts normal ingredients, so quality ore cannot end up there for 100 solution. |

## How it works

- `data-final-fixes.lua` copies the vanilla `holmium-solution` recipe (including changes other mods
  made to it) once per quality as `qhs-holmium-solution-<quality>`, fixes the ingredient qualities and
  scales the holmium solution result. The recipes are unlocked by every technology that unlocks the
  vanilla recipe (vanilla: Holmium processing).
- `control.lua` enables the new recipes in existing saves for forces that already have the vanilla recipe.

## Compatibility

Requires Factorio 2.1, Space Age and Quality.

## Build

```
python tools/build.py   # -> dist/quality-holmium-solution_<version>.zip
```
