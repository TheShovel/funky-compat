#!/usr/bin/env sh
# Install the funky-compat compatibility layer into a V-Slice install.
# Usage: ./install.sh /path/to/vslice
#
# The layer adapts to the target install's API version at install time:
# Polymod only LOADS mods whose `api_version` falls inside the engine's API
# version rule (V-Slice 0.8.x uses '>=0.8.0 <0.9.0', 0.7.x and 0.9.x differ).
# The most reliable signal for what THIS install expects is the metadata of
# any native (non-funky-compat) mod already present in its mods folder, so we
# copy that value into the freshly installed metadata.
set -e

VS_PATH="${1:-}"
if [ -z "$VS_PATH" ]; then
  echo "Usage: $0 /path/to/vslice (the folder that contains the 'mods' directory)"
  exit 1
fi

MODS="$VS_PATH/mods"
if [ ! -d "$MODS" ]; then
  echo "No mods folder found at: $MODS"
  exit 1
fi

DEST="$MODS/funky-compat"
rm -rf "$DEST"
cp -r vslice-mod "$DEST"

# ---------------------------------------------------------------------------
# Detect the API version this install expects and patch the installed metadata
# ---------------------------------------------------------------------------
API_VERSION=""
for meta in "$MODS"/*/_polymod_meta.json; do
  [ -f "$meta" ] || continue
  case "$meta" in
    *"/funky-compat/"*) continue ;;
  esac
  v=$(grep -o '"api_version"[^,]*' "$meta" | head -n1 | sed 's/.*"api_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
  if [ -n "$v" ]; then
    API_VERSION="$v"
    echo "Inferred API version $API_VERSION from existing mod metadata: ${meta#*/mods/}"
    break
  fi
done

if [ -z "$API_VERSION" ]; then
  # No native mod metadata to read. Try the install folder name (e.g. "0.8.4").
  base=$(basename "$VS_PATH")
  if printf '%s' "$base" | grep -qE '^[0-9]+\.[0-9]+'; then
    API_VERSION="$base"
    echo "Inferred API version $API_VERSION from install folder name."
  else
    API_VERSION="0.8.4"
    echo "WARNING: could not infer the API version; falling back to $API_VERSION."
    echo "         If the game is not a 0.8.x build, set api_version in"
    echo "         $DEST/_polymod_meta.json to a version matching the game's"
    echo "         API version rule before launching."
  fi
fi

META="$DEST/_polymod_meta.json"
sed -i "s/\"api_version\": \"[^\"]*\"/\"api_version\": \"$API_VERSION\"/" "$META"

MOD_VERSION=$(grep -o '"mod_version"[^,]*' "$META" | head -n1 | sed 's/.*"mod_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

echo "Installed funky-compat v$MOD_VERSION into: $DEST"
echo "api_version set to: $API_VERSION"
echo "Now copy your Psych/Codename mod folders into $MODS and launch V-Slice."