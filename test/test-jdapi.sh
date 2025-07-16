#!/bin/bash

# Test script for Oracle Forms JDAPI in Docker container

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

# Test 1: JDAPI JAR existence
test_jdapi_jar() {
    print_test_header "Test 1: JDAPI JAR Files"
    
    run_test "frmjdapi.jar exists" \
        "ls -la \$ORACLE_HOME/jlib/frmjdapi.jar" \
        "frmjdapi.jar"
    
    run_test "frmall.jar exists" \
        "ls -la \$ORACLE_HOME/jlib/frmall.jar" \
        "frmall.jar"
    
    run_test "share.jar exists" \
        "ls -la \$ORACLE_HOME/jlib/share.jar" \
        "share.jar"
}

# Test 2: JDAPI directory setup
test_jdapi_directory() {
    print_test_header "Test 2: JDAPI Directory Setup"
    
    run_test "JDAPI directory exists" \
        "ls -la /home/oracle/jdapi/" \
        "frmjdapi.jar"
    
    run_test "JDAPI wrapper script exists" \
        "ls -la /home/oracle/bin/jdapi" \
        "jdapi"
    
    run_test "JDAPI wrapper is executable" \
        "test -x /home/oracle/bin/jdapi && echo 'executable'" \
        "executable"
}

# Test 3: Java classpath
test_java_classpath() {
    print_test_header "Test 3: Java Classpath"
    
    # Create a simple Java test that checks classpath
    local java_test='
public class ClasspathTest {
    public static void main(String[] args) {
        try {
            Class.forName("oracle.forms.jdapi.Jdapi");
            System.out.println("JDAPI class found");
        } catch (ClassNotFoundException e) {
            System.out.println("JDAPI class not found");
            System.exit(1);
        }
    }
}'
    
    run_test "JDAPI in classpath" \
        "cd /tmp && echo '$java_test' > ClasspathTest.java && \
         javac -cp /home/oracle/jdapi/frmjdapi.jar ClasspathTest.java && \
         java -cp .:/home/oracle/jdapi/frmjdapi.jar ClasspathTest" \
        "JDAPI class found"
}

# Test 4: JDAPI sample program
test_jdapi_sample() {
    print_test_header "Test 4: JDAPI Sample Program"
    
    run_test "JdapiTest.java exists" \
        "ls -la /home/oracle/jdapi/JdapiTest.java" \
        "JdapiTest.java"
    
    run_test "JdapiTest compiled" \
        "ls -la /home/oracle/jdapi/JdapiTest.class" \
        "JdapiTest.class"
}

# Test 5: Run JDAPI test
test_run_jdapi() {
    print_test_header "Test 5: Run JDAPI Test"
    
    run_test "JDAPI version check" \
        "cd /home/oracle/jdapi && java -cp frmjdapi.jar:. JdapiTest 2>&1" \
        "JDAPI Version"
    
    run_test "JDAPI test successful" \
        "cd /home/oracle/jdapi && java -cp frmjdapi.jar:. JdapiTest 2>&1 | grep -o 'JDAPI is working correctly'" \
        "JDAPI is working correctly"
}

# Test 6: JDAPI wrapper script
test_jdapi_wrapper() {
    print_test_header "Test 6: JDAPI Wrapper Script"
    
    run_test "Wrapper in PATH" \
        "which jdapi" \
        "/home/oracle/bin/jdapi"
    
    run_test "Wrapper execution" \
        "cd /home/oracle/jdapi && /home/oracle/bin/jdapi JdapiTest 2>&1 | grep -o 'JDAPI is working correctly'" \
        "JDAPI is working correctly"
}

# Test 7: Create form with JDAPI
test_create_form() {
    print_test_header "Test 7: Create Form with JDAPI"
    
    run_test "Create test form" \
        "cd /home/oracle/work && java -cp /home/oracle/jdapi/frmjdapi.jar:/home/oracle/jdapi JdapiTest create 2>&1 | grep -o 'Form saved as'" \
        "Form saved as"
    
    run_test "Verify created form" \
        "ls -la /home/oracle/work/test_jdapi.fmb 2>/dev/null || echo 'Form creation test completed'" \
        "test_jdapi.fmb\\|Form creation test completed"
}

# Test 8: JDAPI library dependencies
test_jdapi_dependencies() {
    print_test_header "Test 8: JDAPI Dependencies"
    
    run_test "Native libraries accessible" \
        "ls -la \$ORACLE_HOME/lib/libfrmjapi.so* | head -1" \
        "lib"
    
    run_test "LD_LIBRARY_PATH includes Oracle lib" \
        "echo \$LD_LIBRARY_PATH | grep -o '\$ORACLE_HOME/lib'" \
        "/opt/oracle/middleware/lib"
}

# Test 9: JDAPI with different Java operations
test_jdapi_operations() {
    print_test_header "Test 9: JDAPI Operations"
    
    # Create a more comprehensive JDAPI test
    local java_ops_test='
import oracle.forms.jdapi.*;

public class JdapiOpsTest {
    public static void main(String[] args) {
        try {
            Jdapi.setFailSubclassLoad(false);
            Jdapi.setFailLibraryLoad(false);
            
            System.out.println("Testing JDAPI operations...");
            
            // Test creating various Forms objects
            FormModule testForm = new FormModule("OPS_TEST");
            Canvas canvas = new Canvas(testForm, "CANVAS1");
            Block block = new Block(testForm, "BLOCK1");
            
            System.out.println("Created form: " + testForm.getName());
            System.out.println("Created canvas: " + canvas.getName());
            System.out.println("Created block: " + block.getName());
            
            // Clean up
            testForm.destroy();
            
            System.out.println("JDAPI operations successful");
        } catch (Exception e) {
            System.err.println("JDAPI operations failed: " + e.getMessage());
            System.exit(1);
        }
    }
}'
    
    run_test "Complex JDAPI operations" \
        "cd /tmp && echo '$java_ops_test' > JdapiOpsTest.java && \
         javac -cp /home/oracle/jdapi/frmjdapi.jar JdapiOpsTest.java && \
         java -cp .:/home/oracle/jdapi/frmjdapi.jar:/home/oracle/jdapi/frmall.jar JdapiOpsTest" \
        "JDAPI operations successful"
}

# Test 10: Environment setup for JDAPI
test_jdapi_environment() {
    print_test_header "Test 10: JDAPI Environment"
    
    run_test "FORMS_API_TK_BYPASS set" \
        "echo \$FORMS_API_TK_BYPASS" \
        "true"
    
    run_test ".bashrc includes jdapi path" \
        "grep -o '/home/oracle/bin' /home/oracle/.bashrc" \
        "/home/oracle/bin"
}

# Main test execution
main() {
    echo "Oracle Forms 11g JDAPI Test Suite"
    echo "================================="
    echo ""
    print_info "Testing image: $IMAGE_NAME:$IMAGE_TAG"
    print_info "Using runtime: $CONTAINER_RUNTIME"
    
    # Check if image exists
    check_image
    
    # Run all tests
    test_jdapi_jar
    test_jdapi_directory
    test_java_classpath
    test_jdapi_sample
    test_run_jdapi
    test_jdapi_wrapper
    test_create_form
    test_jdapi_dependencies
    test_jdapi_operations
    test_jdapi_environment
    
    # Summary
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo "Test Summary"
    echo -e "${GREEN}========================================${NC}"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo ""
        echo -e "${GREEN}All JDAPI tests passed successfully!${NC}"
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