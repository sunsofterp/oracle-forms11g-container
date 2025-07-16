#!/bin/bash

# Script to extract and make JDAPI accessible for Forms development

echo "Extracting and setting up Forms JDAPI..."
echo "========================================"

ORACLE_HOME=${ORACLE_HOME:-/opt/oracle}
JDAPI_DIR="/home/oracle/jdapi"

# Create JDAPI directory
mkdir -p "$JDAPI_DIR"

# Function to copy JDAPI files
copy_jdapi_files() {
    local source_dir="$ORACLE_HOME/jlib"
    local target_dir="$JDAPI_DIR"
    
    echo "Copying JDAPI files to $target_dir..."
    
    # Core JDAPI files
    local jdapi_files=(
        "frmjdapi.jar"
        "frmall.jar"
        "frmbld.jar"
        "share.jar"
        "importer.jar"
        "http_client.jar"
        "oracle_ice.jar"
    )
    
    for file in "${jdapi_files[@]}"; do
        if [ -f "$source_dir/$file" ]; then
            cp "$source_dir/$file" "$target_dir/"
            echo "✓ Copied $file"
        else
            echo "⚠ Warning: $file not found"
        fi
    done
}

# Function to create JDAPI wrapper script
create_jdapi_wrapper() {
    local wrapper_script="/home/oracle/bin/jdapi"
    
    mkdir -p /home/oracle/bin
    
    cat > "$wrapper_script" << 'EOF'
#!/bin/bash
# JDAPI wrapper script for Oracle Forms

ORACLE_HOME=${ORACLE_HOME:-/opt/oracle}
JDAPI_DIR="/home/oracle/jdapi"
JAVA_HOME=${JAVA_HOME:-/usr/java/jdk1.7.0_291}

# Build classpath
CLASSPATH="$JDAPI_DIR/frmjdapi.jar"
CLASSPATH="$CLASSPATH:$JDAPI_DIR/frmall.jar"
CLASSPATH="$CLASSPATH:$JDAPI_DIR/share.jar"
CLASSPATH="$CLASSPATH:$JDAPI_DIR/frmbld.jar"
CLASSPATH="$CLASSPATH:$JDAPI_DIR/importer.jar"
CLASSPATH="$CLASSPATH:$JDAPI_DIR/http_client.jar"
CLASSPATH="$CLASSPATH:$JDAPI_DIR/oracle_ice.jar"

# Add user classpath if provided
if [ -n "$USER_CLASSPATH" ]; then
    CLASSPATH="$CLASSPATH:$USER_CLASSPATH"
fi

# Export environment
export ORACLE_HOME
export CLASSPATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH

# Run Java with JDAPI
exec $JAVA_HOME/bin/java -cp "$CLASSPATH" "$@"
EOF
    
    chmod +x "$wrapper_script"
    echo "✓ Created JDAPI wrapper script at $wrapper_script"
}

# Function to create sample JDAPI program
create_sample_program() {
    local sample_file="$JDAPI_DIR/JdapiTest.java"
    
    cat > "$sample_file" << 'EOF'
import oracle.forms.jdapi.*;
import java.io.File;

public class JdapiTest {
    public static void main(String[] args) {
        try {
            System.out.println("Oracle Forms JDAPI Test");
            System.out.println("======================");
            
            // Initialize JDAPI
            Jdapi.setFailSubclassLoad(false);
            Jdapi.setFailLibraryLoad(false);
            
            // Get JDAPI version
            System.out.println("JDAPI Version: " + Jdapi.getVersion());
            
            // Test creating a new form
            if (args.length > 0 && args[0].equals("create")) {
                System.out.println("\nCreating test form...");
                FormModule form = new FormModule("TEST_FORM");
                form.setTitle("Test Form created by JDAPI");
                
                // Add a canvas
                Canvas canvas = new Canvas(form, "CANVAS1");
                canvas.setViewportHeight(480);
                canvas.setViewportWidth(640);
                
                // Add a block
                Block block = new Block(form, "BLOCK1");
                block.setDatabaseBlock(false);
                
                // Save the form
                String filename = "test_jdapi.fmb";
                form.save(filename);
                System.out.println("✓ Form saved as: " + filename);
                
                // Clean up
                form.destroy();
            } else {
                System.out.println("\nTo create a test form, run with 'create' argument");
            }
            
            System.out.println("\n✓ JDAPI is working correctly!");
            
        } catch (Exception e) {
            System.err.println("✗ JDAPI Error: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}
EOF
    
    echo "✓ Created sample JDAPI program at $sample_file"
}

# Function to compile sample program
compile_sample_program() {
    local java_file="$JDAPI_DIR/JdapiTest.java"
    local class_file="$JDAPI_DIR/JdapiTest.class"
    
    echo "Compiling sample JDAPI program..."
    
    if [ -f "$java_file" ]; then
        cd "$JDAPI_DIR"
        if $JAVA_HOME/bin/javac -cp "$JDAPI_DIR/frmjdapi.jar" JdapiTest.java 2>/dev/null; then
            echo "✓ Sample program compiled successfully"
        else
            echo "⚠ Warning: Could not compile sample program"
        fi
    fi
}

# Main extraction process
echo ""
echo "1. Checking ORACLE_HOME..."
if [ ! -d "$ORACLE_HOME" ]; then
    echo "✗ ERROR: ORACLE_HOME not found at $ORACLE_HOME"
    exit 1
fi
echo "✓ ORACLE_HOME: $ORACLE_HOME"

echo ""
echo "2. Copying JDAPI files..."
copy_jdapi_files

echo ""
echo "3. Creating wrapper script..."
create_jdapi_wrapper

echo ""
echo "4. Creating sample program..."
create_sample_program

echo ""
echo "5. Compiling sample program..."
compile_sample_program

echo ""
echo "6. Setting up environment..."
# Add bin directory to PATH
echo 'export PATH=/home/oracle/bin:$PATH' >> /home/oracle/.bashrc

# Final summary
echo ""
echo "========================================"
echo "✓ JDAPI extraction and setup completed!"
echo ""
echo "JDAPI files location: $JDAPI_DIR"
echo "JDAPI wrapper script: /home/oracle/bin/jdapi"
echo "Sample program: $JDAPI_DIR/JdapiTest.java"
echo ""
echo "To test JDAPI:"
echo "  jdapi JdapiTest"
echo "  jdapi JdapiTest create"
echo ""