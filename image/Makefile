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
# luci: web UI (the release images ship it, Image Builder doesn't by default)
# -odhcpd-ipv6only: no IPv6 RA/DHCPv6 on the LAN
#
# RANGE TARGET: openssh is pinned to 10.6_p1-r2, the build 25.12.6 shipped
# before the Nov 2026 fix for CVE-2026-123158 ("SSHole", password-auth bypass
# for passwordless accounts on musl without PAM). The feeds now only serve the
# patched 10.6_p2, so the vulnerable .apks are vendored in pkgs/ and installed
# as local packages. Bump these to 10.6_p2-r1 (or drop the pin) to patch.
PACKAGES := openssh-server=10.6_p1-r2 openssh-sftp-server=10.6_p1-r2 \
            qemu-ga luci -dropbear -odhcpd-ipv6only shadow-chage

IMAGE := build/openwrt-vigra.raw

.PHONY: all clean
all: $(IMAGE)

$(IMAGE): Makefile $(wildcard pkgs/*.apk) $(shell find files -type f)
	rm -rf build && mkdir -p build/files build/bin
	cp -r files/. build/files/
	# bake in a password hash, not the password itself
	HASH=$$(openssl passwd -6 "$(ROOT_PASSWORD)") && \
		sed -i "s|@ROOT_PASSWORD_HASH@|$$HASH|" build/files/etc/uci-defaults/99-bootstrap
	# vendored .apks become a local feed; apk picks them for the pinned versions.
	# The sed fixes an Image Builder bug in FormatPackages: pkg_ver isn't reset
	# for unversioned packages, so a pinned package poisons every later one.
	docker run --rm --user "$$(id -u):$$(id -g)" \
		-v "$(CURDIR)/build/files:/files:ro" -v "$(CURDIR)/build/bin:/out" \
		-v "$(CURDIR)/pkgs:/pkgs:ro" \
		$(IMAGEBUILDER) \
		sh -c 'cp /pkgs/*.apk packages/ && \
			sed -i "s|.*findstring =,.*pkg_ver:==.*|  \$$(if \$$(findstring =,\$$(pkg)),\$$(eval pkg_ver:==\$$(lastword \$$(subst =, ,\$$(pkg)))),\$$(eval pkg_ver:=))|" Makefile && \
			make image PROFILE=generic PACKAGES="$(PACKAGES)" FILES=/files BIN_DIR=/out'
	# OpenWrt appends signature data after the gzip stream, so gunzip exits 2 on success
	gunzip -c build/bin/openwrt-$(OPENWRT_VERSION)-x86-64-generic-ext4-combined.img.gz > $@ || [ $$? -eq 2 ]

clean:
	rm -rf build
