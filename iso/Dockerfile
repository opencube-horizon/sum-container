# syntax=docker/dockerfile:1
#
# Two usage modes:
#   Docker  (buildx + security.insecure) — full build in one shot
#   Podman  (build --target + run --privileged) — see Makefile

# ── Stage: build-env ────────────────────────────────────────────
# Installs KIWI and copies the image description.
# Podman stops here (--target build-env), then runs KIWI via
# "podman run --privileged" because podman build cannot grant
# loop-device access during RUN.
FROM opensuse/tumbleweed AS build-env

RUN zypper -n refresh && \
    zypper -n install --no-recommends \
        python3-kiwi \
        kiwi-systemdeps-iso-media \
        kiwi-systemdeps-bootloaders \
        kiwi-systemdeps-filesystems \
        binutils \
    && zypper clean -a

COPY . /description/

# ── Stage: build (Docker only) ─────────────────────────────────
# Requires BuildKit with --allow security.insecure entitlement.
FROM build-env AS build

RUN --security=insecure \
    kiwi-ng --debug --color-output system build \
        --description /description \
        --target-dir /result \
    && rm -rf /result/build

# ── Export ──────────────────────────────────────────────────────
FROM scratch
COPY --from=build /result/ /
