#!/usr/bin/env bash

# Clean
rm -rf products
mkdir products

# First, we need to compile metal file into a library that can be imported into swift
xcrun -sdk macosx metal -c -std=macos-metal2.3 compute.metal -o products/compute.air
xcrun -sdk macosx metallib products/compute.air -o products/compute.metallib

# Next, compile the swift file to executable
xcrun -sdk macosx swiftc main.swift -o products/main.out
xcrun -sdk macosx swiftc test.swift -o products/test.out
