#!/bin/bash

# Check if init code hash is provided as argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <init_code_hash>"
    exit 1
fi

init_code_hash=$1

# Generate output
output=$(cast create2 --init-code-hash "$init_code_hash" --starts-with 000000 --no-random | awk '/Salt:/ {print "" $2 ""}')

# Create temp file containing output 
echo "$output" > .temp
