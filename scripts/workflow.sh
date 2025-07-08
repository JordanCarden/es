#!/bin/bash
set -e
# shellcheck source=./config.sh

source "$(dirname "$0")/config.sh"

main() {
    local simulations
    simulations=$(./queue.sh | tail -n 1)

    if [ "$simulations" -gt 0 ]; then
        ./generate.sh "$simulations"
        ./run.sh
    else
        echo "QUEUE FULL"
    fi
}

main "$@"
