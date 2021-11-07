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
compatibility         - correct interaction with another mods.
- apply               - make compatible with known mods
- warn                - warns about known mods combination what can`t be used
control.lua           - *
data-updates.lua      - *
media                 - used pictures
settings.lua          - *
lib                   - ?
migrations            - *
data-final-fixes.lua  - *
prototypes            - mod prototypes grouped by they type. They included in data.lua file
settings-updates.lua  - *
locale                - *
tutorials             - *
scripts               - ?
```