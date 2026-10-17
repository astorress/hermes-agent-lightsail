#!/bin/bash
# Renders env.template into .env from the environment; empty variables are dropped.
set -euo pipefail

EXEC_PATH=$(dirname $(readlink -f "$0"))
VARIABLES=$(grep -oE '\$[A-Z_]+' $EXEC_PATH/env.template | sort -u | tr '\n' ' ')

envsubst "$VARIABLES" < $EXEC_PATH/env.template | grep -vE '=(""|)$' > $EXEC_PATH/.env || true
chmod 600 $EXEC_PATH/.env
