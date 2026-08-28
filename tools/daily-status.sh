#!/usr/bin/env bash
# daily-status.sh
# Runs costafamily.ai status report and prints a summary.
# Output: HTML report at ~/Hermes-Workspace/reports/costafamily-status-<date>.html
set -euo pipefail
cd "$(dirname "$0")/.."
python tools/status-report.py
