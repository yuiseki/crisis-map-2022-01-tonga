include .env

pbf = tmp/$(REGION)-latest.osm.pbf
geojson = tmp/$(REGION)-latest.osm.geojson
mbtiles = tmp/region.mbtiles
zxy_metadata = docs/zxy/metadata.json

targets = \
	$(pbf) \
	$(geojson) \
	$(mbtiles) \
	$(zxy_metadata)

all: $(targets)

.PHONY: clean
clean:
	rm -rf $(mbtiles)
	rm -rf docs/zxy

.PHONY: start_tileserver
start_tileserver: tmp/tileserver.pid

.PHONY: stop_tileserver
stop_tileserver: tmp/tileserver.pid
	kill -9 `cat $<`
	rm $<

tmp/tileserver.pid:
	tileserver-gl-light $(mbtiles) --port 3000 & echo $$! > $@

docs/tiles.json: start_tileserver
	sleep 10
	curl http://localhost:3000/data/v3.json | jq . > $@
	sleep 1
	make stop_tileserver
	sed -i -e 's#http://localhost:3000/data/v3/#$(GITHUB_PAGES)zxy/#g' docs/tiles.json

# Download OpenStreetMap data as Protocolbuffer Binary Format file
$(pbf):
	mkdir -p $(@D)
	curl \
		--continue-at - \
		--output $(pbf) \
		https://download.geofabrik.de/$(REGION)-latest.osm.pbf

# Convert Protocolbuffer Binary Format file to MBTiles format file
$(mbtiles):
	mkdir -p $(@D)
	docker run \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		tilemaker \
			--input /$(pbf) \
			--output /$(mbtiles)

# Split MBTiles Format file to zxy orderd Protocolbuffer Binary Format files
$(zxy_metadata):
	mkdir -p $(@D)
	docker run \
		-it \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		tippecanoe \
			tile-join \
				--force \
				--no-tile-compression \
				--no-tile-size-limit \
				--no-tile-stats \
				--output-to-directory=/tmp/zxy \
				/$(mbtiles)
	cp -r tmp/zxy docs/zxy