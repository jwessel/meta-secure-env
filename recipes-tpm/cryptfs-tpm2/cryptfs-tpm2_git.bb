SUMMARY = "A tool used to create, persist, evict a passphrase \
for full-disk-encryption with TPM 2.0"
DESCRIPTION = " \
This project provides with an implementation for \
creating, persisting and evicting a passphrase with TPM 2.0. \
The passphrase and its associated primary key are automatically \
created by RNG engine in TPM. In order to avoid saving the \
context file, the created passphrase and primary key are always \
persistent in TPM. \
"
SECTION = "devel"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://${S}/LICENSE;md5=af9aa760caa1532b4f5c9874d4e8c753"

SRC_URI = " \
    git://github.com/WindRiver-OpenSourceLabs/cryptfs-tpm2.git \
"
SRCREV = "200994ce11ddb6351a3c95d5ef5914ec2a53d50e"
PV = "0.4.2+git${SRCPV}"

DEPENDS += "tpm2.0-tss"
RDEPENDS_${PN} += "libtss2 libtctisocket"

PARALLEL_MAKE = ""

S = "${WORKDIR}/git"

EXTRA_OEMAKE = " \
    prefix="${prefix}" \
    sbindir="${sbindir}" \
    libdir="${libdir}" \
    includedir="${includedir}" \
    tpm2_tss_includedir="${STAGING_LIBDIR}" \
    tpm2_tss_libdir="${STAGING_INCDIR}" \
    CC="${CC}" \
    EXTRA_CFLAGS="${CFLAGS}" \
    EXTRA_LDFLAGS="${LDFLAGS}" \
"

do_install() {
    oe_runmake install DESTDIR="${D}"
}

FILES_${PN} = "\
    ${sbindir} \
    ${libdir} \
"
