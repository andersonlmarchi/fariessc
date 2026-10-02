ROOT := $(abspath ..)
LAYER_KEYS := limites_municipios confluencias cursos_dagua nascentes trechos_drenagem

.PHONY: all layers check-ogr help

help:
	@echo "Targets: all, layers, check-ogr, load-<layer>"
	@echo "Layers: $(LAYER_KEYS)"
	@echo "Edit ingest/config/layers.yaml with your .shp paths first."

check-ogr:
	@command -v ogr2ogr >/dev/null || (echo "install gdal-bin (ogr2ogr)" >&2; exit 1)
	@ogr2ogr --version | head -1

all: check-ogr layers

layers: $(addprefix load-,$(LAYER_KEYS))

load-%:
	@bash scripts/load-layer.sh $*
