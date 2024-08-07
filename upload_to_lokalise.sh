#!/bin/bash

upload_file() {
  local file=$1
  local attempt=0
  local max_retries=3
  local sleep_time=1

  while [ $attempt -lt $max_retries ]; do
    output=$(./bin/lokalise2 --token="${VAR_LOKALISE_API_TOKEN}" \
      --project-id="${VAR_LOKALISE_PROJECT_ID}" \
      file upload \
      --file="$file" \
      --lang-iso="${VAR_LOKALISE_SOURCE_LANG_ISO}" \
      --replace-modified \
      --include-path \
      --use-automations=true \
      --distinguish-by-file \
      --poll \
      --poll-timeout=120s \
      --tag-inserted-keys \
      --tag-skipped-keys=true \
      --tag-updated-keys \
      --tags $GITHUB_REF_NAME 2>&1)

    echo "$output"
    
    http_code=$(echo "$output" | grep -oP 'HTTP/\d+\.\d+ \K\d+')

    if [ "$http_code" -eq 429 ]; then
      attempt=$((attempt + 1))
      echo "Attempt $attempt failed with HTTP 429. Retrying in $sleep_time seconds..."
      sleep $sleep_time
      sleep_time=$((sleep_time * 2))
    else
      if [ "$http_code" -ne 200 ]; then
        echo "Failed to upload file: $file"
        echo "Error: $output"
        return 1
      else
        echo "Successfully uploaded file: $file"
        return 0
      fi
    fi
  done

  echo "Failed to upload file: $file after $max_retries attempts"
  return 1
}

export -f upload_file
