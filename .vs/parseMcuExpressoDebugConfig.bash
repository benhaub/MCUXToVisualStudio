#! /bin/bash
###############################################################################
# Author: Ben Haubrich                                                        #
# File: parseMcuExpressoDebugConfig.bash                                      #
# Date: January 23rd, 2021                                                    #
# Synopsis: Parse the debug configuration provided to build the command line  #
#           arguments string for JLink.exe and JLinkGDBServer.exe             #
###############################################################################

source common.bash

help() {
  echo "Usage parseMcuExpressoDebugConfig.bash <debugConfigurationFile>"
}

parseMcuExpressoDebugConfig() {

  if [ $# -lt 1 ]; then
    help
    exit 1
  fi

  TEMPORARY_FILE_NAME=`createTemporaryFilename`

  ####Grab all the command line argument values needed from the config.
  IF=`egrep "segger.if" "$1" | cut -f3 -d "=" | tr -d "\"" | tr -d "/" | tr -d ">" | tr -d "\r"`
  SPEED=`egrep "segger.speed" "$1" | cut -f3 -d "=" | tr -d "\"" | tr -d "/" | tr -d ">" | tr -d "\r"`
  DEVICE=`egrep "segger.device" "$1" | cut -f3 -d "=" | tr -d "\"" | tr -d "/" | tr -d ">" | tr -d "\r"`
  PROBE_TYPE=`egrep "segger.select" "$1" | cut -f3 -d "=" | tr -d "\"" | tr -d "/" | tr -d ">" | tr -d "\r"`
  SN=`egrep "segger.select" "$1" | cut -f4 -d "=" | tr -d "\"" | tr -d "/" | tr -d ">" | tr -d "\r"`
  ENDIAN=`egrep "segger.endian" "$1" | cut -f3 -d "=" | tr -d "\"" | tr -d "/" | tr -d ">" | tr -d "\r"`
  INIT_REGISTER=`egrep "segger.init.register" "$1" | cut -f3 -d "=" | tr -d "\"" | tr -d "/" | tr -d ">" | tr -d "\r"`
  INIT_REGISTER="-$INIT_REGISTER"
  IP_ADDRESS=`egrep "core.ipAddress" "$1" | cut -f3 -d "=" | tr -d "\"" | tr -d "/" | tr -d ">" | tr -d "\r"`
  PORT_NUMBER=`egrep "core.portNumber" "$1" | cut -f3 -d "=" | tr -d "\"" | tr -d "/" | tr -d ">" | tr -d "\r"`
  if [ "$IP_ADDRESS" = "localhost" ]; then
    LOCAL_HOST="-LocalhostOnly"
  else
    LOCAL_HOST="-noLocalhostOnly"
  fi


  ####Build the command line arg string
  echo "  \"JLinkArgs\": \"-if $IF -speed $SPEED -commanderScript Debug\\script.jlink -device $DEVICE -SelectEmuBySN $SN\"," >> $TEMPORARY_FILE_NAME
  doubleUpWindowsPathSeparators $TEMPORARY_FILE_NAME
  #Insert it into tasks.vs.json
  LINE_NUMBER=`egrep -n -m1 "JLinkArgs" tasks.vs.json | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" tasks.vs.json
  #Double up the path separators for visual studio compatability
  doubleUpWindowsPathSeparators tasks.vs.json $LINE_NUMBER

  ####Build the strings for gdb server key/value pairs
  echo "      \"miDebuggerServerAddress\": \"${IP_ADDRESS}:${PORT_NUMBER}\"," >> $TEMPORARY_FILE_NAME
  #Insert it into tasks.vs.json
  LINE_NUMBER=`egrep -n -m1 "miDebuggerServerAddress" launch.vs.json | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" launch.vs.json
  #Double up the path separators for visual studio compatability
  doubleUpWindowsPathSeparators launch.vs.json $LINE_NUMBER

  echo "      \"debugServerArgs\": \"-select ${PROBE_TYPE}=${SN} -device $DEVICE -endian $ENDIAN -if $IF -speed $SPEED $INIT_REGISTER $LOCAL_HOST\"," >> $TEMPORARY_FILE_NAME
  #Insert it into tasks.vs.json
  LINE_NUMBER=`egrep -n -m1 "debugServerArgs" launch.vs.json | cut -f1 -d ":"`
  sed -i ${LINE_NUMBER}"s/.*/`tail -1 ${TEMPORARY_FILE_NAME}`/" launch.vs.json
  #Double up the path separators for visual studio compatability
  doubleUpWindowsPathSeparators launch.vs.json $LINE_NUMBER

  rm $TEMPORARY_FILE_NAME

  return 0
}

####For testing
#parseMcuExpressoDebugConfig evkmimxrt1060_azure_iot_mqtt\ JLink\ Debug.launch
