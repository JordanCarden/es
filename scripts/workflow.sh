#!/bin/bash
set -e
source "$(dirname "$0")/config.sh"

main() {
    simulations=$(./queue.sh | tail -n 1)

    if [ "$simulations" -gt 0 ]; then
        ./generate.sh "$simulations"
        ./run.sh
    else
        echo "QUEUE FULL"
    fi
}

main