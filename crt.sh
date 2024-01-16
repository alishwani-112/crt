#!/bin/bash

# Function to display script usage
usage() {
    echo "Usage: $0 -d <domain>"
    exit 1
}

# Parse command-line options
while getopts ":d:h" opt; do
    case $opt in
        d)
            domain="$OPTARG"
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            usage
            ;;
    esac
done

# Check if the domain is provided
if [ -z "$domain" ]; then
    echo "Error: Domain is required."
    usage
fi

# Fetch data from Certificate Transparency logs and save it to a file
curl -s "https://crt.sh/?q=${domain}&output=json" > crt_data.json

# Extract common names and name values, clean and format the data
cat crt_data.json | jq -r ".[].common_name,.[].name_value" \
  | cut -d'"' -f2 \
  | sed 's/\\n/\n/g' \
  | sed 's/\*.//g' \
  | sed -r 's/([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4})//g' \
  | sort | uniq \
  | rev | cut -d "." -f 1,2 | rev \
  | sort -u | grep "$domain" > sorted_domains.txt

# Save all domains to a file without sorting
cat crt_data.json | jq -r ".[].common_name,.[].name_value" | sort -u > all_domain_crt

# Remove the temporary JSON file
rm crt_data.json

echo "Sorted unique domains saved to all_domain_crt"
echo "All domains saved to sorted_domains.txt"
