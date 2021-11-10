# Structure of project

## Root directory


## `Src` directory

All standard mod files market by `*`. About them, you can read in [Factorio Wiki](https://wiki.factorio.com/Tutorial:Mod_structure)

```
info.json             - *
thumbnail.png         - *
changelog.txt         - *
data.lua              - *
LICENSE.md            - *
extra
- compatibility       - correct interaction with another mods.
-- apply              - make compatible with known mods
-- warn               - warns about known mods combination what can`t be used
- prototypes          - mod prototypes grouped by they type. They included in data.lua file
control.lua           - *
data-updates.lua      - *
media                 - used pictures
settings.lua          - *
lib                   - ?
migrations            - *
data-final-fixes.lua  - *
settings-updates.lua  - *
locale                - *
tutorials             - *
scripts               - ?
```