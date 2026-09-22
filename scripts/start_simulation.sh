#!/bin/bash
# Run from the project root: bash scripts/start_simulation.sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."
source backend/venv/bin/activate
python scripts/simulate_driver.py
