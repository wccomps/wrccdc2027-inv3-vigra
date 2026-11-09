# Builds the stock OpenWrt x86-64 image plus a few packages and everything in
# files/, using OpenWrt's official Image Builder container.
#
#   make        -> build/openwrt-vigra.raw
#
# terraform/ uploads build/openwrt-vigra.raw to Proxmox as the VM's disk.

OPENWRT_VERSION ?= 25.12.6
IMAGEBUILDER    := openwrt/imagebuilder:x86-64-$(OPENWRT_VERSION)

# only its hash goes into the image
ROOT_PASSWORD ?= SMBlyRequired!

# openssh-server replaces dropbear, which can't do SSH certificates (black team CA)
# qemu-ga: Proxmox shows the VM's IPs and can shut it down cleanly
# -odhcpd-ipv6only: no IPv6 RA/DHCPv6 on the LAN
PACKAGES := openssh-server openssh-sftp-server qemu-ga -dropbear -odhcpd-ipv6only

IMAGE := build/openwrt-vigra.raw

.PHONY: all clean
all: $(IMAGE)

$(IMAGE): Makefile $(shell find files -type f)
	rm -rf build && mkdir -p build/files build/bin
	cp -r files/. build/files/
	# bake in a password hash, not the password itself
	HASH=$$(openssl passwd -6 "$(ROOT_PASSWORD)") && \
		sed -i "s|@ROOT_PASSWORD_HASH@|$$HASH|" build/files/etc/uci-defaults/99-bootstrap
	docker run --rm --user "$$(id -u):$$(id -g)" \
		-v "$(CURDIR)/build/files:/files:ro" -v "$(CURDIR)/build/bin:/out" \
		$(IMAGEBUILDER) \
		make image PROFILE=generic PACKAGES="$(PACKAGES)" FILES=/files BIN_DIR=/out
	# OpenWrt appends signature data after the gzip stream, so gunzip exits 2 on success
	gunzip -c build/bin/openwrt-$(OPENWRT_VERSION)-x86-64-generic-ext4-combined.img.gz > $@ || [ $$? -eq 2 ]

clean:
	rm -rf build
