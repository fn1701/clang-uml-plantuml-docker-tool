#!/bin/sh
# Runs clang-uml against a mounted project (expects a .clang-uml config and
# a compile_commands.json under the mounted working directory), then
# renders every generated .puml file to the requested image format(s).
#
# Usage: docker run --rm --network=none -v "$PWD:/workspace" \
#          <image> [--format svg,png,jpg] [clang-uml args...]
set -eu

FORMATS="svg"
ARGS=""

while [ $# -gt 0 ]; do
    case "$1" in
        --format)
            FORMATS="$2"
            shift 2
            ;;
        *)
            ARGS="$ARGS $1"
            shift
            ;;
    esac
done

# shellcheck disable=SC2086
clang-uml $ARGS

OUTPUT_DIR=$(awk -F': *' '/^output_directory:/ {print $2; exit}' .clang-uml 2>/dev/null || echo docs/diagrams)

OLD_IFS=$IFS
IFS=','
for fmt in $FORMATS; do
    plantuml "-t${fmt}" "${OUTPUT_DIR}"/*.puml
done
IFS=$OLD_IFS
