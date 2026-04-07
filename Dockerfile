FROM opensuse/leap:15.6

ARG SUM_V

LABEL org.opencontainers.image.title="SUM Container" \
      org.opencontainers.image.description="HPE Smart Update Manager in a container" \
      org.opencontainers.image.version="${SUM_V}" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/opencube-horizon/sum-container"

RUN set -ex ; \
    rpm --import https://downloads.linux.hpe.com/SDR/hpPublicKey2048_key1.pub ; \
    rpm --import https://downloads.linux.hpe.com/SDR/hpePublicKey2048_key1.pub ; \
    rpm --import https://downloads.linux.hpe.com/SDR/hpePublicKey2048_key2.pub ; \
    zypper ar https://downloads.linux.hpe.com/SDR/repo/sum/suse/15/x86_64/current/ sum ; \
    zypper ref sum ; \
    zypper in -y --no-recommends \
        rsync lftp wget tar \
        "sum==${SUM_V}" \
    ; \
    rm -rf /var/cache/zypp/*

VOLUME /assets
VOLUME /data

EXPOSE 63001
EXPOSE 63002

COPY . /
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget -q --spider --no-check-certificate https://localhost:63002/ || exit 1
ENTRYPOINT ["/entrypoint.sh"]
