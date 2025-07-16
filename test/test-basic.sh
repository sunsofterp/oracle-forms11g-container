#!/bin/bash

# Basic test script for Oracle Forms Docker container
# This checks that the container has the basic Forms components installed

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
    
    echo -n "Running: $test_name... "
    
    if output=$($CONTAINER_RUNTIME run --rm "$IMAGE_NAME:$IMAGE_TAG" bash -c "$test_command" 2>&1); then
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        if [ -n "$output" ]; then
            echo "Output: $output" | head -5
        fi
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        print_error "Command failed with exit code: $?"
        echo "Error output:"
        echo "$output" | head -20
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Main test execution
echo "Oracle Forms 11g Docker Image Basic Test Suite"
echo "=============================================="
echo ""
print_info "Testing image: $IMAGE_NAME:$IMAGE_TAG"
print_info "Using runtime: $CONTAINER_RUNTIME"

# Check if image exists
print_info "Checking if image exists: $IMAGE_NAME:$IMAGE_TAG"
if ! $CONTAINER_RUNTIME images | grep -q "$IMAGE_NAME.*$IMAGE_TAG"; then
    print_error "Image not found: $IMAGE_NAME:$IMAGE_TAG"
    exit 1
fi
print_info "Image found!"

# Test 1: Check Forms compiler exists
print_test_header "Test 1: Forms Compiler Exists"
run_test "Check frmcmp.sh exists" \
    "test -f /opt/oracle/enterprise_home/bin/frmcmp.sh && echo 'Forms compiler found'"

# Test 2: Check JDAPI jar exists
print_test_header "Test 2: JDAPI JAR Exists"
run_test "Check frmjdapi.jar exists" \
    "test -f /opt/oracle/enterprise_home/jlib/frmjdapi.jar && echo 'JDAPI jar found'"

# Test 3: Check Java installation
print_test_header "Test 3: Java Installation"
run_test "Check Java version" \
    "java -version 2>&1 | head -1"

# Test 4: Check environment variables
print_test_header "Test 4: Environment Variables"
run_test "Check ORACLE_HOME" \
    "echo ORACLE_HOME=\$ORACLE_HOME"

# Test 5: Check Forms directory structure
print_test_header "Test 5: Forms Directory Structure"
run_test "Check Forms directories" \
    "ls -d /opt/oracle/enterprise_home/forms/* 2>/dev/null | wc -l"

# Summary
echo ""
echo "=========================================="
echo "Test Summary:"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
echo "=========================================="

if [ $TESTS_FAILED -gt 0 ]; then
    print_error "Some tests failed!"
    exit 1
else
    print_info "All tests passed!"
    exit 0
fi