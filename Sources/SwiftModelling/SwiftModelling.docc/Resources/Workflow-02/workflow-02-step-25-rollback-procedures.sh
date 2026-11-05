#!/bin/sh
# Backup and rollback of the legacy order models.
#
#   sh rollback-procedures.sh backup          copy the legacy models and
#                                             record their checksums
#   sh rollback-procedures.sh verify          check the backup
#   sh rollback-procedures.sh restore DIR     verify the backup, then
#                                             restore it into DIR
set -eu

backup=backup/legacy-1.0

case "${1:-}" in
backup)
    mkdir -p "$backup"
    cp LegacyOrders.ecore legacy/*.xmi "$backup"/
    (cd "$backup" && shasum -a 256 LegacyOrders.ecore *.xmi > SHA256SUMS)
    echo "Backed up $(ls "$backup"/*.xmi | wc -l | tr -d ' ') legacy models to $backup"
    ;;
verify)
    (cd "$backup" && shasum -a 256 -c SHA256SUMS)
    ;;
restore)
    target=${2:?usage: sh rollback-procedures.sh restore DIRECTORY}
    (cd "$backup" && shasum -a 256 -c --quiet SHA256SUMS)
    mkdir -p "$target"
    cp "$backup"/LegacyOrders.ecore "$backup"/*.xmi "$target"/
    swift-ecore validate "$target"/*.xmi -m "$target"/LegacyOrders.ecore
    echo "Restored the legacy models into $target"
    ;;
*)
    echo "usage: sh rollback-procedures.sh backup | verify | restore DIRECTORY" >&2
    exit 2
    ;;
esac
