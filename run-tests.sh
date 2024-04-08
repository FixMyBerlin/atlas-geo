#!/bin/bash
# Start docker and run all tests there.
# This file is used by `npm run test`

docker compose -f docker-compose.development.yml run --build --entrypoint /app/run-tests.sh app