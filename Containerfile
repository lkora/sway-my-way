# Base Image
# (You can also use 'ghcr.io/ublue-os/base-main:latest' for pre-configured multimedia codecs)
FROM quay.io/fedora-ostree-desktops/sway-atomic:latest

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

# Copy configuration and build scripts into the container
COPY build_files /tmp/build_files
COPY system_files /


# Execute system-level configurations and package installations
RUN chmod +x /tmp/build_files/build.sh && \
    /tmp/build_files/build.sh && \
    rm -rf /tmp/build_files

# Commit changes to ostree/bootc structure
RUN ostree container commit