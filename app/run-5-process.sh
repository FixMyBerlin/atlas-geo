#!/bin/bash
set -e
source ./process-helpers.sh

export PROCESS_DIR=/app/process/
# The folder for our code hashes, it lies inside the database volume to get invalidated on deletion
export CODE_HASHES=/data/db/code_hashes/
mkdir -p $CODE_HASHES
# Create functions needed for jsonb diffs
psql -q -f ./Diffing/JSONDiff.sql

log_start "$0"

if ! check_hash "${PROCESS_DIR}helper" ".lua"; then
  log "Helpers have changed. Deleting all checksums!"
  rm -f $CODE_HASHES*.lua.sha
  update_hash "${PROCESS_DIR}helper" ".lua"
fi

# One one .lua and one optional .sql per topic.
# Order of topics is important b/c they might rely on their data
# See [process/README.md](./process/README.md) for more
topics=("roads_bikelanes" "bikeroutes" "bicycleParking" "trafficSigns" "boundaries" "places" "landuse" "publicTransport" "poiClassification" "barriers")
for name in ${topics[@]}; do
  run_dir $name
done

notify "Processing finished."

log "✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ "
log "Completed:"
log "Development http://localhost:3000/catalog"
log "Staging https://staging-tiles.radverkehrsatlas.de/catalog"
log "Production https://tiles.radverkehrsatlas.de/catalog"
log "Test-Map https://data.radverkehrsatlas.de/"
log "✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ "

log_end "$0"
