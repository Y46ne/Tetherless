# Straft Tat - Refactored Architecture

## Overview

This project has been refactored using a **strict layered architecture** to maximize scalability, modularity, and maintainability. The codebase is organized into four main layers:

1. **Config Layer** - Data & Constants
2. **Service Layer** - Server-side authority
3. **Controller Layer** - Client-side logic
4. **Utility Layer** - Shared helpers

---

## Directory Structure

```
ReplicatedStorage/
  ├── Modules/
  │   ├── Class.luau
  │   ├── FastCast.luau
  │   ├── Signal.luau
  │   └── Tween.luau
  ├── Shared/
  │   ├── Configs/
  │   │   ├── AnimationIDs.luau
  │   │   ├── AudioIDs.luau
  │   │   ├── BulletsConfig.luau
  │   │   ├── Enums.luau
  │   │   ├── GameConstants.luau
  │   │   ├── MovementConfig.luau
  │   │   ├── UIConstants.luau
  │   │   └── WeaponConfig.luau
  │   ├── EventBus/
  │   │   └── EventBus.luau (centralized signal bus)
  │   ├── Utils/
  │   │   ├── MathUtils.luau
  │   │   ├── RaycastUtils.luau
  │   │   └── TweenHelpers.luau
  │   └── (Legacy proxies)
  │       ├── WeaponState.luau
  │       ├── WeaponData.luau (proxies to WeaponConfig)
  │       └── BulletsData.luau (proxies to BulletsConfig)

ServerScriptService/
  ├── Networking/
  │   ├── RemoteAPI.legacy.luau
  │   ├── ServerNetwork.luau (NEW: centralized server broadcasts)
  │   └── ServerLoader.legacy.luau
  ├── Services/
  │   ├── MatchManager.luau
  │   ├── DamageService.luau
  │   ├── DamageLogService.luau
  │   ├── DropService.luau
  │   ├── KillFeedService.luau
  │   ├── RagdollService.luau
  │   └── WeaponSpawnerService.luau

StarterPlayerScripts/
  ├── ClientLoader.local.luau
  ├── Controllers/
  │   ├── AnimationController.luau (reusable animation track manager)
  │   ├── AnimationsStorage.luau (proxies to AnimationIDs config)
  │   ├── InputController.local.luau (NEW: centralized input handling)
  │   ├── MovementController.local.luau (uses InputController events)
  │   ├── ViewmodelController.local.luau (uses UIConstants)
  │   └── WeaponController.local.luau (uses InputController events)

StarterCharacterScripts/
  ├── Health.local.luau
  └── CharacterSetup.local.luau
```

---

## Layer Descriptions

### 1. Config Layer (`ReplicatedStorage/Shared/Configs/*`)

**Purpose:** Single source of truth for all tunable values.

**Files:**
- `MovementConfig.luau` - Walk/sprint speeds, slide physics, bhop, wall run parameters
- `WeaponConfig.luau` - Weapon stats, fire rates, recoil, spread
- `BulletsConfig.luau` - Ammo types, damage, range, headshot multipliers
- `UIConstants.luau` - Viewmodel sway/bob, timing values, UI paths
- `AnimationIDs.luau` - Animation AssetIDs
- `AudioIDs.luau` - Sound AssetIDs
- `Enums.luau` - Team, weapon category enums
- `GameConstants.luau` - Max players, round time
- `MapRegistry.luau` - Map spawn points, boundaries

**Rule:** If a number is hardcoded in any script, it should move here.

---

### 2. Service Layer (`ServerScriptService/Services/*`)

**Purpose:** Server-side authority and game state management. **Never references UI, sounds, or client-side code.**

**Key Services:**
- `MatchManager.luau` - Round/match state machine, player spawning, win conditions
- `CombatService.luau` (formerly `DamageService.luau`) - Damage validation, hit resolution
- `DamageLogService.luau` - Damage history per player
- `DropService.luau` - Weapon dropping and pickup mechanics
- `KillFeedService.luau` - Broadcast kill events to UI
- `WeaponSpawnerService.luau` - Weapon spawn points and respawn timers
- `RagdollService.luau` - Ragdoll physics on death

**Networking via `ServerNetwork.luau`:**
- Centralizes all server→client broadcasts
- Example: `ServerNetwork.BroadcastMatchStatus(statusText, timerValue)`

---

### 3. Controller Layer (`StarterPlayerScripts/Controllers/*`)

**Purpose:** Client-side input, rendering, and UI. Controllers communicate via `EventBus` signals to avoid spaghetti dependencies.

**Key Controllers:**
- `InputController.local.luau` - **NEW**: Centralized input. Emits signals for `SprintToggle`, `SlidePressed`, `JumpPressed`, `FireLeft`, `FireRight`, `TossWeapon`
- `MovementController.local.luau` - Listens to InputController; handles player movement, wall runs, slides
- `WeaponController.local.luau` - Listens to InputController; manages weapon firing, ammo sync
- `ViewmodelController.local.luau` - Renders first-person arms and weapons; syncs with WeaponController
- `AnimationController.luau` - Reusable animation track caching/playback

**EventBus Pattern:**
```lua
local EventBus = require(shared:WaitForChild("EventBus"):WaitForChild("EventBus"))
local moveEvent = EventBus.Get("Input:Movement")
moveEvent:Connect(function(direction) ... end)
```

---

### 4. Utility Layer (`ReplicatedStorage/Shared/Utils/*` & `ReplicatedStorage/Modules/*`)

**Purpose:** Reusable, stateless helper functions.

**Shared Utils:**
- `MathUtils.luau` - clamp, lerp, safeUnit
- `RaycastUtils.luau` - Raycast wrapper with filter params
- `TweenHelpers.luau` - Tween creation helper

**Low-Level Modules (Kept in ReplicatedStorage/Modules):**
- `Signal.luau` - Event signal implementation (used by EventBus)
- `Tween.luau` - Legacy tween manager
- `FastCast.luau` - Projectile physics
- `Class.luau` - OOP helpers

---

## Architecture Rules & Best Practices

### ✅ DO:

1. **Extract hardcoded values to Configs**
   ```lua
   -- BAD
   local speed = 25
   
   -- GOOD
   local config = require(configs:WaitForChild("MovementConfig"))
   local speed = config.SprintSpeed
   ```

2. **Use Utils for common operations**
   ```lua
   local RaycastUtils = require(utilsFolder:WaitForChild("RaycastUtils"))
   local hit = RaycastUtils.Raycast(origin, direction, {player.Character})
   ```

3. **Decouple via EventBus signals**
   ```lua
   local inputEvents = InputController.GetEvents()
   inputEvents.FireRight:Connect(function() ... end)
   ```

4. **Keep services pure (no UI/sound calls)**
   ```lua
   -- Server services should only:
   -- - Validate game logic
   -- - Update character attributes
   -- - Fire RemoteEvents to notify clients
   ```

5. **Group remote events by domain**
   ```lua
   ServerNetwork.BroadcastMatchStatus(...)
   hitmarkerEvent:FireClient(...)
   killFeedEvent:FireAllClients(...)
   ```

### ❌ DON'T:

1. ❌ Hardcode magic numbers in scripts
2. ❌ Have services call client methods or reference UI
3. ❌ Have controllers directly require other controllers (use EventBus instead)
4. ❌ Create circular dependencies (A → B → A)
5. ❌ Mix movement, weapon, and input logic in one controller

---

## How To: Add a New Weapon

### Step 1: Define weapon stats in `Configs/WeaponConfig.luau`

```lua
NewWeapon = {
    DisplayName = "New Weapon",
    FireRate = 0.15,
    AmmoType = BulletsData["9mm"],
    Magazine = 20,
    RecoilX = 10,
    RecoilY = 5,
    Spread = 2.5,
    SpreadIncrease = 1.2,
    SpreadDecay = 18,
    Model = "rbxassetid://...",
    Sound_Fire = "rbxassetid://...",
    Icon = "rbxassetid://...",
    Category = "Rifle",
    DualWieldable = true,
}
```

### Step 2: Add weapon model to `ReplicatedStorage/Assets/Weapons/`

Place a model named `NewWeapon` with a PrimaryPart (the root) and optional `Muzzle` part.

### Step 3: Add animation (if needed) to `Configs/AnimationIDs.luau`

```lua
["NewWeaponFire"] = {
    id = 'rbxassetid://...'
}
```

### Step 4: Create a spawn point in workspace

Add a part named `NewWeapon` in `workspace/WeaponSpawns/`. The system will automatically create spawners.

**Done!** No changes needed to controllers or services.

---

## How To: Tweak Movement Physics

All movement values are in `Configs/MovementConfig.luau`. Examples:

```lua
-- Faster base movement
WalkSpeed = 20  -- was 18

-- Tighter slide
SlidePower = 140
SlideDuration = 0.9

-- Higher bhop rewards
MaxBhopBoost = 60  -- was 50

-- Wall run adjustments
WallRunBaseSpeed = 40  -- was 35
```

**Restart the game to apply changes.** No code modifications needed.

---

## How To: Customize UI Viewmodel

All viewmodel settings are in `Configs/UIConstants.luau`:

```lua
ViewmodelSwayAmount = 0.08  -- More sway
ViewmodelBobIntensity = 0.08  -- Bouncier bob
ViewmodelBaseOffset = CFrame.new(0, -1.2, -0.3)  -- Reposition weapon
```

---

## Communication Patterns

### Client → Server (Remote Events)

```lua
shootEvent:FireServer(origin, direction, weaponName)
dropWeaponEvent:FireServer("DropLeft", lookDir, ammoToDrop)
```

### Server → Client (Remote Events)

```lua
ServerNetwork.BroadcastMatchStatus(statusText, timerValue)
hitmarkerEvent:FireClient(player, isHeadshot)
killFeedEvent:FireAllClients(victim, killer, weapon, isTrickshot)
```

### Client ↔ Client (EventBus Signals)

```lua
local InputEvents = InputController.GetEvents()
InputEvents.FireRight:Connect(function() ... end)
```

---

## Testing Checklist

- [ ] All configs load without errors
- [ ] Movement feels responsive (no input lag)
- [ ] Weapons fire and deal damage correctly
- [ ] Viewmodel sway/bob is smooth
- [ ] Wall running works on both sides
- [ ] Sliding momentum carries forward
- [ ] Dual-wielding guns works
- [ ] Weapon dropping and picking up works
- [ ] Kill feed displays correctly
- [ ] Match state transitions smoothly

---

## Future Improvements

1. **Type Annotations** - Add Luau type hints to all modules
2. **Enum Patterns** - Replace string-based states with typed enums
3. **Service Locator** - Centralized service registration (avoid hardcoded requires)
4. **Input Rebinding** - Allow players to customize key binds
5. **State Machines** - Use explicit state machines for complex logic (MatchManager, movement)
6. **Unit Tests** - Test damage calculations, spawn logic, physics
7. **Performance Profiling** - Monitor render times and network traffic

---

## Questions?

Refer to the specific config file or controller for implementation details. Each file should have clear variable names and comments.
