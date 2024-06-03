#!/bin/bash

echo "Repo URL: $1";
echo "Change charts: $2";

current_dir=$(pwd)
folders=$2
IFS=',' read -ra folder_array <<< "$folders"
for folder in "${folder_array[@]}"; do
  cd $folder
  rm -rf ./*.tgz
  echo "Processing chart: $folder"
  helm package .
  for file in ./*.tgz; do
    if [ -f "$file" ]; then
      echo "Pushing: $file"
      helm push "$file" "$1"
    fi
  done
  rm -rf ./*.tgz
  cd $current_dir
done

echo "Push process completed."