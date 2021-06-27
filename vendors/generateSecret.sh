#!/bin/bash

if [[ -e "${PROJECT_DIR}/.env" ]]; then
    source "${PROJECT_DIR}/.env"
fi
find "${PROJECT_DIR}" -name '*.gyb' |
  while read file; do
    if [[ ! -f "${file%.gyb}" ]]; then
        echo "Generating ${file%.gyb}";
        "${PROJECT_DIR}/vendors/gyb" --line-directive '' -o "${file%.gyb}" "$file";
    fi
  done

