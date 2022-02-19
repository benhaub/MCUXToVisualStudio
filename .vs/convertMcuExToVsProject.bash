#! /bin/bash
###############################################################################
# Author: Ben Haubrich                                                        #
# File: getMcuExpressoPaths.bash                                              #
# Date: February 2nd, 2021                                                    #
# Synopsis: Top level shell script to convert a MCU expresso project to a     #
# Visual Studo project                                                        #
###############################################################################

source parseMcuExpressoDebugConfig.bash
source parseMcuExpressoBuildOutput.bash
source getDebuggerPaths.bash
source getMcuExpressoPaths.bash

help() {
  echo "Usage convertMcuExToVsProject.bash <pathToMcuExpressoInstall> <pathToMcuExpressoProject> <buildLog>"
  echo "e.g. ./convertMcuExToVsProject.bash /mnt/c/nxp/MCUXpressoIDE_11.3.1_5262 /mnt/d/Repos/BIC/BicEcu build.txt"
}

if [ $# -lt 2 ]; then
  help
  exit 1
fi

DEBUG_CONFIG=`ls ${2} | egrep .*Debug.launch`
#parseMcuExpressoDebugConfig "${2}/${DEBUG_CONFIG}"
#if [ $? -ne 0 ]; then
#  echo "Failed to parse debug configuration file"
#  exit 1
#else
#  echo "Done reading debug configuration file"
#fi
#
parseMcuExpressoBuildOutput $3 $1
if [ $? -ne 0 ]; then
  echo "Failed to parse build output"
  exit 1
else
  echo "Done reading build output"
fi
#
#getDebuggerPaths "${2}/$DEBUG_CONFIG"
#if [ $? -ne 0 ]; then
#  echo "Failed to get paths to debugging executables"
#  exit 1
#else
#  echo "Done finding debug executables"
#fi
#
#getMcuExpressoPaths "$1" "$2"
#if [ $? -ne 0 ]; then
#  echo "Failed to get paths to MCU Expresso files"
#  exit 1
#else
#  echo "Done finding MCUXpresso files"
#fi

echo "Conversion complete"
