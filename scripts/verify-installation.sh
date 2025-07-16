#!/bin/bash

# Script to verify Oracle Forms installation

echo "Verifying Oracle Forms 11g installation..."
echo "========================================="

ORACLE_HOME=${ORACLE_HOME:-/opt/oracle/middleware}
ERRORS=0

# Function to check if a file exists
check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        echo "✓ Found: $description"
        return 0
    else
        echo "✗ Missing: $description ($file)"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to check if a directory exists
check_directory() {
    local dir=$1
    local description=$2
    
    if [ -d "$dir" ]; then
        echo "✓ Found: $description"
        return 0
    else
        echo "✗ Missing: $description ($dir)"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to check executable
check_executable() {
    local exe=$1
    local description=$2
    
    if [ -x "$exe" ]; then
        echo "✓ Executable: $description"
        return 0
    else
        echo "✗ Not executable: $description ($exe)"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Main verification
echo ""
echo "1. Checking Oracle Home..."
check_directory "$ORACLE_HOME" "Oracle Home directory"

echo ""
echo "2. Checking Forms binaries..."
check_file "$ORACLE_HOME/bin/frmcmp.sh" "Forms Compiler"
check_executable "$ORACLE_HOME/bin/frmcmp.sh" "Forms Compiler"
check_file "$ORACLE_HOME/bin/frmcmp_batch.sh" "Forms Batch Compiler"
check_executable "$ORACLE_HOME/bin/frmcmp_batch.sh" "Forms Batch Compiler"

echo ""
echo "3. Checking Forms libraries..."
check_directory "$ORACLE_HOME/lib" "Forms library directory"
check_file "$ORACLE_HOME/lib/libfrmw.so.0" "Forms runtime library"

echo ""
echo "4. Checking JDAPI components..."
check_directory "$ORACLE_HOME/jlib" "Java library directory"
check_file "$ORACLE_HOME/jlib/frmjdapi.jar" "Forms JDAPI JAR"
check_file "$ORACLE_HOME/jlib/frmall.jar" "Forms runtime JAR"

echo ""
echo "5. Checking Forms configuration..."
check_directory "$ORACLE_HOME/forms" "Forms configuration directory"
check_file "$ORACLE_HOME/forms/server/default.env" "Default environment file"

echo ""
echo "6. Testing Forms compiler..."
if [ -x "$ORACLE_HOME/bin/frmcmp.sh" ]; then
    echo "Running compiler test..."
    if $ORACLE_HOME/bin/frmcmp.sh help=yes >/dev/null 2>&1; then
        echo "✓ Forms compiler is functional"
        # Get version info
        echo ""
        echo "Forms version information:"
        $ORACLE_HOME/bin/frmcmp.sh help=yes 2>&1 | head -10 | grep -E "Forms|Release|Version" || true
    else
        echo "✗ Forms compiler test failed"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "✗ Cannot test compiler - not executable"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "7. Checking Java environment..."
if [ -n "$JAVA_HOME" ] && [ -d "$JAVA_HOME" ]; then
    echo "✓ JAVA_HOME is set: $JAVA_HOME"
    if [ -x "$JAVA_HOME/bin/java" ]; then
        echo "✓ Java executable found"
        $JAVA_HOME/bin/java -version 2>&1 | head -1
    else
        echo "✗ Java executable not found"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "✗ JAVA_HOME not set or directory not found"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "8. Checking environment variables..."
echo "ORACLE_BASE: ${ORACLE_BASE:-NOT SET}"
echo "ORACLE_HOME: ${ORACLE_HOME:-NOT SET}"
echo "FORMS_HOME: ${FORMS_HOME:-NOT SET}"
echo "TNS_ADMIN: ${TNS_ADMIN:-NOT SET}"
echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH:-NOT SET}"

# Final summary
echo ""
echo "========================================="
if [ $ERRORS -eq 0 ]; then
    echo "✓ Oracle Forms installation verified successfully!"
    echo "All components are present and appear to be functional."
    exit 0
else
    echo "✗ Verification failed with $ERRORS error(s)"
    echo "Please check the missing components above."
    exit 1
fi