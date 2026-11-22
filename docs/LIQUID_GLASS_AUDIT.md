# Liquid Glass implementation audit

Audit baseline: `Keeperorowner/NagramXF`, branch `dev`.  
This is a source-level audit, not a claim that every surface is already glass-enabled.

## Existing implementation discovered

The upstream already contains a substantial Liquid Glass stack:

| Area | Existing code | What it provides |
|---|---|---|
| Glass lifecycle/capture | `org.telegram.utils.glass.GlassEngine` | Tracks glass views, positions, scroll invalidation, display lists, and themed source colors |
| Drawable contract | `org.telegram.utils.glass.GlassDrawable` | Shared bounds, alpha, source offsets, display-list hooks, reserved capture bounds |
| Settings model | `org.telegram.utils.glass.GlassSettings` | Blur and liquid-glass enabled flags |
| Material rendering | `Components.blur3.drawable.BlurredBackgroundDrawable` | Rounded glass surfaces, source selection, rim, shadow, tint, and liquid refraction |
| Shader | `res/raw/liquid_glass_shader.agsl` | Refraction and foreground compositing |
| Arrow shader | `res/raw/liquid_glass_arrow_shader.agsl` | Refraction for popover/menu shapes with an arrow |
| Source/capture layer | `Components.blur3.*`, `utils.glass.source.*` | RenderNode/bitmap/color sources and view factories |
| Legacy blur | `Components.BlurBehindDrawable` | Bitmap downsampling and software-era fallback paths |

Important source references:

- `TMessagesProj/src/main/java/org/telegram/utils/glass/GlassEngine.java`
- `TMessagesProj/src/main/java/org/telegram/utils/glass/GlassDrawable.java`
- `TMessagesProj/src/main/java/org/telegram/utils/glass/GlassSettings.java`
- `TMessagesProj/src/main/java/org/telegram/ui/Components/blur3/drawable/BlurredBackgroundDrawable.java`
- `TMessagesProj/src/main/java/org/telegram/ui/Components/blur3/BlurredBackgroundDrawableViewFactory.java`
- `TMessagesProj/src/main/res/raw/liquid_glass_shader.agsl`
- `TMessagesProj/src/main/java/org/telegram/ui/MainTabsActivity.java`
- `TMessagesProj/src/main/java/org/telegram/ui/LiteModeSettingsActivity.java`
- `TMessagesProj/src/main/java/org/telegram/messenger/LiteMode.java`

## Current activation rules

The existing engine derives its settings from two LiteMode flags:

- `LiteMode.FLAG_CHAT_BLUR`
- `LiteMode.FLAG_LIQUID_GLASS`

The Liquid Glass renderer in `BlurredBackgroundDrawable` additionally checks the API level (Android 13 / API 33+) and whether the drawable factory explicitly allows the effect. The power-usage settings screen only exposes the Liquid Glass option on sufficiently capable devices and API 33+.

The main tabs already create glass sources and a glass drawable factory in `MainTabsActivity`. Several other surfaces use the same factory and source abstractions.

**Implication:** a global "Full Glass" experience is not achieved by merely turning on one flag. It requires an inventory of every screen/component, consistent source wiring, fallback behavior, and a deliberate performance policy.

## Known coverage gaps to investigate

These are audit targets, not yet confirmed defects:

1. **Chat message bubbles:** determine whether ordinary incoming/outgoing `ChatMessageCell` bubbles should remain solid for legibility or gain a separate glass treatment. Avoid blindly applying backdrop blur to every recycled message cell.
2. **Composer and chat chrome:** audit the message input, attachment controls, top chat header, pinned-message bars, reply/forward previews, and bottom overlays.
3. **Navigation:** verify every tab state (Chats, Contacts, Calls/Settings, Profile), hidden/scrolling states, tablet layout, and the profile button path. Upstream issue #184 specifically mentions the Profile button and bottom navigation glass.
4. **Sheets and menus:** inventory `BottomSheet`, `AlertDialog`, popup menus, context menus, and nested sheets. Reuse existing factories rather than create parallel blur systems.
5. **Settings/profile:** audit ordinary settings lists, profile header/actions, account switcher, and nested settings pages.
6. **Accessibility and fallback:** reduce transparency, high contrast, reduced motion, low-performance devices, API < 33, and power saver.
7. **Performance:** measure GPU time, overdraw, allocations, scroll jank, capture invalidation frequency, and memory use on low/mid/high tier devices.

## Implementation principles

- Keep the existing upstream GlassEngine as the rendering/capture foundation unless profiling proves a concrete limitation.
- Add a project-level Glass configuration/preset layer; do not fork the shader engine prematurely.
- Keep a user-visible Off / Frosted / Liquid / Full preset model. "Full" should mean consistent coverage, not maximum blur on every pixel.
- Use opaque or lightly frosted fallback surfaces when capture is unavailable.
- Do not capture sensitive content into persistent storage. Glass capture buffers must remain transient and be released with view lifecycle.
- Do not apply expensive refraction to every chat bubble by default. Use a curated surface policy and reuse/caching.
- Respect Android API capability and the existing power-saver controls.
- Test light/dark themes, wallpaper contrast, RTL, edge-to-edge, tablets/foldables, and accessibility settings.

## First implementation milestones

### LG-0 — Baseline
- Build upstream normalDebug and pluginDebug from Actions.
- Record upstream commit SHA and artifact hashes.
- Install and smoke-test both variants.

### LG-1 — Surface inventory
- Produce a matrix of all target surfaces and current source/factory usage.
- Capture screenshots on API 33+ and one pre-33 fallback device/emulator.
- Record any existing glass regressions before editing.

### LG-2 — Full Glass preset
- Add one explicit project-level preset and persistence.
- Map it to existing LiteMode flags without bypassing power-saver restrictions.
- Ensure a single change updates all registered surfaces.

### LG-3 — Coverage
- Complete bottom navigation/profile, top bars, sheets/dialogs, composer, settings/profile surfaces.
- Decide message bubble treatment independently after readability and performance tests.

### LG-4 — Validation
- Add screenshot/regression checklist and performance acceptance thresholds.
- Verify no crash when switching presets while scrolling, opening sheets, or changing themes.

## Acceptance criteria for "Full"

- Every agreed major app surface has an explicit material choice.
- No surface silently drops to an unrelated style when opening a nested screen.
- Liquid refraction only activates on supported devices and when enabled.
- Older devices have a stable frosted/solid fallback.
- Scroll and navigation remain smooth; no unbounded bitmap/render-node retention.
- Message text contrast and accessibility remain acceptable in all themes.
