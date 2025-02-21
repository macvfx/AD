#!/bin/bash

# Define variables
GROUP_MATCH="ABC123"  # Change this to match your desired group prefix
OUTPUT_DIR="/Volumes/Drive/Folder/"  # Change this to your desired destination

# Check if at least two arguments are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <user1> <user2> [user3 ...]"
    exit 1
fi

# Create a temporary file to store all unique groups
temp_groups=$(mktemp)

# Get all unique groups for all users
for user in "$@"; do
    # Extract groups matching GROUP_MATCH
    id "$user" | grep -o "[0-9]*([^)]*${GROUP_MATCH}[^)]*)" | sed "s/.*${GROUP_MATCH}\\//" | sed 's/)//' >> "$temp_groups"
done

# Create a CSV file in /private/tmp
output_file="/private/tmp/ad_group_comparison_$(date +%Y%m%d_%H%M%S).csv"

# Sort and get unique groups
unique_groups=$(sort -u "$temp_groups")

# Print CSV header with usernames
printf "Group" > "$output_file"
for user in "$@"; do
    printf ",%s" "$user" >> "$output_file"
done
printf "\n" >> "$output_file"

# Check each group for each user
while IFS= read -r group; do
    printf "%s" "$group" >> "$output_file"
    for user in "$@"; do
        if id "$user" | grep -q "${GROUP_MATCH}\\\\${group})"; then
            printf ",X" >> "$output_file"
        else
            printf "," >> "$output_file"
        fi
    done
    printf "\n" >> "$output_file"
done <<< "$unique_groups"

# Clean up temporary groups file
rm "$temp_groups"

# Display and copy CSV file
cat "$output_file"
cp "$output_file" "$OUTPUT_DIR"
