#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${RED}
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|       crt.sh subdomain finder       |
|                                     |           
|         x.com/isanjaymenon          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
${NC}"
}

DEFAULT_OUTPUT_DIR="./crtsf-output"
CURL_TIMEOUT=30
MAX_RETRIES=3
RETRY_DELAY=5

check_and_install_dependencies() {
    local deps=("jq" "curl")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -eq 0 ]; then
        return 0
    fi

    echo -e "${YELLOW}The following dependencies are missing: ${missing_deps[*]}${NC}"
    read -p "Do you want to install them? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ "$(id -u)" -ne 0 ]; then
            echo -e "${RED}This script needs sudo privileges to install packages.${NC}"
            echo -e "${RED}Please run the script again with sudo or as root.${NC}"
            exit 1
        fi

        if command -v apt-get &>/dev/null; then
            apt-get update
            apt-get install -y "${missing_deps[@]}"
        elif command -v dnf &>/dev/null; then
            dnf install -y epel-release
            dnf install -y "${missing_deps[@]}"
        elif command -v brew &>/dev/null; then
            brew install "${missing_deps[@]}"
        else
            echo -e "${RED}Unsupported package manager. Please install ${missing_deps[*]} manually.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Dependencies are required but won't be installed. Exiting.${NC}"
        exit 1
    fi
}

usage() {
    echo ""
    echo -e "${GREEN}Usage: $0 [-d domain] [-f file] [-o output_dir] [-s] [-t timeout] [-r retries] [-h]${NC}"
    echo ""
    echo "Options:"
    echo ""
    echo -e "${MAGENTA}  -d  Domain to search${NC}"
    echo -e "${MAGENTA}  -f  File containing list of domains${NC}"
    echo -e "${MAGENTA}  -h  Display this help message${NC}"
    echo -e "${MAGENTA}  -o  Output directory (default: $DEFAULT_OUTPUT_DIR)${NC}"
    echo -e "${MAGENTA}  -r  Maximum number of retries (default: $MAX_RETRIES)${NC}"
    echo -e "${MAGENTA}  -s  Output to stdout instead of a file${NC}"
    echo -e "${MAGENTA}  -t  Curl timeout in seconds (default: $CURL_TIMEOUT)${NC}"
    echo ""
}

validate_domain() {
    if [[ ! $1 =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${RED}Invalid domain format: $1${NC}" >&2
        return 1
    fi
    return 0
}

fetch_subdomains() {
    local domain=$1
    local retries=0
    local result=""

    while [ $retries -lt $MAX_RETRIES ]; do
        result=$(curl -m $CURL_TIMEOUT -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | grep -v "^$domain$" | grep -oP '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' | sort -u)

        if [ -n "$result" ]; then
            echo "$result"
            return 0
        fi

        retries=$((retries + 1))
        echo -e "${YELLOW}Retry $retries/$MAX_RETRIES for $domain...${NC}" >&2
        sleep $RETRY_DELAY
    done

    echo -e "${RED}Error: Failed to retrieve data from crt.sh for $domain after $MAX_RETRIES attempts${NC}" >&2
    return 1
}

process_domain() {
    local domain=$1
    local output_dir=$2
    local stdout_output=$3

    echo ""
    echo -e "${RED}Gathering subdomains for $domain from crt.sh...${NC}"
    echo ""

    local result=$(fetch_subdomains "$domain")

    if [ $? -ne 0 ]; then
        return 1
    fi

    if [ "$stdout_output" = true ]; then
        echo "$result"
    else
        local output_file="$output_dir/crtsf-${domain}-subdomains-$(date +"%Y%m%d-%I%M%p").txt"
        echo "$result" >"$output_file"
        echo -e "${GREEN}Results for $domain saved in $output_file.${NC}"
        echo ""
    fi
}

main() {
    print_banner # Display banner at the start of every run

    local DOMAIN=""
    local DOMAIN_FILE=""
    local OUTPUT_DIR=$DEFAULT_OUTPUT_DIR
    local STDOUT_OUTPUT=false

    while getopts ":hd:f:o:st:r:" opt; do
        case $opt in
        h)
            usage
            exit 0
            ;;
        d) DOMAIN=$OPTARG ;;
        f) DOMAIN_FILE=$OPTARG ;;
        o) OUTPUT_DIR=$OPTARG ;;
        s) STDOUT_OUTPUT=true ;;
        t) CURL_TIMEOUT=$OPTARG ;;
        r) MAX_RETRIES=$OPTARG ;;
        \?)
            echo -e "${RED}Invalid option: -$OPTARG${NC}" >&2
            echo ""
            usage
            exit 1
            ;;
        :)
            echo -e "${RED}Option -$OPTARG requires an argument.${NC}" >&2
            echo ""
            exit 1
            ;;
        esac
    done

    if [ -z "$DOMAIN" ] && [ -z "$DOMAIN_FILE" ]; then
        echo -e "${RED}Error: Either a domain or a file with domains must be provided.${NC}" >&2
        echo ""
        usage
        exit 1
    fi

    check_and_install_dependencies

    if [ "$STDOUT_OUTPUT" = false ]; then
        mkdir -p "$OUTPUT_DIR"
    fi

    if [ -n "$DOMAIN" ]; then
        if validate_domain "$DOMAIN"; then
            process_domain "$DOMAIN" "$OUTPUT_DIR" $STDOUT_OUTPUT
        fi
    fi

    if [ -n "$DOMAIN_FILE" ]; then
        if [ ! -f "$DOMAIN_FILE" ]; then
            echo -e "${RED}Error: File not found - $DOMAIN_FILE${NC}" >&2
            echo ""
            exit 1
        fi
        while IFS= read -r domain || [ -n "$domain" ]; do
            if validate_domain "$domain"; then
                process_domain "$domain" "$OUTPUT_DIR" $STDOUT_OUTPUT
            fi
        done <"$DOMAIN_FILE"
    fi
}

main "$@"
