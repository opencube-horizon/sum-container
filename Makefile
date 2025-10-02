
VER := 12.2.0
REV := 0
PUSH := false
REGISTRY :=
PROJECT := 

IMAGE := $(if $(REGISTRY),$(REGISTRY)/)$(if $(PROJECT),$(PROJECT)/)sum

build: Dockerfile
	docker buildx build --build-arg SUM_V=$(VER) -t $(IMAGE):$(VER)-$(REV) .
