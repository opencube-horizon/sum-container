
VER := 12.2.0
REV := 0
PUSH := false
REGISTRY :=
PROJECT := 

IMAGE := $(if $(REGISTRY),$(REGISTRY)/)$(if $(PROJECT),$(PROJECT)/)sum

# use Podman if available, otherwise Docker
CMD := $(if $(shell command -v podman 2>/dev/null),podman,docker)

# when using docker, pass --push=$(PUSH) to buildx command
PUSH_ARG := $(if $(findstring docker,$(CMD)),--push=${PUSH},)

# docker uses "buildx build", podman uses plain "build"
BUILD_CMD := $(if $(findstring docker,$(CMD)),buildx build,build)

# podman defaults to OCI format which does not support HEALTHCHECK; use docker format
FORMAT_ARG := $(if $(findstring podman,$(CMD)),--format docker,)

.PHONY: build push clean

build: Dockerfile entrypoint.sh mirror.sh
	$(CMD) $(BUILD_CMD) --build-arg SUM_V=$(VER) $(FORMAT_ARG) $(PUSH_ARG) -t $(IMAGE):$(VER)-$(REV) .

push:
	$(CMD) push $(IMAGE):$(VER)-$(REV)

clean:
	$(CMD) rmi $(IMAGE):$(VER)-$(REV) 2>/dev/null || true
