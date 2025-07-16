#!/bin/bash

# Debug script to check Oracle Forms installation structure

echo "Oracle Forms Installation Debug Report"
echo "===================================="
echo ""

# Check various possible Oracle Home locations
echo "1. Checking possible Oracle Home locations..."
for dir in /opt/oracle/enterprise_home /opt/oracle/middleware /opt/oracle; do
    if [ -d "$dir" ]; then
        echo "✓ Found directory: $dir"
        echo "  Contents:"
        ls -la "$dir" | head -10
    else
        echo "✗ Not found: $dir"
    fi
    echo ""
done

# Look for Forms binaries
echo "2. Searching for Forms binaries..."
find /opt/oracle -name "frmcmp.sh" -type f 2>/dev/null | while read file; do
    echo "Found: $file"
    ls -la "$file"
done
echo ""

# Look for Forms libraries
echo "3. Searching for Forms libraries..."
find /opt/oracle -name "libfrmw.so*" -type f 2>/dev/null | while read file; do
    echo "Found: $file"
    ls -la "$file"
done
echo ""

# Look for JDAPI files
echo "4. Searching for JDAPI files..."
find /opt/oracle -name "frmjdapi.jar" -type f 2>/dev/null | while read file; do
    echo "Found: $file"
    ls -la "$file"
done
echo ""

# Check Forms directories
echo "5. Checking Forms directory structure..."
if [ -d "/opt/oracle/enterprise_home/forms" ]; then
    echo "Forms directory structure:"
    find /opt/oracle/enterprise_home/forms -type d | head -20
fi
echo ""

# Check environment
echo "6. Environment variables:"
echo "ORACLE_HOME: ${ORACLE_HOME:-NOT SET}"
echo "FORMS_HOME: ${FORMS_HOME:-NOT SET}"
echo "JAVA_HOME: ${JAVA_HOME:-NOT SET}"
echo "PATH: $PATH"
echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH:-NOT SET}"
echo ""

# Check Java installation
echo "7. Java installation:"
if [ -d "/usr/java" ]; then
    echo "Java directory contents:"
    ls -la /usr/java/
fi
if [ -x "/usr/java/jdk1.7.0_291/bin/java" ]; then
    echo "Java version:"
    /usr/java/jdk1.7.0_291/bin/java -version 2>&1
fi