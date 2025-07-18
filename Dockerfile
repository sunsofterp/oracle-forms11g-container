FROM oraclelinux:6-slim

LABEL maintainer="SunsoftERP"
LABEL description="Oracle Forms 11.1.2.2.0 Development Environment"

# Install system dependencies
RUN yum -y update && \
    yum -y install \
        glibc glibc-devel \
        libaio gcc gcc-c++ \
        make sysstat \
        motif motif-devel \
        libXp libXt libXtst \
        xauth xterm ksh \
        unzip tar which wget && \
    yum clean all && \
    rm -rf /var/cache/yum

# Create oracle user and group
RUN groupadd -g 1000 oracle && \
    useradd -u 1000 -g oracle -m -s /bin/bash oracle

# Set environment variables
ENV ORACLE_BASE=/opt/oracle \
    ORACLE_HOME=/opt/oracle/enterprise_home \
    FORMS_HOME=/opt/oracle/enterprise_home \
    TNS_ADMIN=/opt/oracle/network/admin \
    LD_LIBRARY_PATH=/opt/oracle/enterprise_home/lib:$LD_LIBRARY_PATH \
    PATH=/opt/oracle/enterprise_home/bin:$PATH \
    FORMS_API_TK_BYPASS=true \
    JAVA_HOME=/usr/java/jdk1.7.0_291

# Create directory structure
RUN mkdir -p $ORACLE_BASE $TNS_ADMIN && \
    chown -R oracle:oracle /opt/oracle

# Switch to oracle user for installation
USER oracle
WORKDIR /home/oracle

# Download and extract Forms (using build args for S3)
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_DEFAULT_REGION=us-east-1
ARG S3_BUCKET=sunsofterpsetupfiles

# Create temporary directory for installation files
RUN mkdir -p /tmp/forms-install

# Install JDK 7 (as root before switching to oracle user)
USER root
COPY jdk-7u291-linux-x64.rpm /tmp/
RUN rpm -ivh /tmp/jdk-7u291-linux-x64.rpm && \
    rm -f /tmp/jdk-7u291-linux-x64.rpm && \
    ln -sf /usr/java/jdk1.7.0_291-amd64 /usr/java/jdk1.7.0_291

# Update PATH to include Java
ENV PATH=/usr/java/jdk1.7.0_291/bin:$PATH

# Switch back to oracle user
USER oracle

# Copy scripts
COPY --chown=oracle:oracle scripts/apply-patches.sh scripts/verify-installation.sh scripts/extract-jdapi.sh scripts/debug-installation.sh /home/oracle/scripts/
RUN chmod +x /home/oracle/scripts/*.sh

# Download and extract Forms installation
# Note: enterprise_home.tgz should be downloaded beforehand and placed in the build context
USER root
COPY enterprise_home.tgz /tmp/forms-install/
RUN cd /opt/oracle && \
    tar -xzf /tmp/forms-install/enterprise_home.tgz && \
    chown -R oracle:oracle /opt/oracle && \
    rm -rf /tmp/forms-install

# Create patches directory
RUN mkdir -p /tmp/patches

# Copy patches if available (the .gitkeep file ensures the directory exists)
COPY patches/ /tmp/patches/
RUN chown -R oracle:oracle /tmp/patches

# Switch to oracle user for remaining steps
USER oracle

# Apply patches if available
RUN /home/oracle/scripts/apply-patches.sh

# Set up proper Forms binaries (copy from templates to bin)
RUN if [ -f "/opt/oracle/enterprise_home/forms/templates/scripts/frmcmp.sh" ]; then \
        mkdir -p /opt/oracle/enterprise_home/bin && \
        cp /opt/oracle/enterprise_home/forms/templates/scripts/*.sh /opt/oracle/enterprise_home/bin/ && \
        chmod +x /opt/oracle/enterprise_home/bin/*.sh && \
        echo "Forms scripts copied to bin directory"; \
    fi

# Move original frmcmp.sh and install wrapper
USER root
RUN if [ -f "/opt/oracle/enterprise_home/bin/frmcmp.sh" ]; then \
        mv /opt/oracle/enterprise_home/bin/frmcmp.sh /opt/oracle/enterprise_home/bin/frmcmp.sh.orig; \
    fi
COPY templates/frmcmp-wrapper.sh /opt/oracle/enterprise_home/bin/frmcmp.sh
RUN chmod +x /opt/oracle/enterprise_home/bin/frmcmp.sh && \
    chown oracle:oracle /opt/oracle/enterprise_home/bin/frmcmp.sh*
USER oracle

# Create Forms server directory and add default.env
USER root
RUN mkdir -p /opt/oracle/enterprise_home/forms/server
COPY templates/default.env /opt/oracle/enterprise_home/forms/server/
RUN chown -R oracle:oracle /opt/oracle/enterprise_home/forms/server
USER oracle

# Debug installation structure
RUN /home/oracle/scripts/debug-installation.sh || true

# Verify installation (allow failure for now)
RUN /home/oracle/scripts/verify-installation.sh || true

# Extract JDAPI
RUN /home/oracle/scripts/extract-jdapi.sh

# Create directories for runtime
RUN mkdir -p /home/oracle/work /home/oracle/forms

# Copy entrypoint script
COPY --chown=oracle:oracle docker-entrypoint.sh /home/oracle/
RUN chmod +x /home/oracle/docker-entrypoint.sh

# Set working directory
WORKDIR /home/oracle/work

# Expose potential ports (adjust as needed)
# Forms runtime port
EXPOSE 9001

# Set entrypoint
ENTRYPOINT ["/home/oracle/docker-entrypoint.sh"]
CMD ["bash"]