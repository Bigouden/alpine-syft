FROM alpine:3.16
LABEL maintainer="Thomas GUIRRIEC <thomas@guirriec.frr>"
COPY apk_packages /
ENV USERNAME='syft'
ENV UID=1000
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN xargs -a /apk_packages apk add --no-cache --update \
    && useradd -l -m -u ${UID} -U -s /bin/sh ${USERNAME} \
    && curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin \
    && chown -R ${USERNAME}:${USERNAME} /usr/local/bin/syft \
    && rm -rf \
         /tmp/* \
         /root/.cache/*
USER ${USERNAME}
HEALTHCHECK CMD syft version || exit 1
ENTRYPOINT ["/bin/sh", "-c", "sleep infinity"]
