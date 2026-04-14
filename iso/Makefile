
VER     := 1.0.0
REV     := 0
SPP     := 2026.03.00.00
AMSD_V  := 4.6.0
SUT_V   := 6.6.0

IMAGE       := hpe-appliance
BUILDX_NAME := kiwi
KIWI_IMAGE  := kiwi-build

# Detect container engine: prefer podman, fall back to docker.
# Trailing ; defeats GNU Make ≤4.3 optimisation that skips the shell
# for simple commands — command(1) is a shell builtin, not a binary
# on many systems.  See https://savannah.gnu.org/bugs/?57625
CMD := $(if $(shell command -v podman 2>/dev/null ;),podman,docker)

DESCRIPTION := $(CURDIR)/build/description
RESULT      := $(CURDIR)/build/result
MANIFEST    := $(CURDIR)/build/manifest.yaml

.PHONY: iso iso-docker iso-podman stage manifest clean

# ── Docker path ─────────────────────────────────────────────────
# Uses buildx with docker-container driver and BuildKit's
# security.insecure entitlement for loop-device access.
iso-docker: stage
	mkdir -p $(RESULT)
	docker buildx inspect $(BUILDX_NAME) >/dev/null 2>&1 || \
		docker buildx create --name $(BUILDX_NAME) --driver docker-container \
			--buildkitd-flags '--allow-insecure-entitlement security.insecure'
	docker buildx build --builder $(BUILDX_NAME) \
		--allow security.insecure \
		--output type=local,dest=$(RESULT) \
		-f $(CURDIR)/Dockerfile \
		$(DESCRIPTION)

# ── Podman path ─────────────────────────────────────────────────
# podman build cannot grant loop-device access during RUN, so we:
#   1. Build the KIWI tooling image (--target build-env)
#   2. Run KIWI inside a --privileged container
#   3. Copy the result out
iso-podman: stage
	mkdir -p $(RESULT)
	podman build --format docker \
		--target build-env \
		-t $(KIWI_IMAGE) \
		-f $(CURDIR)/Dockerfile \
		$(DESCRIPTION)
	podman rm -f kiwi-run 2>/dev/null || true
	podman run --rm --privileged \
		--security-opt label=disable \
		--name kiwi-run \
		$(KIWI_IMAGE) \
		sh -c '\
			f=/usr/lib/python3*/site-packages/kiwi; \
			sed -i "s/ '"'"'--xattrs'"'"', '"'"'--acls'"'"',//" $$f/defaults.py; \
			sed -i "s/'"'"'-X'"'"', '"'"'-A'"'"', //" $$f/system/setup.py; \
			kiwi-ng --debug --color-output system build \
				--description /description \
				--target-dir /result > /tmp/kiwi-build.log 2>&1; \
			rc=$$?; cat /tmp/kiwi-build.log >&2; \
			[ $$rc -eq 0 ] || exit $$rc; \
			cp /tmp/kiwi-build.log /result/ \
			&& rm -rf /result/build \
			&& tar -cf - -C /result . \
		' | tar -xf - -C $(RESULT)

# ── Auto-detect ─────────────────────────────────────────────────
ifeq ($(CMD),podman)
iso: iso-podman
else
iso: iso-docker
endif
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
	docker buildx rm $(BUILDX_NAME) 2>/dev/null || true
	podman rmi $(KIWI_IMAGE) 2>/dev/null || true
