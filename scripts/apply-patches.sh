#!/bin/bash

# Script to apply Oracle Forms patches
# Currently handles patch 18178044 for JDAPI Linux compatibility

echo "Starting Oracle Forms patch application..."

ORACLE_HOME=${ORACLE_HOME:-/opt/oracle/middleware}
PATCH_DIR="/tmp/forms-install/patches"
S3_BUCKET=${S3_BUCKET:-sunsofterpsetupfiles}

# Function to check for local patch file
check_patch() {
    local patch_file=$1
    local patch_number=$2
    
    echo "Checking for patch $patch_number..."
    
    # Check if patch was copied during build
    if [ -f "/tmp/patches/${patch_file}" ]; then
        echo "Found patch $patch_number"
        mkdir -p "$PATCH_DIR"
        cp "/tmp/patches/${patch_file}" "${PATCH_DIR}/${patch_file}"
        return 0
    else
        echo "Patch $patch_number not available"
        return 1
    fi
}

# Function to apply patch 18178044 (JDAPI Linux fix)
apply_patch_18178044() {
    local patch_file="p18178044_111220_Linux-x86-64.zip"
    
    if check_patch "$patch_file" "18178044"; then
        echo "Applying patch 18178044 for JDAPI Linux compatibility..."
        
        cd "$PATCH_DIR"
        unzip -q "$patch_file"
        
        # The patch typically contains updated jar files
        # Copy them to the appropriate locations
        if [ -d "18178044" ]; then
            cd "18178044"
            
            # Backup original files
            if [ -f "$ORACLE_HOME/jlib/frmjdapi.jar" ]; then
                cp "$ORACLE_HOME/jlib/frmjdapi.jar" "$ORACLE_HOME/jlib/frmjdapi.jar.orig"
            fi
            
            # Apply patch files
            if [ -f "files/jlib/frmjdapi.jar" ]; then
                cp "files/jlib/frmjdapi.jar" "$ORACLE_HOME/jlib/"
                echo "Updated frmjdapi.jar with patch 18178044"
            fi
            
            # Apply any other patch files
            if [ -d "files" ]; then
                cd files
                find . -type f | while read file; do
                    target_file="$ORACLE_HOME/${file#./}"
                    target_dir=$(dirname "$target_file")
                    
                    if [ ! -d "$target_dir" ]; then
                        mkdir -p "$target_dir"
                    fi
                    
                    cp "$file" "$target_file"
                    echo "Updated $file"
                done
            fi
            
            echo "Patch 18178044 applied successfully"
        else
            echo "ERROR: Patch directory structure not as expected"
            return 1
        fi
    else
        echo "Patch 18178044 not available, continuing without it"
        echo "Note: JDAPI may have issues on Linux without this patch"
    fi
}

# Main patch application process
main() {
    echo "Oracle Forms patch application process"
    echo "====================================="
    
    # Check if Oracle Home exists
    if [ ! -d "$ORACLE_HOME" ]; then
        echo "WARNING: ORACLE_HOME not found at $ORACLE_HOME"
        echo "Checking for alternative Oracle installations..."
        
        # Check if enterprise_home extracted directly to /opt/oracle
        if [ -d "/opt/oracle/bin" ] && [ -f "/opt/oracle/bin/frmcmp.sh" ]; then
            echo "Found Oracle installation at /opt/oracle"
            export ORACLE_HOME=/opt/oracle
            export FORMS_HOME=/opt/oracle
        else
            echo "No Oracle installation found. Skipping patch application."
            echo "This is expected if building without enterprise_home.tgz"
            exit 0
        fi
    fi
    
    # Apply patches
    apply_patch_18178044
    
    # Clean up patch files
    if [ -d "$PATCH_DIR" ]; then
        echo "Cleaning up patch files..."
        rm -rf "$PATCH_DIR"
    fi
    
    echo ""
    echo "Patch application process completed"
}

# Run main function
main