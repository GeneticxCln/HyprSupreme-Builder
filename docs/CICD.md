# CI/CD Documentation

This document explains the Continuous Integration and Continuous Deployment workflows for HyprSupreme-Builder.

## Continuous Integration (CI)

The CI workflow (`.github/workflows/ci.yml`) runs on every push and pull request to ensure code quality and functionality.

### Triggered On
- Push to any branch
- Pull requests to any branch

### Jobs

#### 1. Python Tests (`test-python`)
- **Environment**: Ubuntu Latest with Python 3.8, 3.9, 3.10, 3.11
- **Purpose**: Test Python modules and tools
- **Steps**:
  - Install dependencies from `requirements.txt`
  - Run pytest with coverage reporting
  - Upload coverage results to GitHub Actions artifacts

#### 2. Shell Script Tests (`test-shell`)
- **Environment**: Ubuntu Latest
- **Purpose**: Validate shell scripts and installation procedures
- **Steps**:
  - Install shellcheck for linting
  - Run shellcheck on all `.sh` files
  - Execute shell script tests in `tests/shell/`
  - Test installation script in dry-run mode

#### 3. Security Checks (`security`)
- **Environment**: Ubuntu Latest with Python 3.11
- **Purpose**: Scan for security vulnerabilities
- **Steps**:
  - Run Bandit for Python security analysis
  - Run Safety to check for vulnerable dependencies
  - Generate security reports as artifacts

### Coverage Reports
- Python test coverage is collected and stored as artifacts
- Coverage reports are available for download from the Actions tab

## Continuous Deployment (CD)

The CD workflow (`.github/workflows/cd.yml`) handles releases and deployment when version tags are pushed.

### Triggered On
- Push of version tags (format: `v*`, e.g., `v1.0.0`)
- Published releases on GitHub

### Jobs

#### 1. Create Release (`create-release`)
- **Environment**: Ubuntu Latest
- **Purpose**: Build and publish GitHub releases
- **Steps**:
  1. **Extract Version**: Parse version from Git tag
  2. **Create Archive**: 
     - Copy essential files (configs, modules, scripts, tools)
     - Exclude development files (.git, tests, .github, etc.)
     - Create compressed tarball
     - Generate SHA256 checksum
  3. **Publish Release**:
     - Upload tarball and checksum to GitHub Release
     - Auto-generate release notes with installation instructions
     - Mark as prerelease if tag contains alpha/beta/rc

#### 2. Update AUR (`update-aur`)
- **Environment**: Ubuntu Latest
- **Purpose**: Prepare for Arch User Repository updates
- **Conditions**: Only for stable releases (no alpha/beta/rc)
- **Steps**:
  - Calculate checksums for AUR PKGBUILD
  - Prepare version information
  - *Note: Full AUR integration would require additional setup*

#### 3. Notify Discord (`notify-discord`)
- **Environment**: Ubuntu Latest
- **Purpose**: Send release notifications
- **Steps**:
  - Generate release announcement
  - *Note: Requires `DISCORD_WEBHOOK_URL` secret for actual notifications*

## Release Process

### Creating a Release

1. **Prepare Release**:
   ```bash
   # Ensure all changes are committed and pushed
   git add .
   git commit -m "Prepare release v1.0.0"
   git push origin main
   ```

2. **Create and Push Tag**:
   ```bash
   # Create annotated tag
   git tag -a v1.0.0 -m "Release version 1.0.0"
   
   # Push tag to trigger CD workflow
   git push origin v1.0.0
   ```

3. **Monitor Workflow**:
   - Check GitHub Actions tab for workflow progress
   - Verify release creation and artifact uploads
   - Test download and installation of released version

### Release Versioning

- **Stable releases**: `v1.0.0`, `v1.1.0`, `v2.0.0`
- **Pre-releases**: `v1.0.0-alpha1`, `v1.0.0-beta1`, `v1.0.0-rc1`
- Pre-releases are automatically marked as such in GitHub

### Release Assets

Each release includes:
- `HyprSupreme-Builder-vX.X.X.tar.gz` - Main distribution archive
- `HyprSupreme-Builder-vX.X.X.tar.gz.sha256` - Checksum file

## Configuration

### Required Secrets

Currently, the workflows use built-in `GITHUB_TOKEN` for basic operations. Optional secrets for enhanced functionality:

- `DISCORD_WEBHOOK_URL` - For Discord release notifications
- Additional secrets may be needed for future integrations (AUR, cloud deployment, etc.)

### Customization

#### Adding New Test Types
1. Edit `.github/workflows/ci.yml`
2. Add new job or steps to existing jobs
3. Update `requirements.txt` if new Python dependencies are needed

#### Modifying Release Process
1. Edit `.github/workflows/cd.yml`
2. Customize the file copying in "Create Release Archive" step
3. Modify release notes template in "Create GitHub Release" step

#### Adding Deployment Targets
- Add new jobs to `cd.yml` for additional deployment targets
- Examples: Docker Hub, cloud platforms, package repositories

## Troubleshooting

### Common Issues

1. **Tests Failing**: Check the specific job logs in GitHub Actions
2. **Release Not Created**: Ensure tag format is correct (`v*`)
3. **Missing Files in Release**: Update the file copying section in CD workflow

### Debugging

- All workflows generate artifacts for debugging
- Test results and coverage reports are available for download
- Security scan results help identify potential issues

### Local Testing

Before pushing changes, test locally:

```bash
# Run Python tests
pytest tests/unit/ tests/integration/ --cov=tools --cov=modules

# Run shell script linting
shellcheck scripts/*.sh install.sh uninstall.sh

# Run security checks
bandit -r tools/ modules/
safety check
```

## Future Enhancements

- Integration with package managers (AUR, Homebrew, etc.)
- Automated dependency updates
- Performance benchmarking
- Cross-platform testing (macOS, different Linux distributions)
- Docker image publishing
- Documentation deployment

