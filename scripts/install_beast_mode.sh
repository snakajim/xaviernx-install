#!/bin/bash
#
# This script is tested on Aarch64 Ubuntu218.04 LTS LK4.9 Xavier NX only. 
#
# How to use:
# To set beast
# $> ./install_east_mode.sh beast
# To restore default
# $> ./install_east_mode.sh default
#

if [ $# -gt 2 ]; then
  echo "bad argument."
  echo "number of args should be 1, but $#."
  exit 1
fi

if [ $# = 0 ] || [ $1 == "beast" ]; then
  echo "setting beast mode."
else if [ $1 == "default" ]; then
  echo "restore default"
else
  echo "bad argument."
  echo "arg should be either beast or default, but $1."
  exit 1
fi

