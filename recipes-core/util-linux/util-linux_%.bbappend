#
# Copyright (C) 2017 Wind River Systems, Inc.
#

PACKAGES =+ "${PN}-switch_root.static"

do_compile_append_class-target() {
    ${CC} ${CFLAGS} ${LDFLAGS} -static \
        sys-utils/switch_root.o \
        -o switch_root.static
}

do_install_append_class-target() {
    install -d ${D}${sbindir}
    install -m 0700 ${B}/switch_root.static ${D}${sbindir}/switch_root.static
}

FILES_${PN}-switch_root.static = "${sbindir}/switch_root.static"
