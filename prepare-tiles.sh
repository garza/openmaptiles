#!/bin/bash

docker-compose run --rm openmaptiles-tools generate-metadata ./data/tiles.mbtiles
docker-compose run --rm openmaptiles-tools chmod 666 ./data/tiles.mbtiles
