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
find /opt/oracle -name "libfrm*.so*" -type f 2>/dev/null | head -10 | while read file; do
    echo "Found Forms lib: $file"
done
echo ""

# Check lib directories
echo "3a. Checking lib directories..."
for dir in /opt/oracle/enterprise_home/lib /opt/oracle/enterprise_home/forms/lib; do
    if [ -d "$dir" ]; then
        echo "Contents of $dir:"
        ls -la "$dir" | grep -E "(libfrm|\.so)" | head -10
    fi
done
echo ""

# Look for JDAPI files
echo "4. Searching for JDAPI files..."
find /opt/oracle -name "frmjdapi.jar" -type f 2>/dev/null | while read file; do
    echo "Found: $file"
    ls -la "$file"
done
find /opt/oracle -name "frmall.jar" -type f 2>/dev/null | while read file; do
    echo "Found frmall.jar: $file"
    ls -la "$file"
done
echo ""

# Check jlib directory
echo "4a. Checking jlib directory..."
if [ -d "/opt/oracle/enterprise_home/jlib" ]; then
    echo "Contents of /opt/oracle/enterprise_home/jlib (Forms-related jars):"
    ls -la /opt/oracle/enterprise_home/jlib | grep -E "(frm|forms)" | head -10
fi
echo ""

# Check Forms directories
echo "5. Checking Forms directory structure..."
if [ -d "/opt/oracle/enterprise_home/forms" ]; then
    echo "Forms directory structure:"
    find /opt/oracle/enterprise_home/forms -type d | head -20
fi
echo ""

# Check for environment files
echo "5a. Searching for environment files..."
find /opt/oracle -name "*.env" -type f 2>/dev/null | grep -i forms | head -10 | while read file; do
    echo "Found env file: $file"
done
if [ -d "/opt/oracle/enterprise_home/forms/server" ]; then
    echo "Contents of forms/server directory:"
    ls -la /opt/oracle/enterprise_home/forms/server 2>/dev/null | head -10
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