# NagramXF Glass

Experimental Android Telegram client project.

**Architecture decisions**
- Full Liquid Glass UI across chats, message surfaces, navigation, sheets, dialogs, and settings.
- Hybrid plugin architecture: exteraGram-compatible API direction with exteraless-inspired permission boundaries and safety controls.
- Hybrid source strategy: NagramXF is the initial upstream baseline; selected components from exteraless/exteraGram will be evaluated and ported deliberately.

## Current repository model

This repository currently contains the Glass build configuration and patch layer. The upstream NagramXF source is cloned during GitHub Actions into a temporary `source/` directory with its Git submodules. It is not yet a native GitHub fork or a full source mirror.

Upstream: https://github.com/Keeperorowner/NagramXF  
Upstream branch: `dev`  
License of upstream source: GPL-3.0. Review upstream notices and preserve all required attribution when redistributing binaries or derivative source.

## Build a debug APK

1. Open **Settings → Secrets and variables → Actions** in this repository.
2. Add the secrets below.
3. Open **Actions → Nagram XF Glass · Debug APK → Run workflow**.
4. Keep the default upstream ref `dev`, or enter a tag/branch/commit.
5. Download the APKs from the run's **Artifacts** section.

### Required repository secrets

| Secret | Value |
|---|---|
| `SIGNING_KEYSTORE_BASE64` | Base64-encoded persistent keystore used to sign debug APKs |
| `LOCAL_PROPERTIES` | Optional Base64-encoded Java properties file with Telegram API credentials and signing passwords |

Alternatively, add `TELEGRAM_APP_ID` and `TELEGRAM_APP_HASH` as separate secrets. If neither separate credentials nor `LOCAL_PROPERTIES` are set, the workflow falls back to the public test credentials present in upstream NagramXF. Use your own credentials for regular personal builds.

Example `local.properties` before Base64 encoding:

```properties
TELEGRAM_APP_ID=your_app_id
TELEGRAM_APP_HASH=your_app_hash
KEYSTORE_PASS=your_store_password
ALIAS_NAME=your_alias
ALIAS_PASS=your_key_password
```

Create a persistent keystore locally (do this once; keep it safe):

```bash
keytool -genkeypair -v \
  -keystore glass-debug.keystore \
  -storetype JKS \
  -alias nagramxf-glass \
  -keyalg RSA -keysize 2048 -validity 10000
```

Encode files on Linux:

```bash
base64 -w0 glass-debug.keystore
base64 -w0 local.properties
```

On macOS use `base64 < file | tr -d '\\n'`.

The keystore alias and passwords in `local.properties` must match the keystore you created. Never commit the keystore or local properties to Git.

## Patch workflow

Put reviewed Git patches in `patches/` with the `.patch` extension. Actions checks and applies them to the freshly cloned upstream tree before building. Keep patches small and tied to a known upstream revision.

## Build environment

- Ubuntu 24.04 GitHub-hosted runner
- JDK 21
- Android SDK 36 / Build Tools 36.0.0
- NDK 27.2.12479018
- CMake 3.31.6
- arm64-v8a
- Gradle wrapper version supplied by upstream

The workflow builds both `normalDebug` and `pluginDebug` variants. These are upstream variants; they do not yet mean that the planned hybrid plugin engine has been ported.

## Roadmap

1. Reproducible CI build and upstream pinning.
2. Inspect NagramXF UI architecture and identify safe Liquid Glass integration points.
3. Implement a feature-flagged Glass material layer, then migrate navigation, chat list, chat screen, message cells, sheets, and dialogs.
4. Audit exteraGram and exteraless plugin APIs and licenses; design a compatibility adapter and permission model before porting runtime code.
5. Add visual and device-level regression checks.

## Security

Treat third-party plugins as untrusted code. A permission screen alone is not a sandbox. Do not load arbitrary plugin code until isolation, signing/trust policy, API boundaries, and failure recovery are designed and tested.
