#!/bin/bash

JAVA_VERSION="17"                        # Possible values: 8, 11, 17, latest
RUBY_VERSION="3.2.1"                     # Possible values: release number, latest
BUNDLER_VERSION="latest"                 # Possible values: release number, latest
ANDROID_SDK_PLATFORMS_VERSION="33"       # Possible values: https://developer.android.com/studio/releases/platforms
ANDROID_SDK_BUILD_TOOLS_VERSION="33.0.1" # Possible values: https://developer.android.com/studio/releases/build-tools

CLEAN_INSTALL=1 # Removes dependencies before reinstalling
SILENT=0        # Doesn't require user input just force-updates all dependencies to specified versions
