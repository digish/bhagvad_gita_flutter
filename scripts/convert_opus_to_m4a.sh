#!/bin/bash
# Converts all .opus files in assets/audio to .m4a (AAC) for iOS compatibility.

AUDIO_DIR="assets/audio"

if [ ! -d "$AUDIO_DIR" ]; then
  echo "Error: Directory $AUDIO_DIR not found."
  exit 1
fi

echo "Starting conversion of .opus files to .m4a in $AUDIO_DIR..."
count=0

# usage of find to handle spaces correctly is tricky, but here standard paths don't have spaces usually.
# However, using -print0 is safer.

find "$AUDIO_DIR" -name "*.opus" -print0 | while IFS= read -r -d '' filename; do
  newname="${filename%.opus}.m4a"
  if [ ! -f "$newname" ]; then
    echo "Converting: $filename -> $newname"
    ffmpeg -i "$filename" -c:a aac -b:a 64k -loglevel error -y "$newname" < /dev/null
    ((count++))
  else
    echo "Skipping (already exists): $newname"
  fi
done

echo "Conversion complete."
