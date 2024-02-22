#!/bin/sh

# Simple wrapper to execute pma_server.py from anywhere.
# Arbitrary Version Number: v1.0.0
# Author: Tyler McCann (@tylerdotrar)

# Usage:
#   -d DIRECTORY, --directory DIRECTORY  Target file directory                             (default: pwd)
#   -p PORT, --port PORT                 Server port to listen on                          (default: 80)
#   -s, --ssl                            Enable HTTPS support via self-signed certificates (default: false)
#   -D, --debug                          Toggle Flask debug mode                           (default: false)
#   -h, --help                           Show help message and exit

# Examples:
#   pma-server --port 443 --ssl
#   pma-server --port 8080 --directory /usr/share/windows-binaries

# Setup:
#   git clone https://github.com/tylerdotrar/PoorMansArmory /usr/share/PoorMansArmory
#   ln -s /usr/share/PoorMansArmory/wrappers/pma-server.sh /usr/bin/pma-server

exec python3 /usr/share/PoorMansArmory/pma_server.py --directory $(pwd) "$@"
