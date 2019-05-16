## AutoBurst Windower Addon
### Automatically Bursts when it reads a SKILLCHAIN packet

---

#### SET UP

Place the Folder AutoBurst inside the Windower/Addons/ directory should look similar too

```
Windower/
     Addons/
          AutoBurst
               AutoBurst.lua
```

Now before loading, you must make a simple change to the LUA, this will be updated to include commands and by the time you use this, this may already be implemented. 

Open the AutoBurst.lua file inside of either a coding program or a notepad program, you'll be looking for the area markey USERS SETTINGS when you find this area you'll want to edite the AssistedPlayer variable this is as simple as placing the characters name between the "'s, for example.

```
local AssistedPlayer = "JohnDoe"
```

Advanced users can also change the element to be used with skillchains and the tier order. See more info below.

Then while in game type in the In Game text box:
***//lua load AutoBurst***

alternatively you can type 
***lua load AutoBurst***
into the Windower Console Window.

With this done the addon should not be ready to work, simply begin skillchaining and 2 seconds after the chain your character wil begin bursting. Please note only the following jobs will burst: RDM, BLM, SCH, or GEO, going forward I'll extend this list.


#### ADVANCED SET UP
Advanced setup allows you to edit Elements to burst with and tiers. Under User Settings in the LUA the additional customizable options are

```
burstMagic = {
  -- LEVEL 3  and 4
  ["radiance"] = "Thunder",
  ["light"] = "Thunder",
  ["umbra"] = "Blizzard",
  ["darkness"] = "Blizzard",
  -- LEVEL 2
  ["gravitation"] = "Stone",
  ["fragmentation"] = "Thunder",
  ["distortion"] = "Blizzard",
  ["fusion"] = "Fire",
  -- LEVEL 1
  ["compression"] = "Aspir",
  ["liquefaction"] = "Fire",
  ["induration"] = "Blizzard",
  ["reverberation"] = "Water",
  ["transfixion"] = "Banish",
  ["scission"] = "Stone",
  ["detonation"] = "Aero",
  ["impaction"] = "Thunder",
}

tierOrder = {
  [1] = "VI",
  [2] = "V",
  [3] = "IV",
  [4] = "III",
  [5] = "II",
  [6] = "I",
}
```

To edit elements simply change the current element to a different one, for example.

```
["radiance"] = "Fire",
```

To edit Tiers, simply change the tier number, for example.

```
  [4] = "VI",
  [3] = "V",
  [2] = "IV",
  [1] = "III",
  [5] = "II",
  [6] = "I",
```




