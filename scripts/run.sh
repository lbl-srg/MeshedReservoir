#!/bin/bash
# Shell wrapper for run.py
# This script provides a convenient way to run the Python simulation script

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export MODELICAPATH=${MODELICAPATH}:${SCRIPT_DIR}/..

# Run the Python script with all arguments passed to this shell script
python3 "${SCRIPT_DIR}/run.py" "$@"
