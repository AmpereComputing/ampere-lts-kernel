#!/bin/sh
#
# Usage: ampere-lts-centos-build.sh <build-tag>
#
#  where  the build-tag format is YYMMDD where YY is last year digit, MM is month, and DD is day
#
# NOTE: build-tag is auto generated by date if not provided.
#
# These need to match with the definition in .spec file
#
set -x

which rpmbuild &> /dev/null
[ $? -ne 0 ] && echo "rpmbuild tool not found !!!" && exit 1

AMP_TOOLCHAIN_VER=ampere-8.3.0-20191025-dynamic-nosysroot
AMP_COMPILER_LOCALPATH=/opt/amp/${AMP_TOOLCHAIN_VER}/bin
CROSS_COMPILER_NFSPATH=/tools/theobroma/gcc/${AMP_TOOLCHAIN_VER}/bin
NATIVE_COMPILER_NFSPATH=/tools/theobroma/gcc/${AMP_TOOLCHAIN_VER}/native/${AMP_TOOLCHAIN_VER}/bin

MACHINE_TYPE=`uname -m`

if [ ${MACHINE_TYPE} = 'aarch64' ]; then
   export -n CROSS_COMPILE
   if [ -d "$AMP_COMPILER_LOCALPATH" ]; then
        PATH=${AMP_COMPILER_LOCALPATH}:$PATH
        export PATH
   elif [ -d "$NATIVE_COMPILER_NFSPATH" ]; then
        PATH=${NATIVE_COMPILER_NFSPATH}:$PATH
        export PATH
   fi
else
   export CROSS_COMPILE=aarch64-ampere-linux-gnu-
fi

GCC_VERSION=$(${CROSS_COMPILE}gcc -dumpfullversion | sed -e 's/\.\([0-9][0-9]\)/\1/g' -e 's/\.\([0-9]\)/0\1/g' -e 's/^[0-9]\{3,4\}$/&00/')

export XZ_OPT="--threads=0"
TODAY=`date +%Y%m%d`
RELBUILD="${TODAY}"
if [ -n "${1}" ]; then
	RELBUILD=${1}
fi

CENTOSNAMEPREFIX=amp_sw_centos_8.0


CENTOSSPECFILE=SPECS/kernel-ampere-lts-5.4.spec
RPMVERSION=`grep -e "^%define rpmversion" ${CENTOSSPECFILE} | cut -d' ' -f3`
PKGRELEASE=`grep -e "^%define pkgrelease" ${CENTOSSPECFILE} | cut -d' ' -f3`

rpmversion=${RPMVERSION}
pkgrelease=${PKGRELEASE}

# Prepare Linux 5.4 source in SOURCES/
[ ! -f ./linux-5.4.y.zip ] && wget https://github.com/AmpereComputing/ampere-lts-kernel/archive/refs/heads/linux-5.4.y.zip
LINUX_SRC=linux-${rpmversion}-${pkgrelease}
rm -fr ${LINUX_SRC} SOURCES/linux-${rpmversion}-${pkgrelease}.tar.xz
unzip -q linux-5.4.y.zip; mv ampere-lts-kernel-linux-5.4.y ${LINUX_SRC}
echo "# arm64" > SOURCES/kernel-aarch64-altra.config
echo "CONFIG_GCC_VERSION=${GCC_VERSION}" >> SOURCES/kernel-aarch64-altra.config
echo "CONFIG_LOCALVERSION=\"\"" >> SOURCES/kernel-aarch64-altra.config
cat ${LINUX_SRC}/arch/arm64/configs/altra_5.4_defconfig >> SOURCES/kernel-aarch64-altra.config
tar -cJf SOURCES/linux-${rpmversion}-${pkgrelease}.tar.xz ${LINUX_SRC}
rm -fr ${LINUX_SRC} RPMS SRPMS

echo "Building for Linux 5.4 release tag ${RELBUILD}"

#Update build release tag to spec file
#sed -i "s/ buildid \..*/ buildid \.${RELBUILD}+amp/g" ${CENTOSSPECFILE}

rpmbuild --target aarch64 --define "%_topdir `pwd`" --define "buildid .${RELBUILD}+amp" --without debug --with debuginfo --without tools --without perf -ba ${CENTOSSPECFILE}
if [ $? -ne 0 ]; then
  exit $?
fi

cd RPMS/aarch64; md5sum *.rpm > ${CENTOSNAMEPREFIX}-${RELBUILD}_md5sum.txt; cd -
cd RPMS/; tar -cJf ../${CENTOSNAMEPREFIX}-${RELBUILD}-${rpmversion}.tar.xz aarch64;cd -
tar -cJf ${CENTOSNAMEPREFIX}-${RELBUILD}-${rpmversion}.src.tar.xz SRPMS

rm -rf RPMS SRPMS


CENTOSSPECFILE=SPECS/kernel-ampere-lts-5.10.spec
RPMVERSION=`grep -e "^%define rpmversion" ${CENTOSSPECFILE} | cut -d' ' -f3`
PKGRELEASE=`grep -e "^%define pkgrelease" ${CENTOSSPECFILE} | cut -d' ' -f3`

rpmversion=${RPMVERSION}
pkgrelease=${PKGRELEASE}

# Prepare Linux 5.10 source in SOURCES/
[ ! -f ./linux-5.10.y.zip ] && wget https://github.com/AmpereComputing/ampere-lts-kernel/archive/refs/heads/linux-5.10.y.zip
LINUX_SRC=linux-${rpmversion}-${pkgrelease}
rm -fr ${LINUX_SRC} SOURCES/linux-${rpmversion}-${pkgrelease}.tar.xz
unzip -q ./linux-5.10.y.zip; mv ampere-lts-kernel-linux-5.10.y ${LINUX_SRC}
echo "# arm64" > SOURCES/kernel-aarch64-altra.config
echo "CONFIG_GCC_VERSION=${GCC_VERSION}" >> SOURCES/kernel-aarch64-altra.config
echo "CONFIG_LOCALVERSION=\"\"" >> SOURCES/kernel-aarch64-altra.config
cat ${LINUX_SRC}/arch/arm64/configs/altra_5.10_defconfig >> SOURCES/kernel-aarch64-altra.config
tar -cJf SOURCES/linux-${rpmversion}-${pkgrelease}.tar.xz ${LINUX_SRC}
rm -fr ${LINUX_SRC} RPMS SRPMS

echo "Building for Linux 5.10 release tag ${RELBUILD}"

#Update build release tag to spec file
#sed -i "s/ buildid \..*/ buildid \.${RELBUILD}+amp/g" ${CENTOSSPECFILE}

rpmbuild --target aarch64 --define "%_topdir `pwd`" --define "buildid .${RELBUILD}+amp" --without debug --with debuginfo --without tools --without perf -ba ${CENTOSSPECFILE}
if [ $? -ne 0 ]; then
  exit $?
fi

cd RPMS/aarch64; md5sum *.rpm > ${CENTOSNAMEPREFIX}-${RELBUILD}_md5sum.txt; cd -
cd RPMS/; tar -cJf ../${CENTOSNAMEPREFIX}-${RELBUILD}-${rpmversion}.tar.xz aarch64;cd -
tar -cJf ${CENTOSNAMEPREFIX}-${RELBUILD}-${rpmversion}.src.tar.xz SRPMS

rm -rf RPMS SRPMS
