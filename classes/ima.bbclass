#
# Copyright (C) 2017 Wind River Systems, Inc.
#

inherit package

# XXX: Using UKS causes recursive dependency
#inherit user-key-store

PACKAGEFUNCS =+ "package_ima_hook"

# security.ima is generated during the RPM build, and the base64-encoded
# value is written during RPM installation. In addition, if the private
# key is deployed on board, re-sign the updated files during RPM
# installation in higher priority.
python package_ima_hook() {
    packages = d.getVar('PACKAGES', True)
    pkgdest = d.getVar('PKGDEST', True)

    pkg_blacklist = ('dbg', 'dev', 'doc', 'locale', 'staticdev')

    import base64, pipes

    for pkg in packages.split():
        if (pkg.split('-')[-1] in pkg_blacklist) is True:
            continue

        bb.note("Writing IMA %%post hook for %s ..." % pkg)

        pkgdestpkg = os.path.join(pkgdest, pkg)

        cmd = 'evmctl ima_sign --rsa --sigfile --key ${IMA_KEYS_DIR}/ima_privkey.pem '
        sig_list = []
        pkg_sig_list = []

        for _ in pkgfiles[pkg]:
            bb.note("Preparing to sign %s ..." % _)

            sh_name = pipes.quote(_)
            rc, res = oe.utils.getstatusoutput(cmd + sh_name)
            if rc:
                bb.fatal('Calculate IMA signature for %s failed with exit code %s:\n%s' % \
                    (_, rc, res if res else ""))

            with open(_ + '.sig', 'r') as f:
                s = base64.b64encode(f.read()) + ':'
                sig_list.append(s + os.sep + os.path.relpath(sh_name, pkgdestpkg))

            os.remove(_ + '.sig')

        ima_sig_list = ' '.join(sig_list)

        # When the statically linked binary is updated, use the
        # dynamically linked one to resign or set. This situation
        # occurs in runtime only.
        setfattr_bin = 'setfattr.static'
        evmctl_bin = 'evmctl.static'
        # We don't want to create a statically linked echo program
        # any more.
        safe_echo = '1'
        if pkg == 'attr-setfattr.static':
            setfattr_bin = 'setfattr'
        elif pkg == 'ima-evm-utils-evmctl.static':
            evmctl_bin = 'evmctil'
        elif pkg == 'coreutils':
            safe_echo = '0'

        # The %post is dynamically constructed according to the currently
        # installed package and enviroment.
        postinst = r'''#!/bin/sh

# %post hook for IMA appraisal
ima_resign=0
sig_list="''' + ima_sig_list + r'''"

if [ -z "$D" ]; then
    evmctl_bin="${sbindir}/''' + evmctl_bin + r'''"
    setfattr_bin="${bindir}/''' + setfattr_bin + r'''"

    [ -f "/etc/keys/privkey_evm.pem" -a -x "$evmctl_bin" ] && \
        ima_resign=1

    safe_echo="''' + safe_echo + r'''"

    cond_print()
    {
        [ $safe_echo = "1" ] && echo $1
    }

    for entry in $sig_list; do
        old_IFS="$IFS"
        IFS=":"

        tokens=""
        for token in $entry; do
            tokens="$tokens$token "
        done

        IFS="$old_IFS"

        for sig in $tokens; do
            break
        done

        f="$token"

        # IMA appraisal is only applied to the regular file
        [ ! -f "$f" ] && {
            true
            continue
        }

        if [ $ima_resign -eq 0 ]; then
            cond_print "Setting up security.ima for $f ..."

            ! "$setfattr_bin" -n security.ima -v "0s$sig" "$f" && {
                err=$?
                cond_print "Unable to set up security.ima for $f (err: $err)"
                exit 1
            }
        else
            cond_print "IMA signing for $f ..."

            ! "$evmctl_bin" ima_sign --rsa "$f" && {
                err=$?
                cond_print "Unable to sign $f (err: $err)"
                exit 1
            }
        fi
    done
fi

'''
        postinst = postinst + (d.getVar('pkg_postinst_%s' % pkg, True) or '')
        d.setVar('pkg_postinst_%s' % pkg, postinst)
}
