
VER     := 1.0.0
REV     := 0
SPP     := 2026.03.00.00
AMSD_V  := 4.6.0
SUT_V   := 6.6.0

IMAGE       := hpe-appliance
BUILDX_NAME := kiwi

CMD := $(if $(shell command -v podman 2>/dev/null),podman,docker)

DESCRIPTION := $(CURDIR)/build/description
RESULT      := $(CURDIR)/build/result
MANIFEST    := $(CURDIR)/build/manifest.yaml

.PHONY: iso stage manifest clean

iso: stage
	mkdir -p $(RESULT)
	$(CMD) buildx inspect $(BUILDX_NAME) >/dev/null 2>&1 || \
		$(CMD) buildx create --name $(BUILDX_NAME) --driver docker-container \
			--buildkitd-flags '--allow-insecure-entitlement security.insecure'
	$(CMD) buildx build --builder $(BUILDX_NAME) \
		--allow security.insecure \
		--output type=local,dest=$(RESULT) \
		-f $(CURDIR)/Dockerfile \
		$(DESCRIPTION)
	@echo ""
	@echo "ISO built. Output:"
	@ls -lh $(RESULT)/$(IMAGE)*.iso 2>/dev/null || echo "  (no ISO found — check output above)"
	@echo ""
	@echo "Package manifest:"
	@ls -lh $(RESULT)/$(IMAGE)*.packages 2>/dev/null || true

stage: appliance/config.xml appliance/config.sh
	rm -rf $(DESCRIPTION)
	mkdir -p $(DESCRIPTION)/root/etc
	cp appliance/config.sh $(DESCRIPTION)/
	sed -i \
		-e 's|__SPP_BASELINE__|$(SPP)|g' \
		$(DESCRIPTION)/config.sh
	@if [ -d appliance/root ]; then cp -a appliance/root/. $(DESCRIPTION)/root/; fi
	sed \
		-e 's|__VERSION__|$(VER)|g' \
		-e 's|__SPP_BASELINE__|$(SPP)|g' \
		appliance/config.xml > $(DESCRIPTION)/config.xml
	@printf 'ISO_VERSION=%s\nISO_BUILD_DATE=%s\nSPP_BASELINE=%s\nAMSD_VERSION=%s\nSUT_VERSION=%s\n' \
		"$(VER)" "$$(date -u +%Y-%m-%d)" "$(SPP)" "$(AMSD_V)" "$(SUT_V)" \
		> $(DESCRIPTION)/root/etc/hpe-iso-version

manifest:
	@mkdir -p build
	@printf 'iso_version: "%s"\nrevision: %s\nspp_baseline: "%s"\nbuild_date: "%s"\ncomponents:\n  amsd: "%s"\n  sut: "%s"\n' \
		"$(VER)" "$(REV)" "$(SPP)" "$$(date -u +%Y-%m-%d)" "$(AMSD_V)" "$(SUT_V)" \
		> $(MANIFEST)
	@echo "Generated $(MANIFEST)"

clean:
	rm -rf build/
	$(CMD) buildx rm $(BUILDX_NAME) 2>/dev/null || true
