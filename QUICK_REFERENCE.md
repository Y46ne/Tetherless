# Quick Reference: Configuration & Customization

## 🎯 Adding a New Weapon (5 Steps)

### Step 1: Define Stats
Edit `ReplicatedStorage/Shared/Configs/WeaponConfig.luau`:

```lua
YourNewWeapon = {
    DisplayName = "Awesome Gun",
    FireRate = 0.12,                          -- Seconds between shots
    AmmoType = BulletsData["9mm"],            -- Reference existing ammo type
    Magazine = 25,                            -- Shots per magazine
    RecoilX = 8,                              -- Horizontal recoil
    RecoilY = 3,                              -- Vertical recoil
    Spread = 2.5,                             -- Initial spread (degrees)
    SpreadIncrease = 1.5,                     -- Spread growth per shot
    SpreadDecay = 18,                         -- Spread recovery per second
    Model = "rbxassetid://YOUR_MODEL_ID",    -- Model in Assets/Weapons
    Sound_Fire = "rbxassetid://YOUR_SOUND",  -- Fire sound
    Icon = "rbxassetid://YOUR_ICON",         -- UI icon
    Category = "Rifle",                       -- For grouping
    DualWieldable = true,                     -- Can akimbo?
}
```

### Step 2: Create Weapon Model
1. Build/import your weapon model in Roblox Studio
2. **IMPORTANT:** Set the PrimaryPart (usually the barrel or grip)
3. Add a part named `Muzzle` at the barrel tip (optional, for tracer/muzzle flash)
4. Place the entire model in `ReplicatedStorage/Assets/Weapons/YourNewWeapon`

### Step 3: Create Spawn Point
1. Create a Part in workspace called `WeaponSpawns`
2. Add a Part inside named `YourNewWeapon`
3. Position it where you want the weapon to spawn
4. The system will auto-create a spawn point there

### Step 4: (Optional) Add Animation
Edit `ReplicatedStorage/Shared/Configs/AnimationIDs.luau`:

```lua
["YourNewWeaponFire"] = {
    id = 'rbxassetid://YOUR_ANIM_ID'
}
```

### Step 5: Done!
That's it. Restart the game and your weapon will:
- Spawn at the location
- Fire when picked up
- Deal correct damage
- Show correct icon in UI

---

## ⚙️ Tweaking Movement

Edit `ReplicatedStorage/Shared/Configs/MovementConfig.luau`:

### Speed Settings
```lua
WalkSpeed = 18          -- Normal speed (default: 18)
SprintSpeed = 38        -- Sprint speed (default: 38)
WallRunBaseSpeed = 35   -- Wall run speed (default: 35)
```

### Slide Physics
```lua
SlidePower = 120        -- Initial slide force (default: 120)
SlideDuration = 1.0     -- How long slide lasts (default: 1.0)
```

### Bhop (Bunnyhopping)
```lua
BhopWindow = 0.2        -- Time window after landing to bhop (default: 0.2)
BhopAcceleration = 5    -- Speed gain per successful bhop (default: 5)
MaxBhopBoost = 50       -- Maximum speed boost from bhop (default: 50)
```

### Jump from Slide
```lua
SlideJumpForwardBoost = 90   -- Forward momentum (default: 90)
SlideJumpUpwardBoost = 40    -- Upward momentum (default: 40)
```

### Wall Run & Wall Jump
```lua
WallRunRayDistance = 2.5     -- How far to detect walls (default: 2.5)
WallJumpOutwardBoost = 80    -- Push away from wall (default: 80)
WallJumpUpwardBoost = 50     -- Push upward (default: 50)
```

### Camera & FOV
```lua
CameraDip = Vector3.new(0, -1.5, 0)  -- Camera offset when sliding
BaseFOV = 70                           -- Base field of view
MaxFOV = 110                           -- Max FOV when sprinting
FOVSpeedCap = 100                      -- Speed at which to reach max FOV
WallRunCameraTilt = -15                -- Camera tilt on wall run
```

**Save and restart the game to see changes immediately.**

---

## 🎮 Tweaking Weapon Balance

Edit `ReplicatedStorage/Shared/Configs/WeaponConfig.luau`:

### Fire Rate & Damage
```lua
-- Faster fire rate (less = faster)
FireRate = 0.08  -- was 0.1

-- More damage per shot
AmmoType = BulletsData["5.56mm"]
-- Then edit BulletsConfig:
-- Damage = 45  (was 35)
```

### Recoil (Aim Shake)
```lua
-- More recoil = harder to control
RecoilX = 12  -- was 8 (horizontal shake)
RecoilY = 5   -- was 3 (vertical shake)
```

### Spread (Accuracy)
```lua
Spread = 3             -- Initial spread in degrees (higher = less accurate)
SpreadIncrease = 2     -- Spread growth per shot (higher = bloom faster)
SpreadDecay = 15       -- Recovery speed (higher = resets faster)
```

### Magazine & Ammo
```lua
Magazine = 30                    -- Bullets per mag
AmmoType = BulletsData["5.56mm"] -- Damage/range via BulletsData
```

**Example: Make a sniper**
```lua
Sniper = {
    DisplayName = "Sniper Rifle",
    FireRate = 1.5,              -- Slow fire rate
    AmmoType = BulletsData["7.62mm"],  -- High damage ammo
    Magazine = 5,
    RecoilX = 20,
    RecoilY = 15,
    Spread = 0.5,                -- Very accurate
    SpreadIncrease = 0.1,
    SpreadDecay = 100,           -- Resets quickly
    Category = "Sniper",
    DualWieldable = false,
}
```

---

## 🎨 Tweaking Viewmodel (First-Person Arms)

Edit `ReplicatedStorage/Shared/Configs/UIConstants.luau`:

### Arm Sway (Mouse Movement)
```lua
ViewmodelSwayAmount = 0.05   -- How much sway (higher = more wobbly)
ViewmodelSwaySpeed = 8       -- Speed of sway (higher = snappier)
```

### Arm Bob (Movement)
```lua
ViewmodelBobSpeedMultiplier = 0.08  -- How fast bob cycles
ViewmodelBobIntensity = 0.05        -- How much arm bounces
```

### Arm Position
```lua
ViewmodelBaseOffset = CFrame.new(0, -1.5, -0.5)
-- x = left/right (-0.5 = centered, 0.5 = more right)
-- y = up/down (-1.5 = lower, -1.2 = higher)
-- z = forward/back (-0.5 = back, 0.2 = forward)
```

### Weapon Grip Offset
```lua
ViewmodelGripOffset = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), math.rad(90), math.rad(180))
-- Adjust rotation if your weapon model has different orientation
```

---

## 📊 Tweaking Game Constants

Edit `ReplicatedStorage/Shared/Configs/GameConstants.luau`:

```lua
MaxPlayers = 16      -- Max players per server
RoundTime = 300      -- Round duration in seconds (300 = 5 min)
```

---

## 🔊 Adding Sounds

1. Add sound asset IDs to `ReplicatedStorage/Shared/Configs/AudioIDs.luau`:
```lua
Weapons = {
    GenericFire = "rbxassetid://YOUR_SOUND_ID",
    MeleeSwing = "rbxassetid://YOUR_SOUND_ID",
}
```

2. Reference in your service:
```lua
local AudioIDs = require(configsFolder:WaitForChild("AudioIDs"))
local sound = Instance.new("Sound")
sound.SoundId = AudioIDs.Weapons.GenericFire
```

---

## 🎬 Adding Animations

1. Upload animation to Roblox (get the asset ID)
2. Add to `ReplicatedStorage/Shared/Configs/AnimationIDs.luau`:
```lua
["NewAnimation"] = {
    id = 'rbxassetid://YOUR_ANIMATION_ID'
}
```

3. Use in a controller:
```lua
local animationModule = require(script.Parent:WaitForChild("AnimationController"))
local animationStorageModule = require(script.Parent:WaitForChild("AnimationsStorage"))
animationModule.play(animator, animationStorageModule["NewAnimation"].id, Enum.AnimationPriority.Action)
```

---

## 🧪 Testing Your Changes

### After editing Configs:
1. ✅ Stop and restart the game
2. ✅ Check that the value appears in-game
3. ✅ Test gameplay to feel the changes

### Common Tests:
- **Movement:** Sprint, slide, bhop, wall run
- **Combat:** Fire all weapons, check damage, test dual wield
- **UI:** Kill feed shows, HUD updates, ammo syncs
- **Spawning:** Weapons spawn, players spawn, no duplicates

---

## ⚡ Pro Tips

- **Copy weapon stats** to rebalance faster:
  ```lua
  NerfedRifle = table.clone(WeaponConfig.Rifle)
  NerfedRifle.Damage = 25  -- was 35
  ```

- **Test extreme values** to find the sweet spot:
  ```lua
  -- Too slow? SprintSpeed = 100
  -- Too fast? SprintSpeed = 10
  -- Find middle ground
  ```

- **Use the same recoil pattern** for weapon families:
  ```lua
  -- All 9mm pistols
  RecoilX = 6, RecoilY = 2
  
  -- All rifles
  RecoilX = 10, RecoilY = 4
  ```

- **Backup your configs** before major changes:
  - Copy WeaponConfig.luau to WeaponConfig.backup.luau
  - Easy to revert if something breaks

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| New weapon doesn't spawn | Check spawn point name matches weapon name |
| Weapon deals wrong damage | Verify AmmoType is set correctly in WeaponConfig |
| Viewmodel looks bad | Adjust ViewmodelBaseOffset or ViewmodelGripOffset |
| Movement feels laggy | Reduce BhopAcceleration or increase BhopWindow |
| Can't pick up weapon | Ensure weapon model has PrimaryPart set |
| Animation doesn't play | Check AnimationIDs.luau has correct asset ID |

---

**For more details, see README.md and architecture documentation.**
