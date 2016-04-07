
QA_TILES ?= planet
IMAGE_TILES ?= "tilejson+https://a.tiles.mapbox.com/v4/mapbox.satellite.json?access_token=$(MapboxAccessToken)"
TRAIN_SIZE ?= 1000
CLASSES ?= classes/water-roads-buildings.json

data/osm/planet.mbtiles:
	mkdir -p $(dir $@)
	curl https://s3.amazonaws.com/mapbox/osm-qa-tiles/latest.planet.mbtiles.gz | gunzip > $@

data/osm/%.mbtiles:
	mkdir -p $(dir $@)
	curl https://s3.amazonaws.com/mapbox/osm-qa-tiles/latest.country/$(notdir $@).gz | gunzip > $@

data/sample.txt: data/osm/$(QA_TILES).mbtiles
	tippecanoe-enumerate $^ | ./sample $(TRAIN_SIZE) > $@

data/labels/color: data/sample.txt
	mkdir -p $@
	cat data/sample.txt | ./rasterize-labels data/osm/$(QA_TILES).mbtiles $(CLASSES) $@

data/labels/grayscale: data/labels/color
	mkdir -p $@
	for i in $(wildcard data/labels/color/*.png) ; do cat $$i | ./palette-to-grayscale $(CLASSES) > $@/`basename $$i` ; done

data/images:
	mkdir -p $@
	cat data/sample.txt | ./download-images $(IMAGE_TILES) $@

.PHONY: clean-labels clean-images clean
clean-labels:
	rm -rf data/labels
clean-images:
	rm -rf data/images
clean: clean-images clean-labels
	rm data/sample.txt
