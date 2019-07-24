#!/bin/bash

while [[ $# -gt 0 ]]
do
    key="${1}"
    case ${key} in
    -i|--input)
        INPUTPARAM="${2}"
        shift # past argument
        shift # past value
        ;;
    -o|--output)
        OUTPUTPARAM="${2}"
        shift # past argument
        shift # past value
        ;;
    -h|--help)
        echo "Show help"
        shift # past argument
        ;;
    *)    # unknown option
        shift # past argument
        ;;
    esac
    shift
done