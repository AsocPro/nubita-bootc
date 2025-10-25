#!/bin/bash
# Build script for Nubita Bootc k3s image

set -e

# Default values
DEFAULT_BASE_IMAGE="ghcr.io/ublue-os/base-main:latest"
DEFAULT_K3S_VERSION="v1.31.4+k3s1"
DEFAULT_IMAGE_NAME="localhost/nubita-bootc"
DEFAULT_IMAGE_TAG="latest"

# Parse command line arguments
BASE_IMAGE="${BASE_IMAGE:-$DEFAULT_BASE_IMAGE}"
K3S_VERSION="${K3S_VERSION:-$DEFAULT_K3S_VERSION}"
IMAGE_NAME="${IMAGE_NAME:-$DEFAULT_IMAGE_NAME}"
IMAGE_TAG="${IMAGE_TAG:-$DEFAULT_IMAGE_TAG}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Nubita Bootc Build Script ===${NC}"
echo ""
echo "Build Configuration:"
echo "  Base Image:    $BASE_IMAGE"
echo "  k3s Version:   $K3S_VERSION"
echo "  Output Image:  $IMAGE_NAME:$IMAGE_TAG"
echo ""

# Check if podman or docker is available
if command -v podman &> /dev/null; then
    CONTAINER_RUNTIME="podman"
elif command -v docker &> /dev/null; then
    CONTAINER_RUNTIME="docker"
else
    echo -e "${RED}ERROR: Neither podman nor docker found. Please install one.${NC}"
    exit 1
fi

echo -e "${GREEN}Using container runtime: $CONTAINER_RUNTIME${NC}"
echo ""

# Build the image
echo -e "${GREEN}Building bootc image...${NC}"
$CONTAINER_RUNTIME build \
    --build-arg BASE_IMAGE="$BASE_IMAGE" \
    --build-arg K3S_VERSION="$K3S_VERSION" \
    -t "$IMAGE_NAME:$IMAGE_TAG" \
    -f Containerfile \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=== Build Successful! ===${NC}"
    echo ""
    echo "Image: $IMAGE_NAME:$IMAGE_TAG"
    echo ""
    echo "Next steps:"
    echo "  1. Install to disk: sudo bootc switch --transport=oci-archive $IMAGE_NAME:$IMAGE_TAG"
    echo "  2. Or create installer ISO: sudo bootc install to-filesystem --target-imgref $IMAGE_NAME:$IMAGE_TAG"
    echo "  3. See docs/BUILD.md for more options"
    echo ""
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi
