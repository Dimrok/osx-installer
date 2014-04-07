#!/bin/bash

[[ -n "$1" ]] || { echo "Usage: $0 <installer_path>"; exit 1; }
[[ -d "$1" ]] || { echo "Installer app not found: $1"; exit 1; }

INSTALLER_APP_PATH=$1
APP_FILENAME=$(basename "$INSTALLER_APP_PATH")
APP_EXTENSION="${APP_FILENAME##*.}"

# Make sure the installer is a ".app" file
[[ "$APP_EXTENSION" == "app" ]] || { echo "Installer path must be to a '.app' bundle."; exit 1; }

APP_NAME="${APP_FILENAME%.*}"
VOLUME_NAME="$APP_NAME Installer"
VOLUME_PATH="/Volumes/$VOLUME_NAME"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DMG_DIR="$SCRIPT_DIR/dmg"
TMP_DIR="/tmp/$APP_NAME"

# Create the DMG output directory if needed
[ -d "$DMG_DIR" ] || mkdir "$DMG_DIR"

TIMESTAMP="$(date +%s)"
TEMP_DMG_NAME="$APP_NAME-$TIMESTAMP-temp.dmg"
TEMP_DMG_PATH="$DMG_DIR/$TEMP_DMG_NAME"
FINAL_DMG_NAME="$APP_NAME-$TIMESTAMP.dmg"
FINAL_DMG_PATH="$DMG_DIR/$FINAL_DMG_NAME"

# Eject any volumes that may already be mounted
if [ -d "$VOLUME_PATH" ]; then
    echo "Ejecting $VOLUME_PATH"
    echo '
       tell application "Finder"
         tell disk "'$VOLUME_NAME'"
            eject
            delay 5
         end tell
       end tell
    ' | osascript
fi

mkdir "$TMP_DIR"
hdiutil create -srcfolder "$TMP_DIR" -volname "$VOLUME_NAME" -fs HFS+ \
      -fsargs "-c c=64,a=16,e=16" -format UDRW -size 100m "$TEMP_DMG_PATH"
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG_PATH" | \
        egrep '^/dev/' | sed 1q | awk '{print $1}')
sleep 5
cp -r "$INSTALLER_APP_PATH" "$VOLUME_PATH"
mkdir "$VOLUME_PATH/.background"
cp "background.tiff" "$VOLUME_PATH/.background/"
rm -r "$TMP_DIR"

# dmg window dimensions
dmg_width=450
dmg_height=440
dmg_topleft_x=200
dmg_topleft_y=200
dmg_bottomright_x=`expr $dmg_topleft_x + $dmg_width`
dmg_bottomright_y=`expr $dmg_topleft_y + $dmg_height`
icon_size=200
icon_center_x=$(( dmg_width / 2 ))
icon_center_y=$(( dmg_height / 2 + 30))

echo '
tell application "Finder"
    tell disk "'${VOLUME_NAME}'"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {'${dmg_topleft_x}', '${dmg_topleft_y}', '${dmg_bottomright_x}', '${dmg_bottomright_y}'}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to '${icon_size}'
        set background picture of theViewOptions to file ".background:background.tiff"
        set position of item  "'${APP_FILENAME}'" of container window to {'${icon_center_x}', '${icon_center_y}'}
        close
        open
        update without registering applications
        delay 3
        eject
    end tell
end tell
' | osascript

chmod -Rf go-w "$VOLUME_PATH"
sync
sync
hdiutil detach "$DEVICE"
hdiutil convert "$TEMP_DMG_PATH" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG_PATH"
rm -f "$TEMP_DMG_PATH"

open "$DMG_DIR"