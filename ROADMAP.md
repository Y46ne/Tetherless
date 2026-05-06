# STRAFTAT-Inspired Game — Detailed Roadmap

This document expands the earlier high-level suggestions into a detailed, implementable roadmap tailored for the existing Roblox Luau codebase. Each feature includes: concept, tech/tools, architecture (server/client), required config/data, incremental implementation steps (MVP → polish), estimated effort (1 dev), tests, risks, and proposed file/module targets.

---

**How to use this roadmap**
- Pick a Phase (Phase 0..Phase 3). Implement items in order within a Phase. Use the `ReplicatedStorage/Shared/Configs` folder for tunables. Use `StarterPlayerScripts/Controllers` for client controllers and `ServerScriptService/Services` for server authority.

---

## Phase 0 — Core Feel & Movement (High Priority)

### 1. Advanced Movement Mechanics
- Concept: Momentum-driven movement: bunnyhop, air-strafing, slide-jump, dash, mantling/ledge-grabs. Make movement skillful and satisfying.
- Tech/Tools: Luau modules, `RunService` (`RenderStepped` for visual smoothing), `Humanoid` and `RootPart` velocity manipulation, `ReplicatedStorage.Shared.Configs.MovementConfig.luau`.
- Architecture: Client-side responsiveness (controllers), server-side validation snapshot in `ServerScriptService/Services/MovementValidationService.luau`.
- Configs: Add fields to `MovementConfig` (airAcceleration, groundAcceleration, maxWalkSpeed, jumpCoyoteTime, bhopBoost, slideDecayCurve, dashCooldown, mantleRange).
- Implementation steps:
  1. MVP: Implement acceleration smoothing and capped speed lerp on client (`MovementController` already exists). Expose config parameters.
  2. Add air-strafe: modulate lateral velocity based on input while airborne with `AirControlMultiplier`.
  3. Add coyote time and jump buffering.
  4. Implement slide block with momentum carry and `SlideMomentumDecay` curve.
  5. Server validation: store recent pose snapshots and velocity; on suspicious boost, compare to snapshot window and optionally correct.
  6. Polish: animations, dust VFX, sounds, head-bobbing tuned.
- Files to create/edit: `ReplicatedStorage/Shared/Configs/MovementConfig.luau`, `StarterPlayerScripts/Controllers/MovementController.luau`, `ServerScriptService/Services/MovementValidationService.luau`.
- Estimate: MVP 3 days; polish 7–10 days.
- Tests: Playtest with high-latency sim, verify no clipping, and validate server corrections don't feel janky.
- Risks: Client speed exploits — mitigate via server snapshot reconciliation and soft-gating abnormal events.

### 2. Traversal Elements (Jump Pads / Rails)
- Concept: Map interactables that accentuate movement (jump pads, zip-lines, rails, jump-challenges).
- Tech: Part attributes + `CollectionService` tags for designer-friendly map placing.
- Architecture: Server spawns/authoritative triggers; client smoothly interpolates player visuals.
- Files: `ServerScriptService/Services/TraversalService.luau`, `ReplicatedStorage/Shared/Configs/TraversalConfig.luau`.
- Estimate: 2–5 days per traversal type.

---

## Phase 1 — Combat Systems & UX

### 3. Attachments & Handling Mods
- Concept: Allow per-weapon attachments to modify handling (ADS speed, recoil magnitude, spread) without adding new weapons.
- Tech: `AttachmentsConfig` in `ReplicatedStorage`, server-authoritative equip/unequip, HUD update events.
- Files: `ReplicatedStorage/Shared/Configs/AttachmentsConfig.luau`, `ServerScriptService/Services/AttachmentService.luau`, client HUD integration.
- Estimate: 3–6 days + 0.5–1 day per attachment.

### 4. Advanced Ballistics
- Concept: Velocity-based damage, bullet drop, penetration, and ricochet.
- Tech: Use `FastCast` (module) server-side for projectile simulation, or implement time-step raycasts; store `BulletsConfig` parameters.
- Architecture: Server authoritative for hit detection and damage; client-side tracer prediction for responsiveness.
- Files: `ServerScriptService/Services/BallisticsService.luau`, integrate with `DamageService.luau`.
- Estimate: 7–14 days for baseline; +1–2 weeks for penetration and materials.
- Tests: Accuracy with varying ping; penetration edge-cases.

### 5. Replay / Clip System (Lightweight)
- Concept: Short instant replays / highlight clips for analyses.
- Tech: Client local circular buffer of recent states; server event buffer for authoritative snapshots for matches.
- Files: `StarterPlayerScripts/Controllers/ClipRecorder.luau`, playback UI.
- Estimate: 5–10 days.

---

## Phase 2 — Multiplayer Robustness & Training

### 6. Lag Compensation & Anti-Cheat
- Concept: Rewind-based hit validation, anomaly detection, speed/aim heuristics.
- Tech: `MatchManager` + `ServerScriptService/Services/LagCompService.luau`. Circular buffer of recent player poses (tick timestamps), server-side rewind and raycast.
- Implementation:
  1. Implement pose buffer (position, rotation, rootVelocity) with bounded memory (e.g., 1.5s per player).
  2. On server shot validation, rewind target pose to client's shot time and perform raycast.
  3. Add simple anomaly detectors (excess speed, invalid teleportation) and logging.
- Files: `ServerScriptService/Services/LagCompService.luau`.
- Estimate: 7–14 days for baseline.
- Risks: False positives — provide logging and soft flagging.

### 7. AI Bots & Training Modes
- Concept: Bots for offline practice and configurable aim trainers; movement ghosts recording.
- Tech: Server-side AI using steering behaviors; `PathfindingService` where necessary; local ghost replays recorded from client.
- Files: `ServerScriptService/Services/BotManager.luau`, `StarterPlayerScripts/Controllers/GhostRecorder.luau`.
- Estimate: 7–14 days.

---

## Phase 3 — Modes, Physics, Progression, Polish

### 8. Objective Modes & Match Types
- Concept: Extraction, control-points, KOTH, time trials.
- Tech: `ServerScriptService/MatchModes/` modules; `MatchManager` orchestrates.
- Estimate: 3–7 days per mode.

### 9. Physics Props & Ragdoll Feedback
- Concept: Throwables, pushable cover, ragdoll impulse on death for satisfying feedback.
- Tech: `CollectionService` tags for interactive props, server authoritative physics impulses, ragdoll controller.
- Estimate: 4–10 days.

### 10. Cosmetic Progression & Store
- Concept: Cosmetic-only progression; weapon mastery, skins, cosmetic unlocks saved via `DataStoreService`.
- Tech: Server store API wrappers, client inventory UI.
- Estimate: 7–14 days.

### 11. Audio/Haptics
- Concept: Rich 3D audio layering and optional controller vibration.
- Tech: Client `AudioController`, positional sounds, raycast occlusion for muffling.
- Estimate: 3–6 days.

---

## Cross-Cutting Concerns
- Testing & CI: Periodic playtests, automated integration checks for critical services (MovementValidation, LagComp, DamageService).
- Performance: Profile server CPU for ballistics and physics; limit frequency of expensive checks.
- Security: Server authority for any state that impacts gameplay. Validate client-sent events.
- Designer Experience: Expose all tuning values in `ReplicatedStorage/Shared/Configs` with clear comments and ranges.
- Telemetry: Minimal play counters, weapon usage, map performance metrics (opt-in) stored in a light backend or DataStore logs.

---

## Sprint-by-Sprint Example Plan (8 weeks, 1 dev)
- Week 1: Phase 0 — Movement MVP (client smoothing, air-strafe, coyote time), basic slide.
- Week 2: Movement polish, server snapshot validator, add jump-pad traversal.
- Week 3: Attachments system & HUD hooks; begin `BallisticsService` prototype.
- Week 4: Ballistics polish, tracers, replay buffer basic implementation.
- Week 5: Lag compensation baseline (pose buffer + rewind), start bots.
- Week 6: Bots polish, basic objective mode (Control Point), matchmaking hooks.
- Week 7: Ragdoll/physics props, cosmetics backend skeleton, audio layering.
- Week 8: Hardening, QA, tuning, polish and bugfix sprint.

---

## Suggested Immediate Next Steps (pick one)
1. Prototype movement air-strafe + server-side snapshot validator (recommended).
2. Prototype server `BallisticsService` with tracers and velocity-based damage.
3. Implement attachments system and UI hooks.

If you pick (1), I will generate skeleton modules and patch `MovementConfig`, `MovementController`, and create `ServerScriptService/Services/MovementValidationService.luau` with simple snapshot buffer and validation logic.

---

## Appendix — Suggested File Map and Module Stubs
- `ReplicatedStorage/Shared/Configs/MovementConfig.luau` — tunables.
- `StarterPlayerScripts/Controllers/MovementController.luau` — client movement behavior.
- `ServerScriptService/Services/MovementValidationService.luau` — pose buffer and validation.
- `ServerScriptService/Services/BallisticsService.luau` — server projectile handling.
- `ReplicatedStorage/Shared/Configs/BulletsConfig.luau` — bullet params.
- `StarterPlayerScripts/Controllers/ClipRecorder.luau` — local clip buffer.

---

If you want, I can now: (A) create skeleton modules and patch files for the selected immediate next step, or (B) produce a prioritized task list with exact function/file targets and PR-sized subtasks. Reply with your choice and I'll start implementing.
