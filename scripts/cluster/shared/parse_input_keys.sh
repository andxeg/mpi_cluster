#!/bin/bash

PARAMS=""

n="$#"

while (( "$#" )); do
  case "$1" in
    -f|--flag-with-argument)
      FARG=$2
      shift 2
      n=$((n-2))
      if [[ ( "$n" -lt "0" )]] ; then
        echo "Error: missing value for $1" >&2  
        exit 1
      fi
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

printf "FARG = $FARG\n"
printf "PARAMS = $PARAMS\n"

# CHECK IT
# $ ./foo bar -a baz --long thing
# $ ./foo -a baz bar --long thing
