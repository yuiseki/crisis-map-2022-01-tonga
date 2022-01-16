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

.PHONY: start
start:
	tileserver-gl-light $(mbtiles) --port 3000

.PHONY: serve
serve:
	http-server docs

# Download OpenStreetMap data as Protocolbuffer Binary Format file to /tmp
$(pbf):
	mkdir -p $(@D)
	curl \
		--continue-at - \
		--output $(pbf) \
		https://download.geofabrik.de/$(REGION)-latest.osm.pbf

# Export pbf file as GeoJSONSeq Format file to /tmp
$(geojson):
	osmium export \
		--output-format=geojsonseq \
		--output=$(geojson) \
		$(pbf)

$(mbtiles):
	mkdir -p $(@D)
	docker run --rm --mount type=bind,source=$(CURDIR)/tmp,target=/tmp tilemaker \
		--input /$(pbf) \
		--output /$(mbtiles)

# Split MBTiles Format file into zxy Protocolbuffer Binary Format files
$(zxy_metadata):
	mkdir -p $(@D)
	tile-join \
		--no-tile-compression \
		--no-tile-size-limit \
		--no-tile-stats \
		--output-to-directory=docs/zxy \
		$(mbtiles)
