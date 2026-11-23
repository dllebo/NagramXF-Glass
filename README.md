# NagramXF Glass

Experimental Android Telegram client project.

## Architecture decisions

- **Liquid Glass:** full interface coverage — navigation, chat list, chat screen, message surfaces, composer, sheets, dialogs, profile, and settings.
- **Plugin system:** hybrid direction — exteraGram API compatibility where practical, with exteraless-inspired permissions, lifecycle management, and recovery controls.
- **Source strategy:** hybrid — NagramXF is the initial upstream baseline; selected exteraGram/exteraless components will be audited and ported deliberately.

## Current repository model

This repository currently contains the Glass build configuration and patch layer. The upstream NagramXF source is cloned during GitHub Actions into a temporary `source/` directory with its Git submodules. It is **not yet a native GitHub fork or a full source mirror**.

Upstream: https://github.com/Keeperorowner/NagramXF  
Upstream branch: `dev`  
Upstream source license: GPL-3.0. Preserve required notices and attribution when redistributing derivative source or binaries.

## Separate app identity

Glass builds use the Android application ID `fork.risin42.nagramx.glass`, while upstream NagramXF uses `fork.risin42.nagramx`. This allows Glass to be installed alongside the original app without replacing it. The workflow applies this identity override to the freshly cloned upstream source; it does not modify the upstream repository.

The upstream Firebase client metadata is adjusted locally during CI so the Google Services Gradle plugin can generate build resources. For reliable Firebase Cloud Messaging and Crashlytics under the Glass package, register a separate Android app in your own Firebase project and replace the upstream `TMessagesProj/google-services.json` through a reviewed patch.

## Build a debug APK

1. Open **Settings → Secrets and variables → Actions** in this repository.
2. Add the required signing secrets below.
3. Optionally add your own Telegram API credentials.
4. Open **Actions → Nagram XF Glass · Debug APK → Run workflow**.
5. Keep the default upstream ref `dev`, or enter a tag/branch/commit.
6. Download the APKs from the run's **Artifacts** section.

### Optional repository secrets

A first build can run without a signing key: Actions generates a temporary debug key. APKs signed this way are installable, but a later run will have a different signature and cannot update-install over the previous APK. You must uninstall the old app before installing a new one.

For repeat builds that update-install over one another, add all four persistent signing secrets:

| Secret | Value |
|---|---|
| `SIGNING_KEYSTORE_BASE64` | Base64-encoded persistent keystore |
| `KEYSTORE_PASS` | Keystore password |
| `ALIAS_NAME` | Key alias |
| `ALIAS_PASS` | Key password |

Optional Telegram credentials:

| Secret | Value |
|---|---|
| `TELEGRAM_APP_ID` | Your Telegram API ID |
| `TELEGRAM_APP_HASH` | Your Telegram API hash |

If the Telegram credentials are omitted, the workflow falls back to the public test credentials present in upstream NagramXF. Use your own credentials for regular personal builds.

### Create a persistent signing key (once)

Run locally:

```bash
keytool -genkeypair -v \
  -keystore glass-debug.keystore \
  -storetype JKS \
  -alias nagramxf-glass \
  -keyalg RSA -keysize 2048 -validity 10000
```

Encode the keystore on Linux:

```bash
base64 -w0 glass-debug.keystore
```

On macOS:

```bash
base64 < glass-debug.keystore | tr -d '\\n'
```

Add the resulting single-line value as `SIGNING_KEYSTORE_BASE64`. Save the password and alias you entered as `KEYSTORE_PASS`, `ALIAS_NAME`, and `ALIAS_PASS`. Keep this keystore safe: using the same key is necessary to install future builds as updates over earlier builds. Never commit it to Git.

Obtain your Telegram API credentials from https://my.telegram.org and add them as the optional secrets above.

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
