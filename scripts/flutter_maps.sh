#!/usr/bin/env bash
# Runs any `flutter` command with the Google Maps/Places key injected as a
# dart-define, sourced from the git-ignored android/local.properties.
#
# The key therefore never lives in version control or a bundled asset — it is
# read at build time from the same MAPS_API_KEY the native Google Maps SDK uses.
#
# Usage:
#   scripts/flutter_maps.sh run
#   scripts/flutter_maps.sh build appbundle --release --obfuscate --split-debug-info=build/symbols
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROPS="$ROOT/android/local.properties"

MAPS_API_KEY=""
if [[ -f "$PROPS" ]]; then
  # Extract the value after the first '=' on the MAPS_API_KEY line, trimming CR.
  MAPS_API_KEY="$(grep -E '^MAPS_API_KEY=' "$PROPS" | head -n1 | cut -d= -f2- | tr -d '\r')"
fi

if [[ -z "$MAPS_API_KEY" ]]; then
  echo "WARNING: MAPS_API_KEY not found in $PROPS." >&2
  echo "         Places/geocoding will rely solely on Firebase Remote Config." >&2
fi

exec flutter "$@" --dart-define=MAPS_API_KEY="$MAPS_API_KEY"
