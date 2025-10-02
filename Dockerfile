FROM opensuse/leap:15.6

ARG SUM_V

RUN set -ex ; \
    rpm --import https://downloads.linux.hpe.com/SDR/hpPublicKey2048_key1.pub ; \
    rpm --import https://downloads.linux.hpe.com/SDR/hpePublicKey2048_key1.pub ; \
    rpm --import https://downloads.linux.hpe.com/SDR/hpePublicKey2048_key2.pub ; \
    zypper ar https://downloads.linux.hpe.com/SDR/repo/sum/suse/15/x86_64/current/ sum ; \
    zypper ref sum ; \
    zypper in -y \
        rsync lftp wget \
        "sum==${SUM_V}" \
    ; \
    rm -rf /var/cache/zypp/*

VOLUME /assets
VOLUME /data

EXPOSE 63001
EXPOSE 63002

COPY . /
ENTRYPOINT ["/entrypoint.sh"]
