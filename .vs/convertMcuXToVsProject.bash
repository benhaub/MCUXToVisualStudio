#! /bin/bash
###############################################################################
# Author: Ben Haubrich                                                        #
# File: convertMcuXToVsProject.bash                                           #
# Date: February 2nd, 2022                                                    #
# Synopsis: Top level shell script to convert a MCU expresso project to a     #
# Visual Studo project                                                        #
###############################################################################

source copyMcuXpressoFiles.bash
source setupVsFiles.bash
source parseMcuXpressoDebugConfig.bash
source parseMcuXpressoBuildOutput.bash
source getDebuggerPaths.bash
source getMcuXpressoPaths.bash

help() {
  echo "Usage convertMcuXToVsProject.bash <pathToMcuXpressoInstall> <pathToMcuXpressoProject> <buildLog> <buildType>"
  echo "buildType is either Debug or Release"
  echo "e.g. ./convertMcuXToVsProject.bash /mnt/c/nxp/MCUXpressoIDE_11.3.1_5262 /mnt/d/Repos/BIC/BicEcu build.txt Debug"
}

if [ $# -lt 4 ]; then
  help
  exit 1
elif [ ! -d $1 ]; then
  echo "Could not find $1"
  exit 1
elif [ ! -d $2 ]; then
  echo "Could not find $2"
  exit 1
elif [ ! -f $3 ]; then
  echo "could not find $3"
fi

DEBUG_CONFIG=`ls ${2} | egrep .*Debug.launch`
if [ $? -ne 0 ]; then
  echo "Could not find debug launch configuration file"
  exit 1
fi
ls $2 | egrep --silent .*\.jlink
if [ $? -ne 0 ]; then
  echo "Warning. Could not find jlink debugger script."
fi

copyMcuXpressoFiles $2
if [ $? -ne 0 ]; then
  echo "Failed to copy MCUXpresso project files"
  exit 1
else
  echo "Done copying MCUxpresso files"
fi

setupVsFiles
if [ $? -ne 0 ]; then
  echo "Could not set up visual studio files"
  exit 1
else
  echo "Done setting up VS files"
fi

parseMcuXpressoDebugConfig "${2}/${DEBUG_CONFIG}"
if [ $? -ne 0 ]; then
  echo "Failed to parse debug configuration file"
  exit 1
else
  echo "Done reading debug configuration file"
fi

parseMcuXpressoBuildOutput $3 $4
if [ $? -ne 0 ]; then
  echo "Failed to parse build output"
  exit 1
else
  echo "Done reading build output"
fi

getDebuggerPaths "${2}/$DEBUG_CONFIG"
if [ $? -ne 0 ]; then
  echo "Failed to get paths to debugging executables"
  exit 1
else
  echo "Done finding debug executables"
fi

getMcuXpressoPaths "$1" "$2"
if [ $? -ne 0 ]; then
  echo "Failed to get paths to MCUXpresso files"
  exit 1
else
  echo "Done finding MCUXpresso files"

echo "Conversion complete"
