#!/bin/bash
#
# This script is tested on Aarch64 Ubuntu218.04 LTS LK4.9 Xavier NX only. 
# How to run:
# $> \time -ao install_flang.log ./install_flang.sh >& install_flang.log &
#

CPU=`nproc --all`

# ----------
# set MODE_15_6COR
# set cool
# -----------
sudo /usr/sbin/nvpmodel -m 2
sudo /usr/sbin/nvpmodel -d cool
sudo /usr/sbin/nvpmodel -q

# ---------------------------
# Confirm which OS you are in 
# ---------------------------
if [ -e "/etc/lsb-release" ]; then
  OSNOW=UBUNTU
  echo "RUN" && echo "OS $OSNOW is set"
elif [ -e "/etc/redhat-release" ]; then
  OSNOW=CENTOS
  echo "RUN" && echo "OS $OSNOW is set"
elif [ -e "/etc/os-release" ]; then
  OSNOW=DEBIAN
  echo "RUN" && echo "OS $OSNOW is set"
else
  echo "RUN" && echo "OS should be one of UBUNTU, CENTOS or DEBIAN, stop..."
fi

#
# Update CMake > 3.15
#
CMAKE_VERSION=$(cmake --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
if [ $CMAKE_VERSION -lt "31500" ]; then
  echo "-------------------------------------------------------------"
  echo "Your cmake is too old to compile LLVM-12.0.0. Let's renew it."
  echo "-------------------------------------------------------------"
  cd ${HOME}/tmp && aria2c -x10 https://github.com/Kitware/CMake/releases/download/v3.20.1/cmake-3.20.1.tar.gz
  cd ${HOME}/tmp && tar zxvf cmake-3.20.1.tar.gz
  cd ${HOME}/tmp/cmake-3.20.1 && ./bootstrap && make -j${CPU} && sudo make install
else
  echo "-------------------------------------------------------------"
  echo "cmake is already the new version."
  echo "-------------------------------------------------------------"
fi

# ---------------------------------------
# set flang install directory, 
# note that ${PWD}=~/tmp/flang
# ---------------------------------------
#INSTALL_PREFIX=${LLVM_DIR}
cd ${HOME}/tmp
INSTALL_PREFIX="/usr/local/flang_20210324"

if [ ! -d ${INSTALL_PREFIX} ]; then 
  echo "Path \$INSTALL_PREFIX does not exist. "
  mkdir -p ${INSTALL_PREFIX}
else
  echo "clean up before installation."
  sudo rm -rf ${INSTALL_PREFIX}/*
fi

# ---------------------------------------
# set cmake option
# ---------------------------------------
CMAKE_OPTIONS="-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -DLLVM_CONFIG=${INSTALL_PREFIX}/bin/llvm-config \
    -DCMAKE_Fortran_COMPILER=${INSTALL_PREFIX}/bin/flang \
    -DCMAKE_Fortran_COMPILER_ID=Flang \
    -DLLVM_TARGETS_TO_BUILD=AArch64" 

date

# ---------------------------------------
# remake clang with -DLLVM_ENABLE_CLASSIC_FLANG=ON
# ---------------------------------------
if [[ ! -d classic-flang-llvm-project ]]; then
    git clone -b release_100 https://github.com/flang-compiler/classic-flang-llvm-project.git
fi

cd classic-flang-llvm-project
mkdir -p build && cd build
cmake -G Ninja -G "Unix Makefiles"\
  $CMAKE_OPTIONS \
  -DCMAKE_C_COMPILER=/usr/bin/gcc \
  -DCMAKE_CXX_COMPILER=/usr/bin/g++ \
  -DLLVM_ENABLE_CLASSIC_FLANG=ON \
  -DLLVM_ENABLE_PROJECTS="clang;openmp" \
  ../llvm
make -j$CPU
sudo make install

# ---------------------------------------
# Config and compile runtime first
# then
# Confing and compile flang
# ---------------------------------------
cd ${HOME}/tmp
if [[ ! -d flang ]]; then
    git clone -b flang_20210324 https://github.com/flang-compiler/flang.git
fi

(cd flang/runtime/libpgmath
 mkdir -p build && cd build
 cmake -G Ninja -G "Unix Makefiles" \
 $CMAKE_OPTIONS \
 -DCMAKE_CXX_COMPILER=${INSTALL_PREFIX}/bin/clang++ \
 -DCMAKE_C_COMPILER=${INSTALL_PREFIX}/bin/clang \
 ..
 make -j$CPU
 sudo make install)

cd flang
mkdir -p build && cd build
cmake -G Ninja -G "Unix Makefiles" \
$CMAKE_OPTIONS \
-DCMAKE_CXX_COMPILER=${INSTALL_PREFIX}/bin/clang++ \
-DCMAKE_C_COMPILER=${INSTALL_PREFIX}/bin/clang \
-DFLANG_LLVM_EXTENSIONS=ON \
..
make -j$CPU
sudo make install

#
# post install processing
#
grep FLANG_DIR ${HOME}/.bashrc
ret=$?
if [ $ret -eq 1 ] && [ -d ${INSTALL_PREFIX} ]; then
  echo "Updating ${HOME}/.bashrc"
  echo "# " >> ${HOME}/.bashrc
  echo "# flang setting for binary and LD_ & LIBRARY_PATH" >> ${HOME}/.bashrc
  echo "export FLANG_DIR=${INSTALL_PREFIX}">> ${HOME}/.bashrc
  echo "export PATH=\$PATH:\$FLANG_DIR/bin" >>  ${HOME}/.bashrc
  echo "export LIBRARY_PATH=\$LIBRARY_PATH:\$FLANG_DIR/lib" >>  ${HOME}/.bashrc
  echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$FLANG_DIR/lib" >>  ${HOME}/.bashrc
  echo "# " >> ${HOME}/.bashrc
  echo "# " >> ${HOME}/.bashrc
fi

if [ -d ${INSTALL_PREFIX} ]; then
  echo "flang compile done."
  echo "Now you have flag under ${INSTALL_PREFIX}."
  echo "Now you have libpgmath.[so/a] under ${INSTALL_PREFIX}/lib."
  echo "Please check and try flang -help."
  echo ""
else
  echo "[WARNING]"
  echo "flag installation is fail. Check logs."
  echo ""
fi
date

echo "install_flang.sh completed."
date
echo ""
echo ""
echo ""
