<h1 align="center">🔍 CRTSF 🔍</h1>
<h3 align="center">❎ crt.sh subdomain finder ❎</h3>
<h6 align="center">ℹ️ A Bash script that uses the crt.sh Certificate Transparency log to find subdomains ℹ️</h6>

## Features

- Fetch subdomains for a single domain or multiple domains from a file
- Automatic dependency installation (jq, curl)
- Configurable curl timeout and retry attempts
- Colorized output for better readability
- Option to output results to stdout or save to files
- Custom output directory support

## Prerequisites

- Bash shell
- Internet connection
- Either root access or permission to install packages (for automatic dependency installation)

## Installation

1. Clone this repository or download the `crtsf.sh` script:

```bash
git clone https://github.com/isanjaymenon/crtsf.git
```

```bash
cd crtsf
```

2. Make the script executable:

```bash
chmod +x crtsf.sh
```

## Usage

### Basic usage:

```bash
./crtsf.sh -d example.com
```

### Advanced usage:

```bash
./crtsf.sh -d example.com -o /path/to/output -t 60 -r 5
```

### Options:

- `-d`: Domain to search
- `-f`: File containing a list of domains
- `-o`: Output directory (default: ./crtsf-results)
- `-s`: Output to stdout instead of a file
- `-t`: Curl timeout in seconds (default: 30)
- `-r`: Maximum number of retries (default: 3)
- `-h`: Display help message

## Examples

1. Search for subdomains of a single domain:

```bash
./crtsf.sh -d example.com
```

2. Search for subdomains of multiple domains from a file:

```bash
./crtsf.sh -f domains.txt
```

3. Custom output directory and increased timeout:

```bash
./crtsf.sh -d example.com -o /tmp/subdomains -t 60
```

4. Output results to stdout:

```bash
./crtsf.sh -d example.com -s
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [crt.sh](https://crt.sh) for providing certificate transparency log data
- [curl](https://github.com/curl/curl) for transferring data specified with URL syntax
- [jq](https://stedolan.github.io/jq/) for JSON processing

## Disclaimer

Ensure you have permission to scan domains that you do not own.

## Contact

For any queries or suggestions, please open an issue in this repository.
