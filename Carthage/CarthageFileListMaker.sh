#!/bin/bash

: > input.xcfilelist
: > output.xcfilelist
while read FRAMEWORK_NAME; do 
    echo "\$(SRCROOT)/Carthage/Build/iOS/${FRAMEWORK_NAME}.framework" >> input.xcfilelist
    echo "\$(BUILT_PRODUCTS_DIR)/\$(FRAMEWORKS_FOLDER_PATH)/${FRAMEWORK_NAME}.framework" >> output.xcfilelist
done < FrameworkNames
