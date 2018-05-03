#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of ipp
#   Description: Tests for IPP scriptlets
#   Author: Petr Lautrbach <plautrba@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Copyright (C) 2017 Red Hat, Inc. All rights reserved.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include the BeakerLib environment
. /usr/share/beakerlib/beakerlib.sh

# Set SELinux store
if rlIsRHEL "<=7" || rlIsCentOS "<=7"; then
    SELINUXSTOREPATH=/etc/selinux
else
    SELINUXSTOREPATH=/var/lib/selinux
fi

# Set the full test name
TEST="IPP"

# Package being tested
PACKAGE="IPP"

set_booleans() {
    rlRun "rpm --eval '%selinux_set_booleans -s targeted $*' > run_selinux_set_booleans.sh" 0
    rlRun "bash run_selinux_set_booleans.sh"
}

unset_booleans() {
        rlRun "rpm --eval '%selinux_unset_booleans -s targeted $*' > run_selinux_unset_booleans.sh" 0
        rlRun "bash run_selinux_unset_booleans.sh"
}


rlJournalStart
    rlPhaseStartSetup "Setup"
        rlRun "rlFileBackup --clean ~/.rpmmacros" 0,1 "Backing up ~/.rpmmacros"
        rlRun "sed 's|SELINUXSTOREPATH|$SELINUXSTOREPATH|' macros.selinux-policy >>  ~/.rpmmacros" 0 "Updating ~/.rpmmacros"
        rlRun "rlFileBackup --clean ${SELINUXSTOREPATH}/targeted/rpmbooleans.custom" 0,1 "Backing up ${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        rlRun "rm ${SELINUXSTOREPATH}/targeted/rpmbooleans.custom" 0,1 "Updating ~/.rpmmacros"
        rlRun 'TmpDir=$(mktemp -d)' 0
        pushd $TmpDir
        rlRun "semanage boolean -E > boolean.import" 0 "Backup local boolean modifications"
        rlRun "semanage boolean -D" 0 "Drop local boolean modifications"
    rlPhaseEnd

    rlPhaseStartTest "Test install on a clean system"
        set_booleans secure_mode=1 secure_mode_insmod=1

        rlRun "semanage boolean -E > boolean.local"
        # test if local changes are applied
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode' "boolean.local"
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode_insmod' "boolean.local"
        # check the content of /var/lib/selinux/targeted/rpmbooleans.custom, should be almost empty
        rlAssertNotGrep '\(-1\|--on\) secure_mode' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        rlAssertNotGrep '\(-1\|--on\) secure_mode_insmod' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        # bash
    rlPhaseEnd

    rlPhaseStartTest "Test uninstall on a clean system"
        unset_booleans secure_mode=0 secure_mode_insmod=0

        # test if local changes are removed
        rlRun "semanage boolean -E > boolean.local"
        rlAssertNotGrep 'boolean -m \(-1\|--on\) secure_mode' "boolean.local"
        rlAssertNotGrep 'boolean -m \(-1\|--on\) secure_mode_insmod' "boolean.local"
        rlAssertNotGrep 'secure_mode' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        # bash
        rlRun "semanage boolean -m --off secure_mode" 0 "cleanup"
        rlRun "semanage boolean -m --off secure_mode_insmod" 0 "cleanup"
        rlRun "semanage boolean -D" 0 "cleanup"
    rlPhaseEnd

    rlPhaseStartTest "Test install on a system with secure_mode is already on"
        rlRun "semanage boolean -m --on secure_mode" 0 "Setting secure_mode=on"

        set_booleans secure_mode=1 secure_mode_insmod=1

        rlRun "semanage boolean -E > boolean.local"
        # test if local changes are applied
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode' "boolean.local"
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode_insmod' "boolean.local"
        # check the content of /var/lib/selinux/targeted/rpmbooleans.custom, should be almost empty
        rlAssertGrep '\(-1\|--on\) secure_mode' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        rlAssertNotGrep '\(-1\|--on\) secure_mode_insmod' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        # bash
    rlPhaseEnd

    rlPhaseStartTest "Test uninstall on a system where secure_mode was on before install"

        # bash
        unset_booleans secure_mode=0 secure_mode_insmod=0
        # bash

        # test if local changes are removed
        rlRun "semanage boolean -E > boolean.local"
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode' "boolean.local"
        rlAssertNotGrep 'boolean -m \(-1\|--on\) secure_mode_insmod' "boolean.local"
        rlAssertNotGrep 'secure_mode' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"

        rlRun "semanage boolean -m --off secure_mode" 0 "cleanup"
        rlRun "semanage boolean -m --off secure_mode_insmod" 0 "cleanup"
        rlRun "semanage boolean -D" 0 "cleanup"

    rlPhaseEnd

    rlPhaseStartTest "Test install on a system with secure_mode was changed to off"
        rlRun "semanage boolean -m --off secure_mode" 0 "Setting secure_mode=on"

        set_booleans secure_mode=1 secure_mode_insmod=1

        rlRun "semanage boolean -E > boolean.local"
        # test if local changes are applied
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode' "boolean.local"
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode_insmod' "boolean.local"
        # check the content of /var/lib/selinux/targeted/rpmbooleans.custom, should be almost empty
        rlAssertGrep '\(-0\|--off\) secure_mode' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        rlAssertGrep '\(-0\|--off\) secure_mode_insmod' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        # bash
    rlPhaseEnd

    rlPhaseStartTest "Test uninstall on a system where secure_mode was on before install"

        # bash
        unset_booleans secure_mode=0 secure_mode_insmod=0
        # bash

        # test if local changes are removed
        rlRun "semanage boolean -E > boolean.local"
        rlAssertGrep 'boolean -m \(-0\|--off\) secure_mode' "boolean.local"
        rlAssertGrep 'boolean -m \(-0\|--off\) secure_mode_insmod' "boolean.local"
        rlAssertNotGrep 'secure_mode' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"

        rlRun "semanage boolean -m --off secure_mode" 0 "cleanup"
        rlRun "semanage boolean -m --off secure_mode_insmod" 0 "cleanup"
        rlRun "semanage boolean -D" 0 "cleanup"

    rlPhaseEnd

# ============ Install twice, remove once ======================

    rlPhaseStartTest "Test install twice on a clean system"
        set_booleans secure_mode=1 secure_mode_insmod=1
        set_booleans secure_mode=1 zabbix_can_network=1

        rlRun "semanage boolean -E > boolean.local"
        # test if local changes are applied
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode' "boolean.local"
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode_insmod' "boolean.local"
        rlAssertGrep 'boolean -m \(-1\|--on\) zabbix_can_network' "boolean.local"
        # check the content of /var/lib/selinux/targeted/rpmbooleans.custom, should be almost empty
        rlAssertNotGrep '\(-1\|--on\) secure_mode' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        rlAssertNotGrep '\(-1\|--on\) secure_mode_insmod' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        rlAssertNotGrep '\(-1\|--on\) zabbix_can_network' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        # bash
    rlPhaseEnd

    rlPhaseStartTest "Test uninstall once after install twice"
        unset_booleans secure_mode=0 secure_mode_insmod=0

        # test if local changes are removed
        rlRun "semanage boolean -E > boolean.local"
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode' "boolean.local"
        rlAssertNotGrep 'boolean -m \(-1\|--on\) secure_mode_insmod' "boolean.local"
        rlAssertGrep 'boolean -m \(-1\|--on\) zabbix_can_network' "boolean.local"
        rlAssertGrep 'secure_mode$' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        rlAssertNotGrep 'secure_mode_insmod' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        rlAssertGrep 'zabbix_can_network' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        # bash
        rlRun "semanage boolean -m --off secure_mode" 0 "cleanup"
        rlRun "semanage boolean -m --off secure_mode_insmod" 0 "cleanup"
        rlRun "semanage boolean -m --off zabbix_can_network" 0 "cleanup"
        rlRun "semanage boolean -D" 0 "cleanup"
	rlRun "rm ${SELINUXSTOREPATH}/targeted/rpmbooleans.custom" 0 "cleanup"
    rlPhaseEnd

    rlPhaseStartTest "Test install twice on a system with secure_mode is already on"
        rlRun "semanage boolean -m --on secure_mode" 0 "Setting secure_mode=on"

        set_booleans secure_mode=1 secure_mode_insmod=1
        set_booleans secure_mode=1

        rlRun "semanage boolean -E > boolean.local"
        # test if local changes are applied
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode' "boolean.local"
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode_insmod' "boolean.local"
        # check the content of /var/lib/selinux/targeted/rpmbooleans.custom, should be almost empty
        rlAssertGrep '\(-1\|--on\) secure_mode' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        rlAssertGrep '\(-0\|--off\) secure_mode_insmod' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        # bash
    rlPhaseEnd

    rlPhaseStartTest "Test uninstall once after install twice on a system where secure_mode was on before install"

        unset_booleans secure_mode=0 secure_mode_insmod=0

        # test if local changes are removed
        rlRun "semanage boolean -E > boolean.local"
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode' "boolean.local"
        rlAssertGrep 'boolean -m \(-0\|--off\) secure_mode_insmod' "boolean.local"
        rlAssertGrep '\(-1\|--on\) secure_mode' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        rlAssertNotGrep 'secure_mode_insmod' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"

        rlRun "semanage boolean -m --off secure_mode" 0 "cleanup"
        rlRun "semanage boolean -m --off secure_mode_insmod" 0 "cleanup"
        rlRun "semanage boolean -D" 0 "cleanup"
	rlRun "rm ${SELINUXSTOREPATH}/targeted/rpmbooleans.custom" 0 "cleanup"

    rlPhaseEnd

    rlPhaseStartTest "Test install twice on a system with secure_mode was changed to off"
        rlRun "semanage boolean -m --off secure_mode" 0 "Setting secure_mode=on"

        set_booleans secure_mode=1 secure_mode_insmod=1
        set_booleans secure_mode=1

        rlRun "semanage boolean -E > boolean.local"
        # test if local changes are applied
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode' "boolean.local"
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode_insmod' "boolean.local"
        # check the content of /var/lib/selinux/targeted/rpmbooleans.custom, should be almost empty
        rlAssertGrep '\(-0\|--off\) secure_mode' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        rlAssertGrep '\(-0\|--off\) secure_mode_insmod' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        # bash
    rlPhaseEnd

    rlPhaseStartTest "Test uninstall once after install twice on a system where secure_mode was off before install"

        # bash
        unset_booleans secure_mode=0 secure_mode_insmod=0
        # bash

        # test if local changes are removed
        rlRun "semanage boolean -E > boolean.local"
        rlAssertGrep 'boolean -m \(-1\|--on\) secure_mode' "boolean.local"
        rlAssertGrep 'boolean -m \(-0\|--off\) secure_mode_insmod' "boolean.local"
        rlAssertGrep '\(-0\|--off\) secure_mode' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"
        rlAssertNotGrep 'secure_mode_insmod' "${SELINUXSTOREPATH}/targeted/rpmbooleans.custom"

        rlRun "semanage boolean -m --off secure_mode" 0 "cleanup"
        rlRun "semanage boolean -m --off secure_mode_insmod" 0 "cleanup"
        rlRun "semanage boolean -D" 0 "cleanup"
    rlPhaseEnd

    rlPhaseStartCleanup "Cleanup"
        rlRun "semanage boolean -D" 0 "Clean all boolean changes"
        rlRun "semanage import < boolean.import" 0 "Import local boolean modifications back"
        popd
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlRun "rlFileRestore"
    rlPhaseEnd

rlJournalEnd

# Print the test report
rlJournalPrintText
