#!/bin/bash

set -e

cd "$(dirname "$0")"

WORKING_LOCATION="$(pwd)"
APPLICATION_NAME=TrollTools
CONFIGURATION=Debug

if [ ! -d "build" ]; then
    mkdir build
fi

cd build
if [ -e "$APPLICATION_NAME.tipa" ]; then
rm $APPLICATION_NAME.tipa
fi

# Build .app
xcodebuild -project "$WORKING_LOCATION/$APPLICATION_NAME.xcodeproj" \
    -scheme TrollTools \
    -configuration Debug \
    -derivedDataPath "$WORKING_LOCATION/build/DerivedData" \
    -destination 'generic/platform=iOS' \
    ONLY_ACTIVE_ARCH="NO" \
    CODE_SIGNING_ALLOWED="NO" \
    
# Build helper
# xcodebuild -project "$WORKING_LOCATION/$APPLICATION_NAME.xcodeproj" \
#     -scheme RootHelper \
#     -configuration Debug \
#     -derivedDataPath "$WORKING_LOCATION/build/DerivedData" \
#     -destination 'generic/platform=iOS' \
#     ONLY_ACTIVE_ARCH="NO" \
#     CODE_SIGNING_ALLOWED="NO" \

DD_APP_PATH="$WORKING_LOCATION/build/DerivedData/Build/Products/$CONFIGURATION-iphoneos/$APPLICATION_NAME.app"
TARGET_APP="$WORKING_LOCATION/build/$APPLICATION_NAME.app"
cp -r "$DD_APP_PATH" "$TARGET_APP"

# Remove signature
codesign --remove "$TARGET_APP"
if [ -e "$TARGET_APP/_CodeSignature" ]; then
    rm -rf "$TARGET_APP/_CodeSignature"
fi
if [ -e "$TARGET_APP/embedded.mobileprovision" ]; then
    rm -rf "$TARGET_APP/embedded.mobileprovision"
fi

cd $WORKING_LOCATION/RootHelper
make clean
make
cp $WORKING_LOCATION/RootHelper/.theos/obj/debug/trolltoolsroothelper $WORKING_LOCATION/build/TrollTools.app/trolltoolsroothelper
cd -

# cp $WORKING_LOCATION/build/DerivedData/Build/Products/$CONFIGURATION-iphoneos/RootHelper $WORKING_LOCATION/build/TrollTools.app/RootHelper

# Add entitlements
echo "Adding entitlements"
ldid -S"$WORKING_LOCATION/entitlements.plist" "$TARGET_APP/$APPLICATION_NAME"
# ldid -S"$WORKING_LOCATION/entitlements.plist" "$TARGET_APP/RootHelper"

# Package .ipa
rm -rf Payload
mkdir Payload
cp -r $APPLICATION_NAME.app Payload/$APPLICATION_NAME.app
zip -vr $APPLICATION_NAME.tipa Payload
rm -rf $APPLICATION_NAME.app
rm -rf Payload
