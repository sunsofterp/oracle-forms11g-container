# Oracle Forms 11g Docker Image

This repository contains a Docker image for Oracle Forms 11.1.2.2.0 (11g Release 2), designed for development and testing purposes. The image provides a complete Forms development environment including the Forms compiler and JDAPI (Java API for Forms).

## Features

- **Oracle Forms 11.1.2.2.0** - Full Forms development environment
- **Forms Compiler** - Command-line compilation of Forms modules
- **JDAPI Support** - Java API for programmatic Forms manipulation
- **Minimal Base Image** - Built on OracleLinux 6-slim for Forms 11gR2 compatibility
- **Non-root User** - Runs as `oracle` user for security
- **Automated Patching** - Applies Linux patch 18178044 for JDAPI compatibility
- **CI/CD Ready** - GitHub Actions workflows for automated building and testing

## Prerequisites

### For Building the Image

1. **Docker or Podman** installed on your system
2. **Oracle Forms Installation Files**:
   - `enterprise_home.tgz` - Oracle Forms 11g installation archive
   - `jdk-7u291-linux-x64.rpm` - Oracle JDK 7 for Linux
   - Optional: `p18178044_111220_Linux-x86-64.zip` - Linux patch for JDAPI

3. **For S3 Download** (optional):
   - AWS CLI installed and configured
   - Access to S3 bucket containing the installation files

### License Requirements

**IMPORTANT**: Users must have a valid Oracle Forms license. This image is for development and testing purposes only.

## Quick Start

### Building the Image

#### Option 1: Build with S3 Download

```bash
# Set AWS credentials
export AWS_ACCESS_KEY_ID=your_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_key

# Build the image (downloads files then builds)
./build.sh --s3
```

#### Option 2: Build with Local Files

```bash
# First ensure you have the required files:
# - jdk-7u291-linux-x64.rpm
# - enterprise_home.tgz

# Build with local enterprise_home.tgz
./build.sh --file /path/to/enterprise_home.tgz
```

#### Option 3: Direct Docker Build

```bash
# If you already have all files in the current directory
docker build -t oracle-forms:11.1.2.2.0 .
```

### Running the Container

```bash
# Show help
docker run --rm oracle-forms:11.1.2.2.0

# Show environment info
docker run --rm oracle-forms:11.1.2.2.0 info

# Run Forms compiler help
docker run --rm oracle-forms:11.1.2.2.0 frmcmp.sh help=yes

# Interactive shell
docker run --rm -it oracle-forms:11.1.2.2.0 bash
```

## Usage Examples

### 1. Compiling Forms

```bash
# Compile a single form
docker run --rm -v $(pwd):/work oracle-forms:11.1.2.2.0 \
  frmcmp.sh module=/work/myform.fmb userid=scott/tiger@orcl \
  compile_all=yes output_file=/work/myform.fmx

# Batch compile multiple forms
docker run --rm -v $(pwd):/work oracle-forms:11.1.2.2.0 \
  frmcmp_batch.sh module_type=form batch=yes \
  module=/work/*.fmb userid=scott/tiger@orcl
```

### 2. Using JDAPI

```bash
# Run JDAPI test
docker run --rm oracle-forms:11.1.2.2.0 \
  jdapi JdapiTest

# Run custom JDAPI program
docker run --rm -v $(pwd):/work oracle-forms:11.1.2.2.0 \
  bash -c "cd /work && javac -cp /home/oracle/jdapi/frmjdapi.jar MyProgram.java && \
           java -cp .:/home/oracle/jdapi/frmjdapi.jar MyProgram"
```

### 3. Setting TNS Configuration

```bash
# Run with TNS configuration
docker run --rm \
  -e TNS_ENTRIES="ORCL=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=dbhost)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=orcl)))" \
  oracle-forms:11.1.2.2.0 \
  frmcmp.sh module=/work/myform.fmb userid=scott/tiger@ORCL
```

### 4. CI/CD Integration

```yaml
# Example GitHub Actions workflow
- name: Compile Forms
  run: |
    docker run --rm \
      -v ${{ github.workspace }}:/work \
      oracle-forms:11.1.2.2.0 \
      frmcmp_batch.sh module=/work/forms/*.fmb \
      compile_all=yes batch=yes
```

### 5. Development Environment

```bash
# Start development container with mounted workspace
docker run --rm -it \
  -v $(pwd):/workspace \
  -v ~/.tnsadmin:/opt/oracle/network/admin \
  -w /workspace \
  oracle-forms:11.1.2.2.0 \
  bash

# Inside container:
# - Compile forms: frmcmp.sh module=myform.fmb
# - Run JDAPI: jdapi MyJdapiProgram
# - Access Forms tools in $ORACLE_HOME/bin
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ORACLE_BASE` | Oracle base directory | `/opt/oracle` |
| `ORACLE_HOME` | Oracle home directory | `/opt/oracle/middleware` |
| `FORMS_HOME` | Forms home directory | `/opt/oracle/middleware` |
| `TNS_ADMIN` | TNS configuration directory | `/opt/oracle/network/admin` |
| `TNS_ENTRIES` | TNS entries to add to tnsnames.ora | (none) |
| `FORMS_API_TK_BYPASS` | Bypass toolkit initialization | `true` |

## Directory Structure

```
/opt/oracle/
├── middleware/          # Oracle Forms installation
│   ├── bin/            # Forms executables
│   ├── lib/            # Forms libraries
│   └── jlib/           # Java libraries
├── network/
│   └── admin/          # TNS configuration
└── /home/oracle/
    ├── jdapi/          # JDAPI files
    ├── bin/            # User scripts
    └── work/           # Working directory
```

## Testing

Run the test suites to verify the image:

```bash
# Test Forms compiler
./test/test-forms-compiler.sh

# Test JDAPI functionality
./test/test-jdapi.sh

# Run all tests
./test/test-forms-compiler.sh && ./test/test-jdapi.sh
```

## GitHub Actions Workflows

### Build Workflow

The build workflow automatically:
- Builds the Docker image
- Runs all tests
- Pushes to GitHub Container Registry (on main branch)

Trigger manually:
```bash
gh workflow run build-image.yml
```

### Test Workflow

Test any Docker image:
```bash
# Test local image
gh workflow run test-image.yml

# Test registry image
gh workflow run test-image.yml \
  -f registry=ghcr.io/yourusername \
  -f image_name=oracle-forms \
  -f image_tag=11.1.2.2.0
```

## Troubleshooting

### Common Issues

1. **Forms compiler not found**
   ```
   Error: frmcmp.sh: command not found
   ```
   Solution: Ensure the image was built with valid enterprise_home.tgz

2. **JDAPI class not found**
   ```
   Error: ClassNotFoundException: oracle.forms.jdapi.Jdapi
   ```
   Solution: Check if patch 18178044 was applied during build

3. **Cannot connect to database**
   ```
   Error: ORA-12154: TNS:could not resolve the connect identifier
   ```
   Solution: Set TNS_ENTRIES environment variable or mount tnsnames.ora

4. **Permission denied**
   ```
   Error: Permission denied when writing files
   ```
   Solution: Ensure mounted volumes have correct permissions for oracle user

### Debug Mode

Run container with debug information:
```bash
# Verbose Forms compiler output
docker run --rm oracle-forms:11.1.2.2.0 \
  bash -c "export FORMS_TRACE_PATH=/tmp && \
           export FORMS_TRACE_LEVEL=99 && \
           frmcmp.sh help=yes"

# Check installation
docker run --rm oracle-forms:11.1.2.2.0 \
  /home/oracle/scripts/verify-installation.sh
```

## Security Considerations

- Container runs as non-root user (`oracle`)
- No SSH server or remote access tools installed
- Minimal package installation
- AWS credentials used only during build, not stored in image
- Regular security scanning with Trivy in CI/CD pipeline

## License

**IMPORTANT**: This image requires a valid Oracle Forms license. The Docker image itself is provided as-is for development and testing purposes. Users are responsible for complying with Oracle's licensing terms.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `./test/test-forms-compiler.sh && ./test/test-jdapi.sh`
5. Submit a pull request

## Support

For issues and questions:
- Create an issue in this repository
- Check existing issues for solutions
- Review the troubleshooting section

## Acknowledgments

- Oracle Corporation for Oracle Forms
- The Oracle Forms development community

---

**Note**: This is not an official Oracle product. Oracle Forms is a trademark of Oracle Corporation.