#! /bin/bash
###############################################################################
# Author: Ben Haubrich                                                        #
# File: getMcuExpressoPaths.bash                                              #
# Date: January 23rd, 2021                                                    #
# Synopsis: Find the paths to MCU Expresso executables                        #
###############################################################################

source common.bash

help() {
  echo "Usage getMcuExpressoPaths.bash <pathToMcuExpressoInstallRoot>"
}

getMcuExpressoPaths() {

  if [ $# -lt 1 ]; then
    help
    exit 1
  fi

  ####Get the path to the debugger
  if [ -x "${1}/${PATH_TO_BIN}/${TOOLCHAIN_PREFIX}${GDB}" ]; then
    TEMPORARY_FILE_NAME=`createTemporaryFilename`
    PATH_TO_GDB=${1}/${PATH_TO_BIN}/${TOOLCHAIN_PREFIX}${GDB}
    PATH_TO_GDB=`convertToWindowsDriveLetter $PATH_TO_GDB`
    PATH_TO_GDB=`convertToWindowsPathSeparator $PATH_TO_GDB`
    echo "      \"miDebuggerPath\": \""${PATH_TO_GDB}"\"," >> $TEMPORARY_FILE_NAME
    #Escape the windows path separators so we can read the line back properly
    doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME
    #Insert the string into launch.vs.json
    LINE_NUMBER=`egrep -n -m1 "miDebuggerPath" launch.vs.json | cut -f1 -d ":"`
    sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" launch.vs.json
    #Double up the path separators for visual studio compatability
    doubleUpWindowsPathSeparators launch.vs.json $LINE_NUMBER
  else
    echo "Could not find $GDB in ${1}/${PATH_TO_BIN}/${TOOLCHAIN_PREFIX}${GDB}"
    echo "Enter the full path to $GDB"
    read
    PATH_TO_GDB=$REPLY
    PATH_TO_GDB=`convertToWindowsDriverLetter $PATH_TO_GDB`
    PATH_TO_GDB=`convertToWindowsPathSeparator $PATH_TO_GDB`
    echo "      \"miDebuggerPath\": \""${PATH_TO_GDB}"\"," >> $TEMPORARY_FILE_NAME
    doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME
    #Insert the string into launch.vs.json
    LINE_NUMBER=`egrep -n -m1 "miDebuggerPath" launch.vs.json | cut -f1 -d ":"`
    sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" launch.vs.json
    #Double up the path separators for visual studio compatability
    doubleUpWindowsPathSeparators launch.vs.json $LINE_NUMBER
  fi

  ####Get the path to the C compiler
  if [ -x "${1}/${PATH_TO_BIN}/${TOOLCHAIN_PREFIX}${GCC}" ]; then
    PATH_TO_GCC=${1}/${PATH_TO_BIN}/${TOOLCHAIN_PREFIX}${GCC}
    PATH_TO_GCC=`convertToWindowsDriveLetter $PATH_TO_GCC`
    PATH_TO_GCC=`convertToWindowsPathSeparator $PATH_TO_GCC`
    echo "          \"value\": \""${PATH_TO_GCC}"\"," >> $TEMPORARY_FILE_NAME
    #Escape the windows path separators so we can read the line back properly
    doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME
    #Insert the string into ../CMakeSettings.json
    LINE_NUMBER=`egrep -n -m1 "CMAKE_C_COMPILER" ../CMakeSettings.json | cut -f1 -d ":"`
    let LINE_NUMBER++
    sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" ../CMakeSettings.json
    #Double up the path separators for visual studio compatability
    doubleUpWindowsPathSeparators ../CMakeSettings.json $LINE_NUMBER
  else
    echo "Could not find $GCC in ${1}/${PATH_TO_BIN}/${TOOLCHAIN_PREFIX}${GCC}"
    echo "Enter the full path to $GCC"
    read
    PATH_TO_GCC=$REPLY
    PATH_TO_GCC=`convertToWindowsDriveLetter $PATH_TO_GCC`
    PATH_TO_GCC=`convertToWindowsPathSeparator $PATH_TO_GCC`
    echo "          \"value\": \""${PATH_TO_GCC}"\"," >> $TEMPORARY_FILE_NAME
    doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME
    #Insert the string into ../CMakeSettings.json
    LINE_NUMBER=`egrep -n -m1 "CMAKE_C_COMPILER" ../CMakeSettings.json | cut -f1 -d ":"`
    let LINE_NUMBER++
    sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" ../CMakeSettings.json
    #Double up the path separators for visual studio compatability
    doubleUpWindowsPathSeparators ../CMakeSettings.json $LINE_NUMBER
  fi

  ####Get the path to the C++ compiler
  if [ -x "${1}/${PATH_TO_BIN}/${TOOLCHAIN_PREFIX}${GXX}" ]; then
    PATH_TO_CXX=${1}/${PATH_TO_BIN}/${TOOLCHAIN_PREFIX}${GXX}
    PATH_TO_CXX=`convertToWindowsDriveLetter $PATH_TO_CXX`
    PATH_TO_CXX=`convertToWindowsPathSeparator $PATH_TO_CXX`
    echo "          \"value\": \""${PATH_TO_CXX}"\"," >> $TEMPORARY_FILE_NAME
    #Escape the windows path separators so we can read the line back properly
    doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME
    #Insert the string into ../CMakeSettings.json
    LINE_NUMBER=`egrep -n -m1 "CMAKE_CXX_COMPILER" ../CMakeSettings.json | cut -f1 -d ":"`
    let LINE_NUMBER++
    sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" ../CMakeSettings.json
    #Double up the path separators for visual studio compatability
    doubleUpWindowsPathSeparators ../CMakeSettings.json $LINE_NUMBER
  else
    echo "Could not find $GXX in ${1}/${PATH_TO_BIN}/${TOOLCHAIN_PREFIX}${GXX}"
    echo "Enter the full path to $GXX"
    read
    PATH_TO_CXX=$REPLY
    PATH_TO_CXX=`convertToWindowsDriveLetter $PATH_TO_CXX`
    PATH_TO_CXX=`convertToWindowsPathSeparator $PATH_TO_CXX`
    echo "          \"value\": \""${PATH_TO_CXX}"\"," >> $TEMPORARY_FILE_NAME
    doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME
    #Insert the string into ../CMakeSettings.json
    LINE_NUMBER=`egrep -n -m1 "CMAKE_CXX_COMPILER" ../CMakeSettings.json | cut -f1 -d ":"`
    let LINE_NUMBER++
    sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" ../CMakeSettings.json
    #Double up the path separators for visual studio compatability
    doubleUpWindowsPathSeparators ../CMakeSettings.json $LINE_NUMBER
  fi

  ####Get the path to objcpy
  if [ -x "${1}/${PATH_TO_BIN}/${TOOLCHAIN_PREFIX}${OBJCPY}" ]; then
    PATH_TO_OBJCPY=${1}/${PATH_TO_BIN}/${TOOLCHAIN_PREFIX}${OBJCPY}
    PATH_TO_OBJCPY=`convertToWindowsDriveLetter $PATH_TO_OBJCPY`
    PATH_TO_OBJCPY=`convertToWindowsPathSeparator $PATH_TO_OBJCPY`
    echo "  \"objCpy\": \""${PATH_TO_OBJCPY}"\"," >> $TEMPORARY_FILE_NAME
    #Escape the windows path separators so we can read the line back properly
    doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME
    #Insert the string into ../CMakeSettings.json
    LINE_NUMBER=`egrep -n -m1 "objCpy" tasks.vs.json | cut -f1 -d ":"`
    sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" tasks.vs.json
    #Double up the path separators for visual studio compatability
    doubleUpWindowsPathSeparators tasks.vs.json $LINE_NUMBER
  else
    echo "Could not find $GXX in ${1}/${PATH_TO_BIN}/${TOOLCHAIN_PREFIX}${OBJCPY}"
    echo "Enter the full path to $OBJCPY"
    read
    PATH_TO_OBJCPY=$REPLY
    PATH_TO_OBJCPY=`convertToWindowsDriveLetter $PATH_TO_OBJCPY`
    PATH_TO_OBJCPY=`convertToWindowsPathSeparator $PATH_TO_OBJCPY`
    echo "  \"objCpy\": \""${PATH_TO_OBJCPY}"\"," >> $TEMPORARY_FILE_NAME
    doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME
    #Insert the string into ../tasks.vs.json
    LINE_NUMBER=`egrep -n -m1 "objCpy" task.vs.json | cut -f1 -d ":"`
    let LINE_NUMBER++
    sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" tasks.vs.json
    #Double up the path separators for visual studio compatability
    doubleUpWindowsPathSeparators tasks.vs.json $LINE_NUMBER
  fi

  rm $TEMPORARY_FILE_NAME

  return 0
}

#For testing
#getMcuExpressoPaths /mnt/c/nxp/MCUXpressoIDE_11.3.1_5262
