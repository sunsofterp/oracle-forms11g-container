#!/bin/bash

# Oracle Forms 11g Docker Entrypoint Script

# Set up environment variables
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=${ORACLE_HOME:-/opt/oracle}
export FORMS_HOME=${FORMS_HOME:-/opt/oracle}
export TNS_ADMIN=${TNS_ADMIN:-/opt/oracle/network/admin}
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export PATH=$ORACLE_HOME/bin:$PATH
export FORMS_API_TK_BYPASS=true
export JAVA_HOME=/usr/java/jdk1.7.0_291

# Create TNS_ADMIN directory if it doesn't exist
if [ ! -d "$TNS_ADMIN" ]; then
    mkdir -p "$TNS_ADMIN"
fi

# Function to display Forms environment info
show_environment() {
    echo "Oracle Forms 11g Container Environment"
    echo "======================================"
    echo "ORACLE_BASE: $ORACLE_BASE"
    echo "ORACLE_HOME: $ORACLE_HOME"
    echo "FORMS_HOME: $FORMS_HOME"
    echo "TNS_ADMIN: $TNS_ADMIN"
    echo "JAVA_HOME: $JAVA_HOME"
    echo ""
    echo "Forms Version:"
    if [ -f "$ORACLE_HOME/bin/frmcmp.sh" ]; then
        $ORACLE_HOME/bin/frmcmp.sh help=yes 2>/dev/null | head -5
    else
        echo "Forms compiler not found!"
    fi
    echo ""
}

# Function to setup TNS configuration
setup_tns() {
    if [ -n "$TNS_ENTRIES" ]; then
        echo "Setting up TNS configuration..."
        echo "$TNS_ENTRIES" > "$TNS_ADMIN/tnsnames.ora"
        echo "TNS configuration saved to $TNS_ADMIN/tnsnames.ora"
    fi
}

# Check if Forms installation exists
if [ ! -d "$ORACLE_HOME" ] || [ ! -f "$ORACLE_HOME/bin/frmcmp.sh" ]; then
    echo "ERROR: Oracle Forms installation not found at $ORACLE_HOME"
    echo "Please ensure the container was built correctly with enterprise_home.tgz"
    exit 1
fi

# Setup TNS if environment variable is provided
setup_tns

# Show environment info if requested
if [ "$1" = "info" ] || [ "$1" = "--info" ]; then
    show_environment
    exit 0
fi

# If no command provided, show help
if [ $# -eq 0 ]; then
    echo "Oracle Forms 11g Docker Container"
    echo ""
    echo "Usage:"
    echo "  docker run oracle-forms:11.1.2.2.0 [command]"
    echo ""
    echo "Commands:"
    echo "  info                    - Show environment information"
    echo "  frmcmp.sh [args]       - Run Forms compiler"
    echo "  frmcmp_batch.sh [args] - Run Forms batch compiler"
    echo "  bash                   - Start interactive shell"
    echo "  [any command]          - Execute any command"
    echo ""
    echo "Examples:"
    echo "  docker run oracle-forms:11.1.2.2.0 frmcmp.sh help=yes"
    echo "  docker run -v \$(pwd):/work oracle-forms:11.1.2.2.0 frmcmp.sh module=/work/test.fmb compile_all=yes"
    echo ""
    exit 0
fi

# Execute the provided command
exec "$@"