
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

build: Dockerfile
	$(CMD) buildx build --build-arg SUM_V=$(VER) $(PUSH_ARG) -t $(IMAGE):$(VER)-$(REV) .
