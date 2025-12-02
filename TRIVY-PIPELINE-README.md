# Trivy-Based Container Image Scanning and Import Pipeline

This pipeline uses [Trivy](https://trivy.dev/) to scan container images for vulnerabilities before importing them to Azure Container Registry (ACR).

## Overview

The pipeline performs the following operations:

1. **Check for Updates**: Determines if a new image digest is available from the source registry
2. **Scan with Trivy**: Scans the image directly from the remote registry (without pulling locally) for security vulnerabilities
3. **Analyze Results**: Parses scan results and determines if the image meets security requirements
4. **Conditional Import**: Only imports images that pass the security scan (no critical vulnerabilities)
5. **Notification**: Sends detailed scan results to Slack
6. **Artifact Publishing**: Publishes scan reports as pipeline artifacts for audit trail

## Key Features

### Efficient Scanning
- **Remote Scanning**: Trivy scans images directly from the source registry without pulling them to the build agent
- **Parallel Execution**: Uses Azure DevOps matrix strategy to scan multiple images concurrently (max 5 parallel jobs)
- **Caching**: Trivy uses vulnerability database caching to speed up subsequent scans

### Security Controls
- **Severity Thresholds**: Configurable severity levels (CRITICAL, HIGH, MEDIUM, LOW)
- **Gate Control**: Prevents import of images with critical vulnerabilities
- **Unfixed Vulnerabilities**: Option to ignore vulnerabilities without available fixes
- **Audit Trail**: All scan results are published as pipeline artifacts

### Integration
- **Azure Key Vault**: Securely retrieves credentials and webhook URLs
- **Slack Notifications**: Rich formatted notifications with vulnerability details
- **ACR Integration**: Seamless import with proper tagging strategy

## Configuration

### Pipeline Variables

```yaml
variables:
  acrName: hmctspublic                    # Target ACR name
  targetRegistry: hmctspublic.azurecr.io  # Target ACR FQDN
  trivyVersion: '0.58.1'                  # Trivy version (pin for consistency)
  severityThreshold: 'CRITICAL,HIGH'      # Severities that fail the scan
  ignoredSeverities: 'LOW,MEDIUM'         # Severities to ignore
  trivyFormat: 'table'                    # Output format (table, json, sarif)
  trivyTimeout: '10m'                     # Scan timeout
```

### Image Matrix

The pipeline scans multiple Java base images in parallel:

```yaml
matrix:
  openjdk-25-distroless:
    baseImage: distroless/java25-debian13
    baseRegistry: gcr.io
    baseTag: latest
    targetImage: imported/distroless/java25
  # ... additional images
```

### Severity Levels

Trivy categorizes vulnerabilities into four severity levels:

- **CRITICAL**: Requires immediate action, blocks import
- **HIGH**: Serious vulnerabilities, currently blocks import
- **MEDIUM**: Moderate risk, logged but allows import
- **LOW**: Minor issues, logged but allows import

## How It Works

### 1. Check for New Versions

Uses the existing `check-base-tag.sh` script to:
- Query the source registry for the current image digest
- Compare with the digest in the target ACR
- Set `newTagFound` variable if update is available

### 2. Trivy Scanning

```bash
trivy image \
  --severity CRITICAL,HIGH \
  --format table \
  --timeout 10m \
  --ignore-unfixed \
  --scanners vuln \
  gcr.io/distroless/java21-debian12:latest
```

Key Trivy flags:
- `--severity`: Only report specified severity levels
- `--ignore-unfixed`: Skip vulnerabilities without patches
- `--scanners vuln`: Only run vulnerability scanner (not secrets, config, etc.)
- `--format`: Output format (table for human-readable, json for parsing)

### 3. Result Analysis

Parses the JSON report to count vulnerabilities by severity:

```bash
CRITICAL_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' trivy-report.json)
```

Sets pipeline variables:
- `criticalCount`: Number of critical vulnerabilities
- `highCount`: Number of high severity vulnerabilities
- `scanPassed`: Boolean indicating if scan passed (no critical vulns)

### 4. Conditional Import

Only proceeds with import if `scanPassed == true`:

```yaml
condition: and(eq(variables['newTagFound'], 'true'), eq(variables['scanPassed'], 'true'))
```

### 5. Notification

Sends a rich Slack message with:
- Image name and tag
- Vulnerability counts by severity
- Pass/fail status
- Link to build results
- Color-coded (green for pass, red for fail)

## Advantages Over NeuVector

### Trivy Benefits

1. **Open Source**: Free and community-driven
2. **No Infrastructure**: No need to maintain NeuVector controllers
3. **Faster Scans**: Direct registry scanning without image pulls
4. **Better Integration**: Native support for CI/CD pipelines
5. **Comprehensive Database**: Uses multiple vulnerability databases (NVD, GHSA, etc.)
6. **Regular Updates**: Frequent vulnerability database updates
7. **Industry Standard**: Widely adopted in DevSecOps workflows

### Performance Comparison

| Aspect | NeuVector | Trivy |
|--------|-----------|-------|
| Scan Speed | Slower (requires pull) | Faster (remote scan) |
| Infrastructure | Requires controller | Standalone CLI |
| Database Updates | Manual | Automatic |
| CI/CD Integration | Custom API calls | Native support |
| Cost | License required | Free |

## Usage

### Running the Pipeline

The pipeline runs automatically:
- **Daily**: Scheduled scan at 1 AM UTC
- **On Push**: Triggered by commits to master branch

### Manual Trigger

1. Go to Azure DevOps Pipelines
2. Select "Trivy Scan and ACR Import"
3. Click "Run pipeline"
4. Select branch (master)
5. Click "Run"

### Viewing Scan Results

1. **In Pipeline**: View the "Scan image with Trivy" step output
2. **Artifacts**: Download `trivy-scan-<image>-<tag>` artifact
3. **Slack**: Check #acr-tasks-monitoring channel

## Customization

### Adjusting Security Thresholds

To allow images with critical vulnerabilities (not recommended):

```yaml
severityThreshold: 'HIGH'  # Only block on HIGH (exclude CRITICAL)
```

To be more strict:

```yaml
severityThreshold: 'CRITICAL,HIGH,MEDIUM'  # Block on MEDIUM and above
```

### Changing Scan Scope

Include additional scanners:

```bash
trivy image \
  --scanners vuln,secret,config \  # Also scan for secrets and misconfigurations
  $IMAGE_TO_SCAN
```

### Output Formats

Trivy supports multiple output formats:

- `table`: Human-readable table (default)
- `json`: Machine-parseable JSON
- `sarif`: SARIF format for GitHub/Azure DevOps integration
- `cyclonedx`: CycloneDX SBOM format
- `spdx`: SPDX SBOM format

## Troubleshooting

### Scan Failures

**Error**: "Trivy database update failed"

```bash
# Solution: Increase timeout or use manual database update
trivyTimeout: '15m'
```

**Error**: "Unable to connect to registry"

```bash
# Solution: Check registry credentials in Key Vault
# Ensure registry-public-username and registry-public-password are set
```

### False Positives

If Trivy reports vulnerabilities that are not applicable:

1. **Use .trivyignore file**:
   ```
   # Ignore specific CVEs
   CVE-2023-12345
   CVE-2023-67890
   ```

2. **Filter by package**:
   ```bash
   trivy image --ignore-policy policy.rego $IMAGE
   ```

### Performance Issues

If scans are too slow:

1. **Enable cache**:
   ```bash
   export TRIVY_CACHE_DIR=/path/to/cache
   ```

2. **Use local database**:
   ```bash
   trivy image --offline-scan $IMAGE
   ```

3. **Reduce parallel jobs**:
   ```yaml
   maxParallel: 3  # Reduce from 5 to 3
   ```

## Migration from NeuVector

To migrate from the NeuVector-based pipeline:

1. **Backup current pipeline**: Keep `base-image-import.yml` as reference
2. **Update pipeline reference**: Point to `trivy-scan-import.yml`
3. **Remove NeuVector secrets**: Clean up Key Vault if NeuVector not used elsewhere
4. **Update Slack channel**: Inform team about new scanner
5. **Test thoroughly**: Run manual pipeline for all images

## Security Best Practices

1. **Pin Trivy Version**: Always specify exact version for reproducibility
2. **Regular Updates**: Update Trivy version monthly for latest features
3. **Database Freshness**: Trivy auto-updates database, but monitor for failures
4. **Audit Logs**: Retain scan artifacts for compliance (90 days recommended)
5. **False Positive Management**: Document and track ignored CVEs
6. **Severity Escalation**: Review and adjust severity thresholds quarterly

## Additional Resources

- [Trivy Documentation](https://trivy.dev/)
- [Trivy GitHub](https://github.com/aquasecurity/trivy)
- [Azure DevOps Trivy Task](https://github.com/aquasecurity/trivy-azure-pipelines-task)
- [Vulnerability Databases](https://trivy.dev/docs/latest/guide/configuration/db/)
- [Private Registry Authentication](https://trivy.dev/docs/latest/guide/advanced/private-registries/)

## Contributing

When modifying this pipeline:

1. Test changes in a separate branch
2. Run manual pipeline execution
3. Verify all matrix jobs succeed
4. Check Slack notifications format
5. Review scan artifacts
6. Update this README with changes

## License

This pipeline is part of the HMCTS infrastructure automation.
