#!/bin/bash
# Wrapper script for Forms compiler to ensure proper environment setup

# Source the default environment if it exists
if [ -f "$ORACLE_HOME/forms/server/default.env" ]; then
    . "$ORACLE_HOME/forms/server/default.env"
fi

# Ensure required environment variables are set
export ORACLE_HOME=${ORACLE_HOME:-/opt/oracle/enterprise_home}
export FORMS_HOME=${FORMS_HOME:-$ORACLE_HOME}
export TNS_ADMIN=${TNS_ADMIN:-/opt/oracle/network/admin}
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export FORMS_API_TK_BYPASS=true
export FORMS_PATH=${FORMS_PATH:-$ORACLE_HOME/forms:$ORACLE_HOME/forms/common}
export FORMS_BUILDER_CLASSPATH=$ORACLE_HOME/jlib/frmjdapi.jar:$ORACLE_HOME/forms/java/frmall.jar

# Set terminal type for Forms
export TERM=${TERM:-vt220}

# Execute the actual Forms compiler
exec $ORACLE_HOME/bin/frmcmp.sh.orig "$@"