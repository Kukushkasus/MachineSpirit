#!/usr/bin/env bash
# [ PURITY SEAL ] Preserve the user's work. Record every rite.
set -euo pipefail
exec python3 "$(cd -- "$(dirname -- "$0")" && pwd)/installer/install.py" "$@"
