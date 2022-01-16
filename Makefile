include .env

pbf = /tmp/$(REGION)-latest.osm.pbf
geojson = /tmp/$(REGION)-latest.osm.geojson
mbtiles = docs/region.mbtiles
zxy_metadata = docs/zxy/metadata.json

targets = \
	$(pbf) \
	$(geojson) \
	$(mbtiles) \
	$(zxy_metadata)

all: $(targets)

.PHONY: clean
clean:
	rm -rf tmp/layers/*.geojson
	rm -rf $(mbtiles)
	rm -rf docs/zxy

.PHONY: start
start:
	tileserver-gl-light $(mbtiles) --port 3000

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

# split region geojson to layers
# See: https://openmaptiles.org/schema/
layers_files = \
	tmp/layers/aerodrome_label.geojson \
	tmp/layers/aeroway.geojson \
	tmp/layers/boundary.geojson \
	tmp/layers/building.geojson \
	tmp/layers/housenumber.geojson \
	tmp/layers/landcover.geojson \
	tmp/layers/landuse.geojson \
	tmp/layers/mountain_peak.geojson \
	tmp/layers/park.geojson \
	tmp/layers/place.geojson \
	tmp/layers/poi.geojson \
	tmp/layers/transportation.geojson \
	tmp/layers/transportation_name.geojson \
	tmp/layers/water.geojson \
	tmp/layers/water_name.geojson \
	tmp/layers/waterway.geojson

tmp/layers/aerodrome_label.geojson:
	mkdir -p $(@D)
	grep -s '"aeroway":"aerodrome"' $(geojson) > $@ || true

tmp/layers/aeroway.geojson:
	mkdir -p $(@D)
	grep -s '"aeroway":' $(geojson) > $@ || true

tmp/layers/boundary.geojson:
	mkdir -p $(@D)
	grep -s -E '"admin_level":"2"|"admin_level":"4"' $(geojson) > $@ || true

tmp/layers/building.geojson:
	mkdir -p $(@D)
	grep '"building":' $(geojson) > $@ || true

tmp/layers/housenumber.geojson:
	mkdir -p $(@D)
	grep '"addr:housenumber":' $(geojson) > $@ || true

tmp/layers/landcover.geojson:
	mkdir -p $(@D)
	grep '"landcover":' $(geojson) > $@ || true

tmp/layers/landuse.geojson:
	mkdir -p $(@D)
	grep '"landuse":' $(geojson) > $@ || true

tmp/layers/mountain_peak.geojson:
	mkdir -p $(@D)
	grep -E '"natural":"peak"|"natural":"volcano"' $(geojson) > $@ || true

tmp/layers/park.geojson:
	mkdir -p $(@D)
	grep '"leisure":"park"' $(geojson) > $@ || true

tmp/layers/place.geojson:
	mkdir -p $(@D)
	grep '"place":' $(geojson) > $@ || true

tmp/layers/poi.geojson:
	mkdir -p $(@D)
	grep -E '"town_hall"|"school"|"college"|"lodging"|"hospital"|"stadium"' $(geojson) | grep '"name":' > $@ || true

tmp/layers/transportation.geojson:
	mkdir -p $(@D)
	grep -E '"highway":|"railway":|"aerialway":|"route":' $(geojson) > $@ || true

tmp/layers/transportation_name.geojson:
	mkdir -p $(@D)
	grep -E '"highway":|"railway":|"aerialway":|"route":' $(geojson) | grep '"name":' > $@ || true

tmp/layers/water.geojson:
	mkdir -p $(@D)
	grep '"natural":"water"' $(geojson) > $@ || true

tmp/layers/water_name.geojson:
	mkdir -p $(@D)
	grep '"natural":"water"' $(geojson) | grep '"name":' > $@ || true

tmp/layers/waterway.geojson:
	mkdir -p $(@D)
	grep '"waterway":' $(geojson) > $@ || true

# Build MBTiles Format file from tmp/layers/*.geojson
$(mbtiles): $(layers_files)
	mkdir -p $(@D)
	tippecanoe \
		-P \
		--force \
		--no-tile-compression \
		--maximum-zoom=g \
		--generate-ids \
		--hilbert \
		--output=$(mbtiles) \
		tmp/layers/*.geojson

# Split MBTiles Format file into zxy Protocolbuffer Binary Format files
$(zxy_metadata):
	mkdir -p $(@D)
	tile-join \
		--no-tile-compression \
		--no-tile-size-limit \
		--no-tile-stats \
		--output-to-directory=docs/zxy \
		$(mbtiles)
