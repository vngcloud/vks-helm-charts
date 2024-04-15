#!/bin/bash

echo "Repo URL: $1";

# Loop through all .tgz files in the specified folder (replace with your folder)
for file in ./*.tgz; do
  # Check if file exists
  if [ -f "$file" ]; then
    echo "Pushing: $file"
    helm push "$file" "$1"
  fi
done

echo "Push process completed."