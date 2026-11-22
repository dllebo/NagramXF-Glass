# Hybrid plugin runtime — design plan

Status: research/design only. No third-party plugin loader has been copied into this repository yet.

## Desired compatibility

The project goal is a hybrid runtime with:
- an exteraGram-compatible plugin-facing API where technically and legally feasible;
- exteraless-inspired permission prompts, lifecycle controls, crash containment, logs, and Safe Mode;
- an explicit compatibility layer so upstream plugin behavior does not directly depend on internal Telegram classes.

Compatibility must be verified against actual plugin SDK versions and sample plugins. Similar file extensions or API names do not prove binary compatibility.

## Proposed layers

1. **Plugin Registry**
   - Installed plugin metadata, version, entry point, supported API range, signer, declared capabilities.
   - Import/export and update metadata.
2. **Package Inspector**
   - Parse supported package formats without executing code.
   - Validate archive paths, size limits, duplicate entries, manifest schema, checksums, and signature.
3. **Permission Broker**
   - Capability grants for message access, contacts, account metadata, network, file access, UI injection, and hooks.
   - Default deny; explain each permission; revocable grants; audit trail.
4. **Compatibility API**
   - Stable interfaces for UI actions, lifecycle, preferences, notifications, and approved events.
   - Adapters for exteraGram plugin API versions.
   - No direct exposure of internal database keys, auth material, or Telegram session secrets.
5. **Runtime Host**
   - Plugin lifecycle, version negotiation, resource cleanup, timeouts, crash reporting, disable/restart.
   - Separate process or stronger isolation where feasible; in-process DEX hooks must be treated as fully trusted code.
6. **Python Bridge**
   - Evaluate existing Chaquopy integration and exteraless runtime requirements.
   - Restrict imports and exposed Java APIs; do not claim Python execution is a security sandbox.
7. **Developer Tools**
   - API docs, sample plugin, compatibility tests, debug logs, and a plugin validation command.

## Security constraints

- A plugin permission UI is not a sandbox.
- Arbitrary DEX/Xposed/Java hooks execute with the app's process privileges. They can read app memory and access private app data.
- Do not install plugins silently or auto-grant permissions.
- Verify signatures/checksums and display publisher identity, but do not treat a signature as proof of safety.
- Keep plugin data separate from Telegram account/session storage.
- Provide Safe Mode that starts the client with all third-party plugins disabled.
- Log permission use and runtime failures without logging message contents, phone numbers, auth tokens, or private keys.
- Network access should be opt-in and documented.
- Never let plugin code access or export Telegram authentication keys.

## Porting workflow

1. Identify exact exteraGram and exteraless upstream repositories, commits, license files, and plugin SDK documentation.
2. Build a feature/API matrix and determine which runtime components are actually reusable.
3. Inspect package formats and sample plugins.
4. Port metadata parsing and validation first; no code execution.
5. Add permission model and Safe Mode.
6. Implement one narrow, low-risk API surface and a sample plugin.
7. Add compatibility tests before expanding hooks or Python support.

## Definition of done

- Package inspection never executes plugin code.
- Permission grants are explicit, scoped, revocable, and persisted safely.
- Safe Mode reliably starts with third-party plugins disabled.
- Crashes in plugin lifecycle are contained and recorded.
- A sample plugin passes API compatibility tests.
- The app clearly warns that in-process hooks are trusted code and cannot be sandboxed by ordinary permission prompts.
