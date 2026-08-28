#!/usr/bin/env bash
set -euo pipefail

BUNDLE_ID_VALUE="${1:-${BUNDLE_ID:-}}"
if [[ -z "$BUNDLE_ID_VALUE" ]]; then
  echo "Usage: set-ios-bundle-id.sh <bundle-id>" >&2
  exit 64
fi

export BUNDLE_ID_VALUE

python3 <<'PY'
import os
import pathlib
import re

bundle_id = os.environ["BUNDLE_ID_VALUE"].strip()
if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9.-]+", bundle_id):
    raise SystemExit(f"Invalid bundle id: {bundle_id}")

project_path = pathlib.Path("project.yml")
text = project_path.read_text(encoding="utf-8")
updated, count = re.subn(
    r"PRODUCT_BUNDLE_IDENTIFIER:\s*[^\n]+",
    f"PRODUCT_BUNDLE_IDENTIFIER: {bundle_id}",
    text,
    count=1,
)
if count != 1:
    raise SystemExit("Could not find PRODUCT_BUNDLE_IDENTIFIER in project.yml")

project_path.write_text(updated, encoding="utf-8")
print(f"Configured PRODUCT_BUNDLE_IDENTIFIER={bundle_id}")
PY