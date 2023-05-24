#!/bin/sh
set -e

OSM2PGSQL_BIN=/usr/bin/osm2pgsql
ID_FILTER="" # See README.md 'Process only a single object'

FILTER_DIR="./filter/"
OSM_DATADIR="/data/" # root for docker
OSM_GERMANY=${OSM_DATADIR}openstreetmap-latest.osm.pbf
OSM_REGIONS=${OSM_DATADIR}openstreetmap-regions.osm.pbf
OSM_FILTERED_FILE=${OSM_DATADIR}openstreetmap-filtered.osm.pbf
OSM_FILTER_EXPRESSIONS=${FILTER_DIR}filter-expressions.txt

echo "\e[1m\e[7m Filter – PREPARE \e[27m\e[21m"

python3 ./filter/prepare_region_filter.py
MERGED_REGIONS_FILE=${FILTER_DIR}regions_merged.geojson

echo "\e[1m\e[7m Filter – START \e[27m\e[21m"

if [ -f "${OSM_GERMANY}" ]; then

  if [ "$SKIP_FILTER" = "skip" ]; then
    echo "💥 SKIPPED with 'SKIP_FILTER=skip' in '/docker-compose.yml'"
  else
    echo "\e[1m\e[7m Filter by regions\e[27m\e[21m"
    # Docs https://docs.osmcode.org/osmium/latest/osmium-extract.html
    osmium extract --overwrite --polygon=${MERGED_REGIONS_FILE} --output=${OSM_REGIONS} ${OSM_GERMANY}
    rm ${MERGED_REGIONS_FILE}
    echo "\e[1m\e[7m Filter by tags\e[27m\e[21m"
    # Docs https://docs.osmcode.org/osmium/latest/osmium-tags-filter.html
    osmium tags-filter --overwrite --expressions ${OSM_FILTER_EXPRESSIONS} --output=${OSM_FILTERED_FILE} ${OSM_REGIONS}
  fi
  if [ "$ID_FILTER" != "" ]; then
    echo "\e[1m\e[7m Seacrhing for osm-id: ${ID_FILTER}\e[27m\e[21m"
    osmium getid --overwrite --output=${OSM_FILTERED_FILE} --verbose-ids ${OSM_FILTERED_FILE} ${ID_FILTER}
  fi
else
  echo "Filter: 🧨 file ${OSM_GERMANY} not found"
fi

echo "\e[1m\e[7m Filter – END \e[27m\e[21m"
