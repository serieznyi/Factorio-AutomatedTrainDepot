# ATD - Automated Train Depot

Add train depot what support automatically deploy new trains in train system

Forum: https://forums.factorio.com/viewforum.php?f=<SOME_IDENTIFIER>

Download: https://mods.factorio.com/mods/serieznyi/AutomatedTrainDepo

## Required

 - Lua ^5.2.1

## Other
- [Lua Code Style](https://github.com/luarocks/lua-style-guide)
- [Structure of project](docs/project-structure.md)
- Useful links
    - [Factorio API](https://lua-api.factorio.com/latest/index.html)
    - [FLib API](https://factoriolib.github.io/flib/index.html)
    - [Factorio Modding Tutorial](https://wiki.factorio.com/Tutorial:Modding_tutorial)
    - GUI
      - [FLib GUI Style](https://github.com/factoriolib/flib/blob/master/docs/gui-styles.md) 
      - [GUI Guide](https://github.com/ClaudeMetz/UntitledGuiGuide/wiki)
      - [GUI Style Guide](https://github.com/raiguard/Factorio-SmallMods/wiki/GUI-Style-Guide)

## Lua check (Local)

Download check file 

```bash
curl -s -o .luacheckrc https://raw.githubusercontent.com/Nexela/Factorio-luacheckrc/0.17/.luacheckrc
```

```bash
luacheck -q ./src
```


## Thanks for

Some code project ideas from https://github.com/raiguard mods