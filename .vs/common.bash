TOOLCHAIN_PREFIX=arm-none-eabi-
PATH_TO_BIN=ide/tools/bin
GDB=gdb.exe
GCC=gcc.exe
GXX=c++.exe
OBJCPY=objcopy.exe
PROJECT_NAME=`pwd | awk 'BEGIN {FS ="/"} ; {print $(NF -1)}'`

#Try to create a unique file name that likely won't exist. Does not create the
#file.
#Returns the file name
createTemporaryFilename() {
  TEMPORARY_FILE_NAME=`date -u | tr -d " "`
  if [ -f "${TEMPORARY_FILE_NAME}" ]; then
    exit 1
  fi
  echo $TEMPORARY_FILE_NAME
}

#Replace the driver letter for WSL to a Windows style
# $1 - The path to replace the drive letter with.
convertToWindowsDriveLetter() {
  DRIVE_LETTER=`echo $1 | cut -d"/" -f3`
  DRIVE_LETTER_UPPER=`echo $DRIVE_LETTER | tr '[:lower:]' '[:upper:]'`
  echo $1 | sed "s/\/mnt\/${DRIVE_LETTER}\//${DRIVE_LETTER_UPPER}:\\\/"
}

#Replace unix path separator with windows separators.
#$1 - String to replace path separators with.
convertToWindowsPathSeparator() {
  echo "$1" | sed 's/\//\\/g'
}

#Replace windows path separators with unix.
#$1 - String to replace path separators with
convertStringToUnixPathSeparator() {
  echo "$1" | sed 's/\\/\//g'
}

#Replace windows path separators in the file provided with unix path separators.
#Optionally inlcude a line number as well. If not given, the entire file is at
#the mercy of sed.
#$1 - file to convert separators
#$2 - Optional line number to restrict the conversion to.
convertFileToUnixPathSeparator() {
  if [ $# -eq 2 ]; then
    sed -i $2's/\\/\//g' $1
  else
    sed -i 's/\\/\//g' $1
  fi
}

#Double up path separators. Linux interprets them as escapes so they are
#completely removed if they appear by themselves.
#Optionally include a line number as well.
#$1 - file to double serparators
#$2 - line number to perform the edit to. If not given, the entire file is at
#the mercy of sed.
doubleUpWindowsPathSeparators() {
  if [ $# -eq 2 ]; then
    sed -i $2's/\\/\\\\/g' $1
  else
    sed -i 's/\\/\\\\/g' $1
  fi
}
