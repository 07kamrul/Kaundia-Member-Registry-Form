#!/bin/sh
# Kept for compatibility; logic lives in scripts/run.sh.
exec sh "$(dirname "$0")/run.sh" resolve-duplicates "$@"
