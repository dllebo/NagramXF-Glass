#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-source}"
if [[ ! -d "$ROOT" ]]; then
  echo "::error::Source directory not found: $ROOT"
  exit 1
fi

required=(
  "gradlew"
  "settings.gradle"
  "TMessagesProj/build.gradle"
)
missing=()
for path in "${required[@]}"; do
  if [[ ! -e "$ROOT/$path" ]]; then
    missing+=("$path")
  fi
done

if (( ${#missing[@]} )); then
  printf '::error::Missing expected upstream files:\n'
  printf ' - %s\n' "${missing[@]}"
  exit 1
fi

echo "== NagramXF source audit =="
echo "Revision: $(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
echo "Gradle wrapper: present"
echo "Android app module: present"

glass_files=(
  "TMessagesProj/src/main/java/org/telegram/utils/glass/GlassEngine.java"
  "TMessagesProj/src/main/java/org/telegram/utils/glass/GlassDrawable.java"
  "TMessagesProj/src/main/java/org/telegram/ui/Components/blur3/drawable/BlurredBackgroundDrawable.java"
  "TMessagesProj/src/main/res/raw/liquid_glass_shader.agsl"
)

glass_found=0
for path in "${glass_files[@]}"; do
  if [[ -f "$ROOT/$path" ]]; then
    echo "FOUND glass: $path"
    ((glass_found+=1))
  else
    echo "MISSING glass: $path"
  fi
done

echo "Liquid Glass components found: $glass_found/${#glass_files[@]}"
if (( glass_found == 0 )); then
  echo "::warning::No known Liquid Glass engine files found; upstream layout may have changed."
fi

echo "Submodule status:"
git -C "$ROOT" submodule status 2>/dev/null || true
