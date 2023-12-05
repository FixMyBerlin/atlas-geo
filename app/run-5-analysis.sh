#!/bin/bash
set -e
source ./process-helpers.sh

echo -e "\e[1m\e[7m Analysis – START \e[27m\e[21m\e[0m"

run_psql "analysis/boundaryStats"

echo -e "\e[1m\e[7m Analysis – END \e[27m\e[21m\e[0m"