#!/bin/bash

NIFI_DIR="/media/production-setup/nifi"
NIFI_CERTIFICATES="/media/production-setup/nifi-cert"
HADOOP_CONF_FILES="/media/production-setup/hadoop-files"
NIFI_SOURCE="/media/production-setup/nifi-source"

# Function to ensure directory exists
ensure_dir() {
    local dir_path="$1"
    local description="$2"

    if [ -d "$dir_path" ]; then
        echo "OK: $description exists: $dir_path"
    else
        echo "WARNING: $description missing: $dir_path"
        echo "Attempting to create..."
        if mkdir -p "$dir_path"; then
            echo "Successfully created $dir_path"
        else
            echo "ERROR: Failed to create $dir_path (Permission denied?)"
            exit 1
        fi
    fi
}

# 1. Ensure NiFi Directory
ensure_dir "$NIFI_DIR" "NiFi Installation Directory"

ensure_dir "$NIFI_SOURCE" "NiFi Binary Source Directory"

# 2. Ensure Certificates Directory AND Check for Content
ensure_dir "$NIFI_CERTIFICATES" "Certificates Directory"


# Strict Check: Stop if certificates directory is empty
if [ -z "$(ls -A "$NIFI_CERTIFICATES" 2>/dev/null)" ]; then
    echo "ERROR: $NIFI_CERTIFICATES is empty."
    echo "Please place certificate files in this directory before running the script."
    exit 1
fi
echo "OK: Certificates found in $NIFI_CERTIFICATES"

# 3. Ensure Hadoop Config Directory AND Check for Specific Files
ensure_dir "$HADOOP_CONF_FILES" "Hadoop Configuration Directory"

# Strict Check: Stop if required Hadoop files are missing
if [ ! -f "$HADOOP_CONF_FILES/core-site.xml" ]; then
    echo "ERROR: Missing required file: core-site.xml in $HADOOP_CONF_FILES"
    exit 1
fi

if [ ! -f "$HADOOP_CONF_FILES/hdfs-site.xml" ]; then
    echo "ERROR: Missing required file: hdfs-site.xml in $HADOOP_CONF_FILES"
    exit 1
fi
echo "OK: Required Hadoop configuration files found."

echo "SUCCESS: All prerequisites met. Proceeding with installation..."


echo "Checking for NiFi binary ZIP files in $NIFI_SOURCE..."

# Enable nullglob to handle empty matches correctly
shopt -s nullglob
zip_files=("$NIFI_SOURCE"/*.zip)
shopt -u nullglob

if [ ${#zip_files[@]} -eq 0 ]; then
    echo "ERROR: No .zip files found in $NIFI_SOURCE."
    echo "Please place the NiFi binary ZIP file (e.g., nifi-1.x.x-bin.zip) in this directory."
    exit 1
fi

echo "OK: Found the following ZIP files:"
for file in "${zip_files[@]}"; do
    echo "   - $(basename "$file")"
done

echo "Picking Latest Nifi:"
NIFI_VERSION=$(ls "$NIFI_SOURCE"  | grep "nifi" |  sort -r | head -n 1)
echo "NiFi Version Found: $NIFI_VERSION"
if [[ -n "$NIFI_VERSION" ]]; then
    echo "No NiFi Binary Found"
    exit 1
fi
echo "NiFi Version Found: $NIFI_VERSION"
