#! /bin/bash
###############################################################################
# Author: Ben Haubrich                                                        #
# File: getDebuggerPaths.bash                                                 #
# Date: January 23rd, 2021                                                    #
# Synopsis: Find the paths to the debugger executables                        #
###############################################################################

source common.bash

#Note. Doubling up of windows path separators is a pain. Outputing the string
#to a file first, doubling, then using sed to replace the line eliminates the
#double path separator (\\) forcing the need to do it twice. The way it is done
#below may seem strange but it's the only way I could get it to work. That
#includes the times where I used the sed command directly instead of using the
#function I made.

help() {
  echo "Usage getDebuggerPaths.bash <debugConfigurationFile>"
}

getDebuggerPaths() {

  if [ $# -lt 1 ]; then
    help
    exit 1
  fi

  TEMPORARY_FILE_NAME=`createTemporaryFilename`
  if [ $? -ne 0 ]; then
    echo "Could not create temporary file"
    exit 1
  fi

  ####If probe type is JLINK. Look for SEGGER executables.
  egrep 'probe.name' "$1" | egrep 'J-Link'
  if [ $? -eq 0 ]; then
    echo "Could not find debug config file"
  fi

  if [ $? -eq 0 ]; then
    SEGGER_PATH=`find /mnt/c/Program\ Files* -iname segger -type d 2>/dev/null`
    echo "1st $SEGGER_PATH"
    if [[ ! -d "${SEGGER_PATH}" ]]; then
      echo "Could not find SEGGER executables."
      echo "Please provide the path to SEGGER:"
      read
      while [[ ! -d "${REPLY}/SEGGER" ]]; do
        echo "Searching for ${REPLY}/SEGGER"
        echo "Could not find SEGGER folder. Enter the path to SEGGER"
        read
      done
      SEGGER_PATH=$REPLY
    fi
  fi

  DEBUG_SERVER_PATH=${SEGGER_PATH}/JLink/JLinkGDBServer.exe
  DEBUG_SERVER_PATH=`convertToWindowsDriveLetter "${DEBUG_SERVER_PATH}"`
  DEBUG_SERVER_PATH=`convertToWindowsPathSeparator "${DEBUG_SERVER_PATH}"`
  #Create the full string to insert into the json file
  echo "      \"debugServerPath\": \""${DEBUG_SERVER_PATH}"\"," >> $TEMPORARY_FILE_NAME
  doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME

  ####Insert the string into launch.vs.json
  LINE_NUMBER=`egrep -n -m1 "debugServerPath" launch.vs.json | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" launch.vs.json
  #Double up the path separators for visual studio compatability
  doubleUpWindowsPathSeparators launch.vs.json $LINE_NUMBER

  ####Create the path to JLink.exe
  PATH_TO_JLINK="${SEGGER_PATH}/JLink/JLink.exe"
  echo $PATH_TO_JLINK
  PATH_TO_JLINK=`convertToWindowsDriveLetter "${PATH_TO_JLINK}"`
  PATH_TO_JLINK=`convertToWindowsPathSeparator "${PATH_TO_JLINK}"`
  #Create the full string to insert into the json file
  echo "  \"pathToJLink\": \"\\\""${PATH_TO_JLINK}"\\\"\"," >> $TEMPORARY_FILE_NAME
  doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME

  ####Insert the string into tasks.vs.json
  LINE_NUMBER=`egrep -n -m1 "pathToJLink" tasks.vs.json | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" tasks.vs.json
  #Double up the path separators for visual studio compatability
  doubleUpWindowsPathSeparators tasks.vs.json $LINE_NUMBER
  #Then remove the first double separator because it's meant to actually escape
  #the first quote mark.
  sed -i ${LINE_NUMBER}'s/"\\\\"/"\\"/' tasks.vs.json
  sed -i ${LINE_NUMBER}'s/\\""/\""/' tasks.vs.json

  rm $TEMPORARY_FILE_NAME

  return 0
}

#For testing
#getDebuggerPaths evkmimxrt1060_azure_iot_mqtt\ JLink\ Debug.launch
