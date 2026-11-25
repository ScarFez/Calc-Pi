#!/bin/bash

# Set the absolute path to the source file and compiler flags
SRC_FILE="/home/woc/.openclaw/workspace/Calc-Pi/pi_solver_c.c"
OUTPUT_DIR="/home/woc/.openclaw/workspace/Calc-Pi/"
BIN_NAME="pi_solver_c"

echo "--- Starting Build.sh script ---"

# 1. Clean up previous builds if they exist
echo "Running make clean equivalent..."
# We simulate clean by removing the binary if it exists
rm -f "${OUTPUT_DIR}${BIN_NAME}"

if [ ! -f "${SRC_FILE}" ]; then
    echo "ERROR: Source file not found at ${SRC_FILE}"
    exit 1
fi

# 2. Compile the C code using GCC with GMP/MPFR
echo "Compiling ${SRC_FILE}..."
# Note: -I flag points to the include directory relative to the source location
gcc -std=c11 -Wall -Wextra -pedantic -lgmp -lmpfr -I"${OUTPUT_DIR}include" -c "${SRC_FILE}" -o "${OUTPUT_DIR}${BIN_NAME}.o"

if [ $? -ne 0 ]; then
    echo "--- Compilation Failed! Check compiler output above. ---"
    exit 1
fi

# 3. Link the object file into the final executable
echo "Linking executable..."
gcc "${OUTPUT_DIR}${BIN_NAME}.o" -o "${OUTPUT_DIR}${BIN_NAME}" -lgmp -lmpfr

if [ $? -ne 0 ]; then
    echo "--- Linking Failed! Check compiler output above. ---"
    exit 1
fi

echo "--- Build Successful! Executable located at ${OUTPUT_DIR}${BIN_NAME} ---"