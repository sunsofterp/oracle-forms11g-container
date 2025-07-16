#!/bin/bash

# Test script for Oracle Forms compiler in Docker container

set -e

# Default values
IMAGE_NAME="${IMAGE_NAME:-oracle-forms}"
IMAGE_TAG="${IMAGE_TAG:-11.1.2.2.0}"
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-docker}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

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

print_test_header() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_output="$3"
    
    echo -n "Running: $test_name... "
    
    if output=$($CONTAINER_RUNTIME run --rm "$IMAGE_NAME:$IMAGE_TAG" bash -c "$test_command" 2>&1); then
        if [ -n "$expected_output" ]; then
            if echo "$output" | grep -q "$expected_output"; then
                echo -e "${GREEN}PASSED${NC}"
                TESTS_PASSED=$((TESTS_PASSED + 1))
                return 0
            else
                echo -e "${RED}FAILED${NC}"
                print_error "Expected output not found: $expected_output"
                echo "Actual output:"
                echo "$output" | head -20
                TESTS_FAILED=$((TESTS_FAILED + 1))
                return 1
            fi
        else
            echo -e "${GREEN}PASSED${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        fi
    else
        echo -e "${RED}FAILED${NC}"
        print_error "Command failed with exit code: $?"
        echo "Error output:"
        echo "$output" | head -20
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Check if image exists
check_image() {
    print_info "Checking if image exists: $IMAGE_NAME:$IMAGE_TAG"
    
    if ! $CONTAINER_RUNTIME images | grep -q "$IMAGE_NAME.*$IMAGE_TAG"; then
        print_error "Image not found: $IMAGE_NAME:$IMAGE_TAG"
        print_error "Please build the image first using: ./build.sh"
        exit 1
    fi
    
    print_info "Image found!"
}

# Test 1: Forms compiler help
test_compiler_help() {
    print_test_header "Test 1: Forms Compiler Help"
    
    run_test "frmcmp.sh help" \
        "frmcmp.sh help=yes" \
        "Forms Compiler"
}

# Test 2: Forms compiler version
test_compiler_version() {
    print_test_header "Test 2: Forms Compiler Version"
    
    run_test "frmcmp.sh version check" \
        "frmcmp.sh help=yes | grep -E 'Version|Release'" \
        "11.1.2"
}

# Test 3: Forms batch compiler
test_batch_compiler() {
    print_test_header "Test 3: Forms Batch Compiler"
    
    run_test "frmcmp_batch.sh help" \
        "frmcmp_batch.sh help=yes" \
        "Forms Compiler"
}

# Test 4: Environment variables
test_environment() {
    print_test_header "Test 4: Environment Variables"
    
    run_test "ORACLE_HOME check" \
        "echo \$ORACLE_HOME" \
        "/opt/oracle/middleware"
    
    run_test "FORMS_HOME check" \
        "echo \$FORMS_HOME" \
        "/opt/oracle/middleware"
    
    run_test "PATH includes Forms bin" \
        "echo \$PATH | grep -o '/opt/oracle/middleware/bin'" \
        "/opt/oracle/middleware/bin"
}

# Test 5: Required libraries
test_libraries() {
    print_test_header "Test 5: Required Libraries"
    
    run_test "Forms runtime library" \
        "ls -la \$ORACLE_HOME/lib/libfrmw.so.0" \
        "libfrmw.so.0"
    
    run_test "LD_LIBRARY_PATH check" \
        "echo \$LD_LIBRARY_PATH | grep -o '/opt/oracle/middleware/lib'" \
        "/opt/oracle/middleware/lib"
}

# Test 6: Compile a simple form
test_compile_form() {
    print_test_header "Test 6: Compile Test Form"
    
    # Create a simple test form
    cat > sample.fmb.hex << 'EOF'
# This would be a hex dump of a simple Oracle Forms file
# For now, we'll skip actual compilation test
EOF
    
    print_warn "Skipping actual form compilation (requires valid .fmb file)"
    
    # Test that compiler accepts proper syntax
    run_test "Compiler syntax check" \
        "frmcmp.sh module=/nonexistent.fmb 2>&1 | grep -E 'FRM-|Unable to open'" \
        "FRM-"
    
    rm -f sample.fmb.hex
}

# Test 7: Working directory
test_working_directory() {
    print_test_header "Test 7: Working Directory"
    
    run_test "Working directory check" \
        "pwd" \
        "/home/oracle/work"
    
    run_test "Work directory is writable" \
        "touch /home/oracle/work/test.txt && echo 'writable'" \
        "writable"
}

# Test 8: Java environment
test_java_environment() {
    print_test_header "Test 8: Java Environment"
    
    run_test "JAVA_HOME check" \
        "echo \$JAVA_HOME" \
        "/usr/java/jdk1.7.0_291"
    
    run_test "Java version" \
        "java -version 2>&1 | grep -o '1.7'" \
        "1.7"
}

# Test 9: Container info command
test_info_command() {
    print_test_header "Test 9: Container Info Command"
    
    run_test "Info command" \
        "info" \
        "Oracle Forms 11g Container Environment"
}

# Test 10: File permissions
test_permissions() {
    print_test_header "Test 10: File Permissions"
    
    run_test "Oracle user check" \
        "whoami" \
        "oracle"
    
    run_test "Home directory ownership" \
        "ls -ld /home/oracle | grep -o 'oracle oracle'" \
        "oracle oracle"
}

# Main test execution
main() {
    echo "Oracle Forms 11g Docker Image Test Suite"
    echo "========================================"
    echo ""
    print_info "Testing image: $IMAGE_NAME:$IMAGE_TAG"
    print_info "Using runtime: $CONTAINER_RUNTIME"
    
    # Check if image exists
    check_image
    
    # Run all tests
    test_compiler_help
    test_compiler_version
    test_batch_compiler
    test_environment
    test_libraries
    test_compile_form
    test_working_directory
    test_java_environment
    test_info_command
    test_permissions
    
    # Summary
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo "Test Summary"
    echo -e "${GREEN}========================================${NC}"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo ""
        echo -e "${GREEN}All tests passed successfully!${NC}"
        exit 0
    else
        echo ""
        echo -e "${RED}Some tests failed. Please check the output above.${NC}"
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --runtime)
            CONTAINER_RUNTIME="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --image NAME     Docker image name (default: oracle-forms)"
            echo "  --tag TAG        Docker image tag (default: 11.1.2.2.0)"
            echo "  --runtime RT     Container runtime (default: docker)"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main