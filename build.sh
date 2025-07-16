#!/bin/bash

# Oracle Forms 11g Docker Image Build Script

set -e

# Default values
IMAGE_NAME="oracle-forms"
IMAGE_TAG="11.1.2.2.0"
S3_BUCKET="sunsofterpsetupfiles"
BUILD_WITH_S3=false
LOCAL_ENTERPRISE_HOME=""
PUSH_TO_REGISTRY=false
REGISTRY=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --name NAME          Docker image name (default: oracle-forms)"
    echo "  -t, --tag TAG            Docker image tag (default: 11.1.2.2.0)"
    echo "  -s, --s3                 Build using S3 download (requires AWS credentials)"
    echo "  -f, --file FILE          Path to local enterprise_home.tgz file"
    echo "  -b, --bucket BUCKET      S3 bucket name (default: sunsofterpsetupfiles)"
    echo "  -p, --push               Push image to registry after build"
    echo "  -r, --registry REGISTRY  Registry URL (e.g., docker.io, ghcr.io)"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Build with S3 download"
    echo "  $0 --s3"
    echo ""
    echo "  # Build with local file"
    echo "  $0 --file /path/to/enterprise_home.tgz"
    echo ""
    echo "  # Build and push to Docker Hub"
    echo "  $0 --s3 --push --registry docker.io/myorg"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -s|--s3)
            BUILD_WITH_S3=true
            shift
            ;;
        -f|--file)
            LOCAL_ENTERPRISE_HOME="$2"
            shift 2
            ;;
        -b|--bucket)
            S3_BUCKET="$2"
            shift 2
            ;;
        -p|--push)
            PUSH_TO_REGISTRY=true
            shift
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate options
if [ "$BUILD_WITH_S3" = true ] && [ -n "$LOCAL_ENTERPRISE_HOME" ]; then
    print_error "Cannot use both --s3 and --file options"
    exit 1
fi

if [ "$BUILD_WITH_S3" = false ] && [ -z "$LOCAL_ENTERPRISE_HOME" ]; then
    print_error "Must specify either --s3 or --file option"
    usage
    exit 1
fi

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Docker/Podman
    if command -v podman &> /dev/null; then
        CONTAINER_RUNTIME="podman"
        print_info "Using podman as container runtime"
    elif command -v docker &> /dev/null; then
        CONTAINER_RUNTIME="docker"
        print_info "Using docker as container runtime"
    else
        print_error "Neither docker nor podman found. Please install one of them."
        exit 1
    fi
    
    # Check if we can run containers
    if ! $CONTAINER_RUNTIME ps &> /dev/null; then
        print_error "Cannot connect to $CONTAINER_RUNTIME daemon. Is it running?"
        exit 1
    fi
}

# Function to check AWS prerequisites
check_aws_prerequisites() {
    if [ "$BUILD_WITH_S3" = true ]; then
        print_info "Checking AWS prerequisites..."
        
        # Check if AWS CLI is available
        if ! command -v aws &> /dev/null; then
            print_error "AWS CLI not found. Please install AWS CLI"
            exit 1
        fi
        
        # Test S3 access (AWS CLI will use credentials from env, config file, or IAM role)
        print_info "Testing S3 access to bucket: $S3_BUCKET"
        if aws s3 ls "s3://$S3_BUCKET/enterprise_home.tgz" &> /dev/null; then
            print_info "Successfully verified access to S3 bucket"
        else
            print_error "Cannot access s3://$S3_BUCKET/enterprise_home.tgz"
            print_error "Please check your AWS credentials and bucket permissions"
            print_error "AWS CLI will look for credentials in this order:"
            print_error "  1. Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)"
            print_error "  2. AWS credentials file (~/.aws/credentials)"
            print_error "  3. IAM role (if running on EC2)"
            exit 1
        fi
    fi
}

# Function to prepare local file
prepare_local_file() {
    if [ -n "$LOCAL_ENTERPRISE_HOME" ]; then
        print_info "Checking local enterprise_home.tgz file..."
        
        if [ ! -f "$LOCAL_ENTERPRISE_HOME" ]; then
            print_error "File not found: $LOCAL_ENTERPRISE_HOME"
            exit 1
        fi
        
        # Copy file to build context
        print_info "Copying enterprise_home.tgz to build context..."
        cp "$LOCAL_ENTERPRISE_HOME" ./enterprise_home.tgz
    fi
}

# Function to download files from S3
download_s3_files() {
    if [ "$BUILD_WITH_S3" = true ]; then
        print_info "Downloading files from S3..."
        
        # Download JDK if not present
        if [ ! -f "jdk-7u291-linux-x64.rpm" ]; then
            print_info "Downloading JDK 7..."
            if ! aws s3 cp "s3://${S3_BUCKET}/jdk-7u291-linux-x64.rpm" ./jdk-7u291-linux-x64.rpm; then
                print_error "Failed to download JDK 7"
                exit 1
            fi
        else
            print_info "JDK 7 already present"
        fi
        
        # Download enterprise_home.tgz
        print_info "Downloading enterprise_home.tgz..."
        if ! aws s3 cp "s3://${S3_BUCKET}/enterprise_home.tgz" ./enterprise_home.tgz; then
            print_error "Failed to download enterprise_home.tgz"
            exit 1
        fi
        
        # Optionally download patch
        if aws s3 ls "s3://${S3_BUCKET}/p18178044_111220_Linux-x86-64.zip" &> /dev/null; then
            print_info "Downloading patch 18178044..."
            mkdir -p patches
            aws s3 cp "s3://${S3_BUCKET}/p18178044_111220_Linux-x86-64.zip" ./patches/
        fi
    fi
}

# Function to build image
build_image() {
    print_info "Building Docker image..."
    print_info "Image: $IMAGE_NAME:$IMAGE_TAG"
    
    # Build the image
    if $CONTAINER_RUNTIME build -t "$IMAGE_NAME:$IMAGE_TAG" .; then
        print_info "Image built successfully: $IMAGE_NAME:$IMAGE_TAG"
        
        # Tag additional versions
        $CONTAINER_RUNTIME tag "$IMAGE_NAME:$IMAGE_TAG" "$IMAGE_NAME:11.1.2"
        $CONTAINER_RUNTIME tag "$IMAGE_NAME:$IMAGE_TAG" "$IMAGE_NAME:11g"
        $CONTAINER_RUNTIME tag "$IMAGE_NAME:$IMAGE_TAG" "$IMAGE_NAME:latest"
        
        print_info "Tagged as:"
        print_info "  - $IMAGE_NAME:11.1.2"
        print_info "  - $IMAGE_NAME:11g"
        print_info "  - $IMAGE_NAME:latest"
    else
        print_error "Image build failed"
        cleanup
        exit 1
    fi
}

# Function to test image
test_image() {
    print_info "Testing Docker image..."
    
    # Test 1: Check if container starts
    print_info "Test 1: Container startup..."
    if $CONTAINER_RUNTIME run --rm "$IMAGE_NAME:$IMAGE_TAG" echo "Container started successfully"; then
        print_info "✓ Container starts successfully"
    else
        print_error "✗ Container failed to start"
        return 1
    fi
    
    # Test 2: Check Forms compiler
    print_info "Test 2: Forms compiler..."
    if $CONTAINER_RUNTIME run --rm "$IMAGE_NAME:$IMAGE_TAG" frmcmp.sh help=yes &> /dev/null; then
        print_info "✓ Forms compiler is working"
    else
        print_error "✗ Forms compiler test failed"
        return 1
    fi
    
    # Test 3: Check environment
    print_info "Test 3: Environment info..."
    if $CONTAINER_RUNTIME run --rm "$IMAGE_NAME:$IMAGE_TAG" info | grep -q "Oracle Forms"; then
        print_info "✓ Environment is configured correctly"
    else
        print_error "✗ Environment check failed"
        return 1
    fi
    
    print_info "All tests passed!"
    return 0
}

# Function to push image
push_image() {
    if [ "$PUSH_TO_REGISTRY" = true ]; then
        if [ -z "$REGISTRY" ]; then
            print_error "Registry URL not specified. Use --registry option"
            exit 1
        fi
        
        print_info "Pushing image to registry: $REGISTRY"
        
        # Tag for registry
        FULL_IMAGE_NAME="$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
        $CONTAINER_RUNTIME tag "$IMAGE_NAME:$IMAGE_TAG" "$FULL_IMAGE_NAME"
        
        # Push image
        if $CONTAINER_RUNTIME push "$FULL_IMAGE_NAME"; then
            print_info "Successfully pushed: $FULL_IMAGE_NAME"
            
            # Push other tags
            for TAG in "11.1.2" "11g" "latest"; do
                $CONTAINER_RUNTIME tag "$IMAGE_NAME:$TAG" "$REGISTRY/$IMAGE_NAME:$TAG"
                $CONTAINER_RUNTIME push "$REGISTRY/$IMAGE_NAME:$TAG"
                print_info "Pushed: $REGISTRY/$IMAGE_NAME:$TAG"
            done
        else
            print_error "Failed to push image"
            exit 1
        fi
    fi
}

# Function to cleanup
cleanup() {
    print_info "Cleaning up..."
    
    # Remove downloaded files if we downloaded them from S3
    if [ "$BUILD_WITH_S3" = true ]; then
        rm -f ./enterprise_home.tgz
        # Keep JDK for future builds
    fi
    
    # Remove local copy of enterprise_home.tgz if we created it
    if [ -f "./enterprise_home.tgz" ] && [ -n "$LOCAL_ENTERPRISE_HOME" ]; then
        rm -f ./enterprise_home.tgz
    fi
}

# Main execution
main() {
    echo "Oracle Forms 11g Docker Image Builder"
    echo "====================================="
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Check AWS prerequisites if needed
    check_aws_prerequisites
    
    # Download S3 files if needed
    download_s3_files
    
    # Prepare local file if needed
    prepare_local_file
    
    # Build image
    build_image
    
    # Test image
    if test_image; then
        print_info "Image is ready to use!"
        
        # Push to registry if requested
        push_image
    else
        print_error "Image tests failed"
        cleanup
        exit 1
    fi
    
    # Cleanup
    cleanup
    
    echo ""
    print_info "Build completed successfully!"
    print_info "To run the container:"
    echo "  $CONTAINER_RUNTIME run --rm -it $IMAGE_NAME:$IMAGE_TAG"
}

# Run main function
main