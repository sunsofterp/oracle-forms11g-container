# Oracle Forms 11g Test Suite

This directory contains test scripts and sample files for validating the Oracle Forms 11g Docker image.

## Test Scripts

### test-forms-compiler.sh
Tests the Oracle Forms compiler functionality:
- Compiler availability and version
- Environment variables
- Library dependencies
- Basic compilation tests
- File permissions

### test-jdapi.sh
Tests the Oracle Forms JDAPI (Java API):
- JDAPI JAR file availability
- Java classpath configuration
- Sample program compilation and execution
- JDAPI operations
- Form creation via JDAPI

## Sample Files

### sample_form.xml
A sample Oracle Forms definition in XML format for reference. Note that actual Oracle Forms files use a binary format (.fmb), not XML. This file serves as documentation of a typical form structure.

## Running Tests

### Local Testing
```bash
# Run Forms compiler tests
./test-forms-compiler.sh

# Run JDAPI tests
./test-jdapi.sh

# Test specific image
./test-forms-compiler.sh --image oracle-forms --tag 11.1.2.2.0
```

### GitHub Actions
Tests are automatically run via GitHub Actions when:
- Code is pushed to main/master branches
- Pull requests are created
- Manually triggered via workflow dispatch
- Weekly on Sundays (scheduled)

## Creating Test Forms

To create actual Oracle Forms files for testing:

1. Use Oracle Forms Builder (requires Windows with Forms installation)
2. Use JDAPI to programmatically create forms
3. Convert existing forms using Forms migration tools

## Test Requirements

- Docker or Podman installed
- Oracle Forms Docker image built
- Bash shell
- Basic Unix tools (grep, awk, etc.)

## Adding New Tests

To add new tests:
1. Create test functions in the appropriate script
2. Follow the existing naming convention (test_*)
3. Use the run_test helper function for consistent output
4. Update the main() function to include your test
5. Document the test purpose and expected results