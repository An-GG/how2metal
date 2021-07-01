#!/usr/bin/env bash

# Clean
rm -f *.air
rm -f *.metallib
rm -f *.out

# First, we need to compile metal file into a library that can be imported into swift
xcrun -sdk macosx metal -c -std=macos-metal2.3 compute.metal -o compute.air
xcrun -sdk macosx metallib compute.air -o compute.metallib

# Next, compile the swift file to executable
xcrun -sdk macosx swiftc main.swift -o a.out
