# Oracle Forms 11g Docker Image Build Plan

## Overview

This document outlines the plan to create a Docker image for Oracle Forms 11.1.2.2.0 (11g Release 2) in a dedicated repository. This image will be used for testing the Oracle Forms Gradle Plugin and other Forms development needs.

## Repository Structure

```
oracle-forms-11g-docker/
├── README.md
├── Dockerfile
├── docker-entrypoint.sh
├── scripts/
│   ├── apply-patches.sh
│   ├── verify-installation.sh
│   └── extract-jdapi.sh
├── test/
│   ├── test-forms-compiler.sh
│   ├── test-jdapi.sh
│   └── sample.fmb
├── .github/
│   └── workflows/
│       ├── build-image.yml
│       └── test-image.yml
└── build.sh
```

## Image Specifications

### Base Image
- **OS**: OracleLinux 6-slim
- **Rationale**: Compatibility with Forms 11g Release 2 requirements (11.1.2.2.0 requires Oracle Linux 6)

### Oracle Forms Version
- **Version**: 11.1.2.2.0
- **Source**: `enterprise_home.tgz` from S3 bucket
- **Size**: ~1.2GB compressed

### Required Components
1. System packages for Forms runtime
2. Oracle Forms installation from enterprise_home.tgz
3. Linux patch 18178044 (if available)
4. Environment configuration
5. JDAPI jar for programmatic access

## Build Process

### 1. Dockerfile Structure

```dockerfile
FROM oraclelinux:6-slim

# Install system dependencies
RUN yum -y update && \
    yum -y install \
        glibc glibc-devel \
        libaio gcc gcc-c++ \
        make sysstat \
        motif motif-devel \
        libXp libXt libXtst \
        xauth xterm ksh \
        unzip tar which wget

# Create oracle user
RUN groupadd -g 1000 oracle && \
    useradd -u 1000 -g oracle -m -s /bin/bash oracle

# Set environment variables
ENV ORACLE_BASE=/opt/oracle \
    ORACLE_HOME=/opt/oracle/middleware \
    FORMS_HOME=/opt/oracle/middleware \
    TNS_ADMIN=/opt/oracle/network/admin \
    LD_LIBRARY_PATH=/opt/oracle/middleware/lib:$LD_LIBRARY_PATH \
    PATH=/opt/oracle/middleware/bin:$PATH \
    FORMS_API_TK_BYPASS=true

# Download and extract Forms (using build args for S3)
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG S3_BUCKET=sunsofterpsetupfiles

# Extract Forms installation
# Apply patches if available
# Verify installation
# Set up entrypoint
```

### 2. Build Script

The `build.sh` script will:
- Check for AWS credentials
- Verify S3 access
- Build image with proper build args
- Tag image appropriately
- Run basic validation tests

### 3. Entry Point

The `docker-entrypoint.sh` will:
- Set up environment variables
- Verify Forms installation
- Configure TNS if needed
- Execute passed commands

## S3 Integration

### Required Files
1. `enterprise_home.tgz` - Main Forms installation
2. `p18178044_111220_Linux-x86-64.zip` - Linux patch (optional)

### Access Method
- Use AWS CLI during build
- Pass credentials as build args (not stored in image)
- Alternative: Pre-download and COPY from local

## Testing

### 1. Compiler Test
```bash
docker run --rm oracle-forms:11.1.2.2.0 \
  frmcmp.sh help=yes
```

### 2. JDAPI Test
```bash
docker run --rm oracle-forms:11.1.2.2.0 \
  java -cp $ORACLE_HOME/jlib/frmjdapi.jar oracle.forms.jdapi.Jdapi
```

### 3. Form Compilation Test
```bash
docker run --rm -v $(pwd):/work oracle-forms:11.1.2.2.0 \
  frmcmp.sh module=/work/test.fmb compile_all=yes
```

## CI/CD Pipeline

### GitHub Actions Workflow

1. **Build Workflow** (`build-image.yml`):
   - Triggered on push to main
   - Build image
   - Run tests
   - Push to registry (optional)

2. **Test Workflow** (`test-image.yml`):
   - Test compiler functionality
   - Test JDAPI availability
   - Validate environment setup
   - Check patch application

## Image Distribution

### Option 1: Docker Hub
- Repository: `sunsofterp/oracle-forms`
- Tag: `11.1.2.2.0`
- Requires Docker Hub account

### Option 2: GitHub Container Registry
- Repository: `ghcr.io/sunsofterp/oracle-forms`
- Tag: `11.1.2.2.0`
- Integrated with GitHub

### Option 3: Private Registry
- For internal use only
- Custom registry URL

## Security Considerations

1. **Build-time secrets**:
   - AWS credentials only during build
   - Not stored in final image
   - Use --secret mount if available

2. **Runtime security**:
   - Run as non-root user (oracle)
   - Minimal installed packages
   - No SSH or remote access

3. **License compliance**:
   - Document Oracle license requirements
   - Private image only
   - Users must have valid Forms license

## Maintenance

1. **Update schedule**:
   - Monthly base OS updates
   - Oracle patch updates as released
   - Security fixes as needed

2. **Version tagging**:
   - `11.1.2.2.0` - Specific version
   - `11.1.2` - Minor version
   - `11g` - Major version
   - `latest` - Most recent 11g

3. **Deprecation**:
   - Follow Oracle support lifecycle
   - Provide migration path to newer versions

## Documentation

### README Contents
1. Quick start guide
2. Build instructions
3. Usage examples
4. Troubleshooting
5. License information

### Usage Examples
1. Compiling forms
2. Running JDAPI programs
3. Batch processing
4. CI/CD integration

## Success Criteria

1. Image builds successfully
2. Forms compiler works
3. JDAPI accessible
4. Size < 2GB
5. Build time < 10 minutes
6. All tests pass

## Notes for Implementation

1. The `enterprise_home.tgz` contains a pre-installed Forms directory
2. The JDAPI jar is located at `enterprise_home/jlib/frmjdapi.jar`
3. Patch 18178044 fixes JDAPI issues on Linux
4. The TNS_ADMIN setup is optional but recommended
5. X11 libraries are needed even for command-line compilation