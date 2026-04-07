# syntax=docker/dockerfile:1

FROM opensuse/tumbleweed AS build

RUN zypper -n refresh && \
    zypper -n install --no-recommends \
        python3-kiwi \
        kiwi-systemdeps-iso-media \
        kiwi-systemdeps-bootloaders \
        kiwi-systemdeps-filesystems \
        binutils \
    && zypper clean -a

COPY . /description/

RUN --security=insecure \
    kiwi-ng --debug --color-output system build \
        --description /description \
        --target-dir /result \
    && rm -rf /result/build

FROM scratch
COPY --from=build /result/ /
