#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${RED}
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|       crt.sh Subdomain Finder       |
|                                     |           
|         x.com/isanjaymenon          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
${NC}"

DEFAULT_OUTPUT_DIR="./crtsf-results"
CURL_TIMEOUT=30

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "⚠️ Error: jq command-line tool is not installed."
    echo "🙏 Please install jq before running this script."
    exit 1
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "⚠️ Error: curl command-line tool is not installed."
    echo "🙏 Please install curl before running this script."
    exit 1
fi

usage() {
    echo "👉 Usage: $0 [-d domain] [-f file] [-o output_dir] [-s] [-h]"
    echo ""
    echo "Options:"
    echo ""
    echo "  -d     🔍 Domain to search"
    echo "  -f     📁 File containing list of domains"
    echo "  -o     📄 Output directory (default: $DEFAULT_OUTPUT_DIR)"
    echo "  -s     📤 Output to stdout instead of a file"
    echo "  -h     💁 Display this help message"
    echo ""
}

validate_domain() {
    if [[ ! $1 =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "👎 Invalid domain format: $1" >&2
        echo ""
        exit 1
    fi
}

process_domain() {
    local domain=$1
    local output_dir=$2
    local stdout_output=$3

    echo "🕵️‍♂️ Gathering subdomains for $domain from crt.sh..."
    echo ""
    echo "📎📎📎📎"
    echo ""
    local result=$(curl -m $CURL_TIMEOUT -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | grep -v "^$domain$" | grep -oP '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' | sort | uniq)

    if [ -z "$result" ]; then
        echo "⛔ Error: No data retrieved from crt.sh for $domain" >&2
        echo ""
    else
        if [ "$stdout_output" = true ]; then
            echo "$result"
        else
            local output_file="$output_dir/${domain}_subdomains_$(date +"%Y-%m-%d_%I-%M%p")_crtsf-output.txt"
            echo "$result" > $output_file
            echo "✅ Results for $domain saved in $output_file."
            echo ""
        fi
    fi
}

DOMAIN=""
DOMAIN_FILE=""
OUTPUT_DIR=$DEFAULT_OUTPUT_DIR
STDOUT_OUTPUT=false

while getopts ":hd:f:o:s" opt; do
  case $opt in
    h)
      usage
      exit 0
      ;;
    d)
      DOMAIN=$OPTARG
      ;;
    f)
      DOMAIN_FILE=$OPTARG
      ;;
    o)
      OUTPUT_DIR=$OPTARG
      ;;
    s)
      STDOUT_OUTPUT=true
      ;;
    \?)
      echo "⚠️ Invalid option: -$OPTARG" >&2
      echo ""
      usage
      exit 1
      ;;
    :)
      echo "👋 Option -$OPTARG requires an argument." >&2
      echo ""
      exit 1
      ;;
  esac
done

if [ -z "$DOMAIN" ] && [ -z "$DOMAIN_FILE" ]; then
    echo "⛔ Error: Either a domain or a file with domains must be provided." >&2
    echo ""
    usage
    exit 1
fi

if [ "$STDOUT_OUTPUT" = false ]; then
    mkdir -p "$OUTPUT_DIR"
fi

if [ -n "$DOMAIN" ]; then
    validate_domain $DOMAIN
    process_domain $DOMAIN "$OUTPUT_DIR" $STDOUT_OUTPUT
fi

if [ -n "$DOMAIN_FILE" ]; then
    if [ ! -f "$DOMAIN_FILE" ]; then
        echo "❌ Error: File not found - $DOMAIN_FILE" >&2
        echo ""
        exit 1
    fi
    while IFS= read -r domain; do
        validate_domain $domain
        process_domain $domain "$OUTPUT_DIR" $STDOUT_OUTPUT
    done < "$DOMAIN_FILE"
fi
