#!/bin/bash
#
# This script is tested on Aarch64 Ubuntu218.04 LTS LK4.9 Xavier NX only. 
# How to run:
# $> \time -ao install_llvm.log ./install_llvm.sh >& install_llvm.log &
#

CPU=`nproc --all`

# ----------
# set MODE_15_6COR
# set cool
# -----------
sudo /usr/sbin/nvpmodel -m 2
sudo /usr/sbin/nvpmodel -d cool
sudo /usr/sbin/nvpmodel -q


# ------------------------
# check your clang version
# ------------------------
which clang
ret=$?
if [ $ret -eq 0 ]; then
  CLANG_VERSION=$(clang --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
  if [ $CLANG_VERSION -eq "120000" ]; then
    echo "You have already had LLVM-12.0.0."
    echo "Skip installation. Program exit."
    exit
  else
    echo "You have already had LLVM clang but it is not target version=$CLANG_VERSION."
    echo "Proceed LLVM-12.0.0 install."
  fi
else
  echo "LLVM-clang is not found in your system."
  echo "Proceed LLVM-12.0.0 install."
fi

#export CXX="/usr/bin/clang++"
#export CC="/usr/bin/clang"
export CXX="/usr/bin/g++-7"
export CC="/usr/bin/gcc-7"


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
#
# install LLVM 1200
#
cd ${HOME}/tmp && rm -rf llvm*
cd ${HOME}/tmp && git clone --depth 1 https://github.com/llvm/llvm-project.git -b llvmorg-12.0.0 && \
  cd llvm-project && mkdir -p build && cd build
echo "start llvm_1200 build"
date
if [ $OSNOW = "UBUNTU" ] ||  [ $OSNOW = "DEBIAN" ]; then 
  cmake -G Ninja -G "Unix Makefiles"\
    -DCMAKE_C_COMPILER=$CC \
    -DCMAKE_CXX_COMPILER=$CXX \
    -DLLVM_ENABLE_PROJECTS="clang;libcxx;libcxxabi;lld;openmp" \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DLLVM_TARGETS_TO_BUILD="AArch64" \
    -DCMAKE_INSTALL_PREFIX="/usr/local/llvm_1200" \
    ../llvm && make -j${CPU} && sudo make install
elif [ $OSNOW = "CENTOS" ]; then
  cmake -G Ninja -G "Unix Makefiles" \
    -DCMAKE_C_COMPILER=$CC \
    -DCMAKE_CXX_COMPILER=$CXX \
    -DLLVM_ENABLE_PROJECTS="clang;libcxx;libcxxabi;lld;openmp" \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DLLVM_TARGETS_TO_BUILD="AArch64" \
    -DCMAKE_INSTALL_PREFIX="/usr/local/llvm_1200" \
    ../llvm && make -j${CPU} && sudo make install
else
  echo "please set right choise in OS=$OSNOW.."
fi
echo "end llvm_1200 build"
date
make clean

#
# post install processing
#
grep LLVM_DIR ${HOME}/.bashrc
ret=$?
if [ $ret -eq 1 ] && [ -d /usr/local/llvm_1200/bin ]; then
  echo "Updating ${HOME}/.bashrc"
  echo "# " >> ${HOME}/.bashrc
  echo "# LLVM setting for binary and LD_ & LIBRARY_PATH" >> ${HOME}/.bashrc
  echo "export LLVM_DIR=/usr/local/llvm_1200">> ${HOME}/.bashrc
  echo "export PATH=\$LLVM_DIR/bin:\$PATH" >>  ${HOME}/.bashrc
  echo "export LIBRARY_PATH=\$LLVM_DIR/lib:\$LIBRARY_PATH" >>  ${HOME}/.bashrc
  echo "export LD_LIBRARY_PATH=\$LLVM_DIR/lib:\$LD_LIBRARY_PATH" >>  ${HOME}/.bashrc
  echo "# " >> ${HOME}/.bashrc
  echo "# " >> ${HOME}/.bashrc
fi

if [ -f /usr/local/llvm_1200/bin/lld ]; then
  sudo rm /usr/bin/ld
  sudo ln -s /usr/local/llvm_1200/bin/lld /usr/bin/ld
  echo "/usr/bin/ld is replaced by lld."
  sudo ldconfig -v
else
  echo "ERROR : lld not found under /usr/local/llvm_1200/bin/"
  echo "ERROR : Please check if your llvm build is ok. Program exit."
  exit
fi

echo "install_llvm.sh completed."
date
echo ""
echo ""
echo ""
