# kics-scan disable=f2f903fb-b977-461e-98d7-b3e2185c6118,9513a694-aa0d-41d8-be61-3271e056f36b,d3499f6d-1651-41bb-a9a7-de925fea487b,ae9c56a6-3ed1-4ac0-9b54-31267f51151d,4b410d24-1cbe-4430-a632-62c9a931cf1c

ARG ALPINE_VERSION="3.21"

FROM alpine:${ALPINE_VERSION} AS builder
COPY --link apk_packages /tmp/
# checkov:skip=CKV_DOCKER_4
ADD --link --chmod=755 https://raw.githubusercontent.com/anchore/syft/main/install.sh /tmp
# hadolint ignore=DL3018
RUN --mount=type=cache,id=builder_apk_cache,target=/var/cache/apk \
    apk add gettext-envsubst

FROM alpine:${ALPINE_VERSION}
LABEL maintainer="Thomas GUIRRIEC <thomas@guirriec.frr>"
ENV USERNAME="syft"
ENV UID=1000
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
# hadolint ignore=DL3013,DL3018,DL3042,SC2006
RUN --mount=type=bind,from=builder,source=/usr/bin/envsubst,target=/usr/bin/envsubst \
    --mount=type=bind,from=builder,source=/usr/lib/libintl.so.8,target=/usr/lib/libintl.so.8 \
    --mount=type=bind,readwrite,from=builder,source=/tmp,target=/tmp \
    --mount=type=cache,id=apk_cache,target=/var/cache/apk \
    apk --update add `envsubst < /tmp/apk_packages` \
    && useradd -l -m -u ${UID} -U -s /bin/sh ${USERNAME} \
    && /tmp/install.sh -b /usr/local/bin \
    && chown -R "${USERNAME}":"${USERNAME}" /usr/local/bin/syft
USER ${USERNAME}
HEALTHCHECK CMD syft version || exit 1
ENTRYPOINT ["/bin/sh", "-c", "sleep infinity"]
