# syntax=docker/dockerfile:1
ARG FEDORA_VERSION=45
FROM quay.io/fedora-ostree-desktops/sway-atomic:${FEDORA_VERSION}
LABEL org.opencontainers.image.title="sway-my-way" \
      org.opencontainers.image.description="Fedora 45 Sway Atomic for an Intel desktop"

COPY build_files /tmp/build_files
COPY system_files/ /
RUN bash /tmp/build_files/build.sh
ARG REQUIRE_MODULE_SIGNING=0
ARG MODULE_SIGNING_CERT_SHA256
RUN --mount=type=secret,id=module_key,mode=0444 \
    --mount=type=secret,id=module_cert \
    REQUIRE_MODULE_SIGNING="${REQUIRE_MODULE_SIGNING}" bash /tmp/build_files/virtualbox.sh && \
    dnf5 clean all && \
    rm -rf /tmp/build_files && \
    ostree container commit
