#!/bin/sh
# Flutter tree-shakes the Material icon font into a file whose name never changes, so a browser
# that cached an older build keeps showing blank icons for anything new. Naming the file after its
# content gives every build its own URL. Runs before every hosting deploy (predeploy in firebase.json).
set -eu

assets="${PROJECT_DIR:-.}/build/web/assets"
font="fonts/MaterialIcons-Regular.otf"

# Already renamed: the same build is being deployed again.
[ -f "$assets/$font" ] || exit 0
grep -q "\"$font\"" "$assets/FontManifest.json" || { echo "FontManifest.json doesn't list $font" >&2; exit 1; }

hash=$(shasum -a 256 "$assets/$font" | cut -c1-12)
hashed="fonts/MaterialIcons-Regular.$hash.otf"
rm -f "$assets"/fonts/MaterialIcons-Regular.*.otf
mv "$assets/$font" "$assets/$hashed"
sed -i.bak "s#\"$font\"#\"$hashed\"#" "$assets/FontManifest.json"
rm "$assets/FontManifest.json.bak"
echo "Icon font: $hashed"
