#!/bin/bash
# Colourise the output
RED='\033[0;31m'        # Red
GRE='\033[0;32m'        # Green
YEL='\033[1;33m'        # Yellow
NCL='\033[0m'           # No Color

# Perform unpacking
unpack() {
        FILE_NAME="$(basename "${entry}")"
		FILE_TYPE="$(file -i "${entry}")"
        SIZE="$(du -sh "${entry}" | cut -f1)"

	if $VERBOSE_FLAG ; then 
        printf "%*s${GRE}%s${NCL}\n"                    $((indent+4)) '' "${entry}"
        printf "%*s\tFile type:\t${YEL}%s${NCL}\n"      $((indent+4)) '' "${FILE_TYPE#*: }"
		printf "%*s\tFile size:\t${YEL}%s${NCL}\n"      $((indent+4)) '' "$SIZE"
	fi

	    DECOMPRESSED="Can not be extracted"
		case "${FILE_TYPE}" in
   	     **application/x-bzip2*) bunzip2 "${entry}" && ((++TOTAL_DECOMPRESSED)) && DECOMPRESSED="Extracted" || ((++TOTAL_UNCOMPRESSED)) ;;
       	 *application/gzip*) gunzip "${entry}" && ((++TOTAL_DECOMPRESSED)) && DECOMPRESSED="Extracted" || ((++TOTAL_UNCOMPRESSED)) ;;
         *application/zip*) unzip -o -qq -d $(dirname $entry) "${entry}" && ((++TOTAL_DECOMPRESSED)) && DECOMPRESSED="Extracted" && rm $entry || ((++TOTAL_UNCOMPRESSED)) ;;
         *application/x-compress*) uncompress "${entry}" && ((++TOTAL_DECOMPRESSED)) && DECOMPRESSED="Extracted" || ((++TOTAL_UNCOMPRESSED)) ;;
		 *) ((TOTAL_UNCOMPRESSED++)) ;;
    	esac
		$VERBOSE_FLAG && printf "%*s\tExtracted:\t${YEL}%s${NCL}\n"      $((indent+4)) '' "${DECOMPRESSED}"      
}

# Directory traversal
walk() {
        local indent="${2:-0}"
        $VERBOSE_FLAG && printf "\n%*s${RED}%s${NCL}\n\n" "$indent" '' "$1"
        # If the entry is a file do unpack
        for entry in "$1"/*; do [[ -f "$entry" ]] && unpack; done
        # If the entry is a directory and recursive option is enabled make a recursive call
        for entry in "$1"/*; do [[ -d "$entry" ]] && $RECURSIVE_FLAG && walk "$entry" $((indent+4)); done
}

PARAMS=""
VERBOSE_FLAG=false
HELP_FLAG=false
RECURSIVE_FLAG=false
TOTAL_DECOMPRESSED=0
TOTAL_UNCOMPRESSED=0

# Extract options
while (( "$#" )); do
  case "$1" in
    -v|--verbose)
	  VERBOSE_FLAG=true
      shift
      ;;
    -h|--help)
	  HELP_FLAG=true
      shift
      ;;
    -r|--recursive)
	  RECURSIVE_FLAG=true
      shift
      ;;
    -*|--*=) # Unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # Preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# Show help
if $HELP_FLAG ; then
	echo "Usage: extract.sh [OPTION]... [FILE]...
	
Extracts multiple packed files, and even traverse folders recursively and unpack all archives in them - regardless of the specific algorithm that was used when packing them.
	
Given a list of filenames as input, this script queries each target file for the type of compression used on it.
Then the script automatically invokes the appropriate decompression command, putting files in the same folder.
If files with the same name already exist, they are overwritten.
Script supports 4 unpacking options - gunzip, bunzip2, unzip, uncompress.
If a target file is not compressed, the script takes no other action on that particular file.
If the target is a directory then it decompresses all files in it using same method.
Script returns number of archives decompressed.
Command returns number of files it did NOT decompress.

Additional switches:
-v (--verbose) - verbose - returns each file decompressed & warn for each file that was NOT decompressed
-r (--recursive) - traverses contents of folders recursively, performing unpack on each
-h (--help) - this HELP notice"
exit 0
fi

# Set positional arguments in their proper place
eval set -- "$PARAMS"

# Process files and directories from positional arguments
if [ $# -eq 0 ]; then
  EXEC_DIR="${PWD}"
  walk "${EXEC_DIR}"
else
	for FILE in "${@}"
	do
		if [[ -d $FILE ]] ; then
			if [[ $FILE == /* ]] ; then
				EXEC_DIR="${FILE}"
			else
				EXEC_DIR="${PWD}/${FILE}"
			fi
			walk "${EXEC_DIR}"
		else
			entry=$FILE
			unpack
		fi		
	done
fi
echo
printf "Total extracted:\t${YEL}%s${NCL}\n"      "${TOTAL_DECOMPRESSED}"
printf "Total not extracted:\t${YEL}%s${NCL}\n"      "${TOTAL_UNCOMPRESSED}"