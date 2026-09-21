#!/usr/bin/env bash
# Validate kernel-module references in a cloned OrangeFox device tree.
# Usage: validate-recovery-modules.sh <fox-tree> <device-path>
set -euo pipefail

FOX_PATH=${1:?OrangeFox tree path is required}
DEVICE_PATH=${2:?Device-tree path is required}

if [[ ! -d "$FOX_PATH" || ! -d "$DEVICE_PATH" ]]; then
  echo "Usage: $0 <fox-tree> <device-path>" >&2
  exit 2
fi

missing=0
while IFS= read -r module; do
  [[ -z "$module" ]] && continue
  module="${module%%#*}"
  module="$(printf '%s' "$module" | xargs)"
  [[ -z "$module" ]] && continue

  if ! find "$DEVICE_PATH" "$FOX_PATH/vendor" \
      -type f -name "$module" -print -quit 2>/dev/null | grep -q .; then
    echo "Missing recovery module: $module" >&2
    missing=1
  fi
done < <(
  grep -RhoE '[A-Za-z0-9_.+-]+\.ko' "$DEVICE_PATH" 2>/dev/null | sort -u
)

if (( missing )); then
  cat >&2 <<'EOF'
One or more .ko files referenced by the device tree do not exist.
Fix the device tree by removing stale module references or adding the
matching prebuilt modules before starting the OrangeFox build.
EOF
  exit 1
fi

echo "All referenced recovery modules exist."
