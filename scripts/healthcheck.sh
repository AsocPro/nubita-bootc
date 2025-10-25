#!/bin/bash
# Health check wrapper for k3s cluster using goss
# This script wraps goss to provide health validation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GOSS_FILE="${GOSS_FILE:-/etc/goss/goss.yaml}"
GOSS_OPTS="${GOSS_OPTS:---color --format documentation}"

# Parse command line arguments
VERBOSE=false
FORMAT="documentation"
RETRY_COUNT=0
RETRY_SLEEP=5

print_usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Health check wrapper for k3s cluster using goss.

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -f, --format FORMAT     Output format: documentation, json, junit, tap, silent (default: documentation)
    -r, --retry COUNT       Retry health check COUNT times if it fails (default: 0)
    -s, --sleep SECONDS     Sleep SECONDS between retries (default: 5)
    -q, --quick             Run quick health check (skip some tests)

EXAMPLES:
    $(basename "$0")                    # Run full health check
    $(basename "$0") -v                 # Run with verbose output
    $(basename "$0") -f json            # Output in JSON format
    $(basename "$0") -r 3 -s 10         # Retry 3 times, wait 10s between retries

ENVIRONMENT VARIABLES:
    GOSS_FILE       Path to goss configuration file (default: /etc/goss/goss.yaml)
    GOSS_OPTS       Additional goss options

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        -r|--retry)
            RETRY_COUNT="$2"
            shift 2
            ;;
        -s|--sleep)
            RETRY_SLEEP="$2"
            shift 2
            ;;
        -q|--quick)
            # For quick checks, we could create a minimal goss file or skip certain tests
            echo -e "${YELLOW}Quick mode: Running basic health checks only${NC}"
            # You could add logic here to use a different goss file or filter tests
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Check if goss is installed
if ! command -v goss &> /dev/null; then
    echo -e "${RED}ERROR: goss command not found${NC}"
    echo "Please ensure goss is installed in the image"
    exit 1
fi

# Check if goss config file exists
if [ ! -f "$GOSS_FILE" ]; then
    echo -e "${RED}ERROR: Goss configuration file not found: $GOSS_FILE${NC}"
    exit 1
fi

if [ "$VERBOSE" = true ]; then
    echo -e "${BLUE}=== k3s Cluster Health Check ===${NC}"
    echo "Using goss version: $(goss --version)"
    echo "Configuration file: $GOSS_FILE"
    echo "Output format: $FORMAT"
    echo ""
fi

# Function to run goss validation
run_goss_check() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}Running health checks...${NC}"
    fi

    # Run goss with specified format and options
    goss --gossfile "$GOSS_FILE" validate --format "$FORMAT" $GOSS_OPTS
    return $?
}

# Main execution with retry logic
attempt=1
max_attempts=$((RETRY_COUNT + 1))

while [ $attempt -le $max_attempts ]; do
    if [ $attempt -gt 1 ]; then
        echo -e "${YELLOW}Retry attempt $attempt of $max_attempts...${NC}"
    fi

    if run_goss_check; then
        if [ "$VERBOSE" = true ] || [ "$FORMAT" = "documentation" ]; then
            echo ""
            echo -e "${GREEN}✓ k3s cluster health check passed!${NC}"
        fi
        exit 0
    else
        if [ $attempt -lt $max_attempts ]; then
            echo -e "${YELLOW}Health check failed. Waiting ${RETRY_SLEEP}s before retry...${NC}"
            sleep "$RETRY_SLEEP"
        fi
    fi

    ((attempt++))
done

# All attempts failed
echo ""
echo -e "${RED}✗ k3s cluster health check failed after $max_attempts attempt(s)${NC}"
exit 1
