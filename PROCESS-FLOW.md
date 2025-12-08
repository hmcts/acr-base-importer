# Pipeline Process Flow

## Overview

This pipeline performs two independent workflows in sequence:

1. **Stage 1**: Scan and import base images from external registries (e.g., Google Distroless)
2. **Stage 2**: Create ACR cache rules and validate cached images from source registries

Both stages run in the same pipeline but are independent operations with their own time requirements and resource pools.

---

## Stage 1: Scan and Import Base Images

**File**: `pipelines/base-image-import-stage.yml`
**Pool**: `hmcts-cftptl-agent-pool` (on-premises agents)
**Timeout**: 120 minutes (2 hours)
**Images**: 6 base images (Java 25, 21, 17 with latest and debug tags)

### Stage 1 Flow

```
┌─────────────────────────────────────────────────────────────┐
│ ScanAndImport Stage                                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ 1. Get ACR Credentials from Key Vault                      │
│    └─ Fetch: registry-public-username, password, webhook   │
│                                                             │
│ 2. Setup Trivy v0.68.1                                     │
│    └─ Install binary and update vulnerability database    │
│                                                             │
│ 3. For each of 6 base images: ─────────────────────────────┤
│    │                                                        │
│    ├─ 3a. Check Version (check_base_*)                    │
│    │      └─ Script: check-base-tag.sh                    │
│    │         • Query external registry for latest digest  │
│    │         • Compare with ACR target image              │
│    │         • Output: newTagFound (true/false)           │
│    │         • Output: baseDigest (for import)            │
│    │                                                        │
│    ├─ 3b. Scan Image (scan_base_*) [if newTagFound]      │
│    │      └─ Template: scan-image.yml                     │
│    │         • Run: trivy image <registry>/<image>:<tag>  │
│    │         • Threshold: CRITICAL,HIGH                   │
│    │         • Timeout: 10 minutes                         │
│    │         • Output: scanPassed (true if 0 CRITICAL)    │
│    │         • On scan failure: exit 1, skip next step    │
│    │                                                        │
│    └─ 3c. Import Image (import_base_*) [if scan passed]  │
│           └─ Template: import-image.yml                   │
│              • Run: az acr import (currently commented)    │
│              • Source: external registry image            │
│              • Target: hmctspublic ACR                    │
│              • Tag: <baseTag>-<digest>                    │
│                                                             │
│ 4. End of loop - next image in sequence                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Stage 1 Task Naming

```
For each image (example: distroless/java25-debian13:latest):

1. check_base_distroless_java25_debian13_latest
   ├─ outputs: newTagFound, baseDigest

2. scan_base_distroless_java25_debian13_latest
   ├─ runs if: newTagFound == 'true'
   ├─ outputs: scanPassed

3. import_base_distroless_java25_debian13_latest
   ├─ runs if: newTagFound == 'true' AND scanPassed == 'true'
   └─ (failure here means image not imported)
```

### Stage 1 Decision Logic

| Condition | Scan Runs? | Import Runs? | Outcome |
|-----------|-----------|-------------|---------|
| New tag found + clean scan | ✅ | ✅ | Image imported to ACR |
| New tag found + vulnerabilities | ✅ | ❌ | Scan fails, import skipped |
| No new tag (same as ACR) | ❌ | ❌ | Both skipped, no action |

---

## Stage 2: Create and Validate Cache Rules

**File**: `pipelines/cache-rules-stage.yml`
**Pool**: `ubuntu-latest` (hosted agents)
**Timeout**: 180 minutes (3 hours)
**Cache Rules**: 57 rules (postgresql, redis, grafana, kubernetes components, etc.)

### Stage 2 Flow

```
┌──────────────────────────────────────────────────────────────┐
│ CreateCache Stage                                            │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ 1. Get ACR Credentials from Key Vault                       │
│    └─ Fetch: registry-public-username, registry-public-pw   │
│                                                              │
│ 2. Setup Trivy v0.68.1                                      │
│    └─ Install binary and update vulnerability database     │
│                                                              │
│ 3. Scan Source Repositories (57 rules) ──────────────────────│
│    │                                                         │
│    └─ For each cache rule: ─────────────────────────────────│
│       │                                                      │
│       └─ Scan Source (scan_source_<ruleName>)              │
│          └─ Template: scan-image.yml                        │
│             • Source: docker.io/<baseImage>:latest          │
│             • (or ghcr.io/mcr.microsoft.com based on rule) │
│             • Threshold: CRITICAL,HIGH                      │
│             • Timeout: 10 minutes                           │
│             • Output: scanPassed                            │
│             • Failure: Task fails, skips to next rule       │
│                                                              │
│ 4. Create Cache Rules (57 rules) ────────────────────────────│
│    │                                                         │
│    └─ For each cache rule: ─────────────────────────────────│
│       │                                                      │
│       └─ Create Rule (create_<ruleName>) [if source scan OK] │
│          └─ AzureCLI: az acr cache create                    │
│             • Source: docker.io/<baseImage>:latest          │
│             • Destination: hmctspublic ACR                  │
│             • Name: <ruleName>                              │
│             • Cache: dockerhub                              │
│             • Runs if: scan_source_<ruleName>.scanPassed    │
│                                                              │
│ 5. Check Destination Images (57 rules) ──────────────────────│
│    │                                                         │
│    └─ For each cache rule: ─────────────────────────────────│
│       │                                                      │
│       └─ Check Dest (check_dest_<ruleName>)                │
│          └─ AzureCLI: az acr repository show                │
│             • Check if: hmctspublic/<destRepo>:latest       │
│             • Output: imageExists (true/false)              │
│             • Runs: Always (no condition)                   │
│                                                              │
│ 6. Scan Destination Images (57 rules) ───────────────────────│
│    │                                                         │
│    └─ For each cache rule: ─────────────────────────────────│
│       │                                                      │
│       └─ Scan Dest (scan_dest_<ruleName>) [if exists]      │
│          └─ Template: scan-image.yml                        │
│             • Source: hmctspublic.azurecr.io/<destRepo>     │
│             • Threshold: CRITICAL,HIGH                      │
│             • Timeout: 10 minutes                           │
│             • Output: scanPassed                            │
│             • Runs if: check_dest_<ruleName>.imageExists    │
│                                                              │
│ 7. End of loops - all rules processed                       │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Stage 2 Task Naming

```
For each cache rule (example: postgresql):

1. scan_source_postgresql
   └─ outputs: scanPassed

2. create_postgresql
   └─ runs if: scan_source_postgresql.scanPassed == 'true'

3. check_dest_postgresql
   └─ outputs: imageExists

4. scan_dest_postgresql
   └─ runs if: check_dest_postgresql.imageExists == 'true'
   └─ outputs: scanPassed
```

### Stage 2 Decision Logic

| Source Scan | Rule Created? | Dest Checked? | Dest Scanned? |
|-----------|---|---|---|
| ✅ Pass | ✅ Yes | ✅ Always | ✅ If exists |
| ❌ Fail | ❌ No | ✅ Always | Only if exists |

**Key Point**: Rule creation depends ONLY on source scan. Destination checks happen independently regardless of rule creation.

---

## Complete Pipeline Execution Order

```
Pipeline Triggered (master branch or daily schedule)
│
├─ Load 6 base images + 57 cache rules as parameters
├─ Load variables: acrName, serviceConnection, trivyVersion, etc.
│
├─ STAGE 1: ScanAndImport (120 min timeout)
│  ├─ Get ACR credentials
│  ├─ Setup Trivy
│  └─ For each of 6 images:
│     ├─ Check version → Scan (if new) → Import (if clean)
│
└─ STAGE 2: CreateCache (180 min timeout)
   ├─ Get ACR credentials
   ├─ Setup Trivy
   ├─ Scan 57 source repos
   ├─ Create rules from clean sources
   ├─ Check 57 destination images
   └─ Scan 57 destination images (if exist)
```

---

## Key Behaviors & Guarantees

### Behavior: Task Failures

When a task fails (scan finds CRITICAL vulnerability):

```yaml
# In scan-image.yml:
if [ "$CRITICAL_COUNT" -eq 0 ]; then
  echo "##vso[task.setvariable variable=scanPassed;isOutput=true]true"
else
  exit 1  # Task fails, stops execution
fi
```

**Effect**: Next task in loop is skipped automatically (no need for explicit condition).

### Behavior: Conditions are Explicit

When a condition is specified:

```yaml
condition: eq(variables['scan_source_${{ rule.ruleName }}.scanPassed'], 'true')
```

**Effect**: Task is skipped if condition is false (task doesn't fail, just skipped).

### Important: These are Different!

- **Task fails** (exit 1) → Subsequent tasks skipped UNLESS `continueOnError: true`
- **Condition false** → Task skipped, subsequent tasks continue normally
- **Both used** (scan fails + condition on next task) → Safe fallback

---

## Performance Characteristics

### Stage 1 Performance
- **Per image**: ~2-5 minutes (check + scan + import)
- **Total for 6 images**: ~12-30 minutes
- **Parallelization**: Sequential (one image at a time)

### Stage 2 Performance
- **Per rule**: ~1-3 minutes (scan source + create rule + check dest + scan dest)
- **Total for 57 rules**: ~60-180 minutes (3 hours worst case)
- **Parallelization**: Sequential (one rule at a time)

### Why Sequential?

Loop structure is `${{ each rule in parameters.cacheRulesToValidate }}:` which runs tasks sequentially within a single job. To parallelize:
- Would need separate jobs per rule (multiplies agent usage)
- Would need job templates or matrix strategy
- Current approach balances simplicity vs. throughput

---

## Debugging & Troubleshooting

### How to Find Task Output

1. **Task Name Format**:
   - Base images: `scan_base_<image>_<tag>` | `import_base_<image>_<tag>`
   - Cache rules: `scan_source_<ruleName>` | `create_<ruleName>` | `scan_dest_<ruleName>`

2. **Variable Names**:
   - Task outputs accessible via: `variables['<taskName>.<variableName>']`
   - Example: `variables['scan_source_postgresql.scanPassed']`

3. **Log Locations**:
   - Base image checks: `logs` → `ScanAndImport` → `check_base_*`
   - Cache rule scans: `logs` → `CreateCache` → `scan_source_*` / `scan_dest_*`

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "Task X skipped" | Previous task failed or condition false | Check previous task logs |
| "Image import failed" | Scan found CRITICAL vulns | Review Trivy report in scan task |
| "Cache rule not created" | Source scan failed | Check `scan_source_<ruleName>` logs |
| "Destination scan missing" | Image doesn't exist in ACR | Check `check_dest_<ruleName>` output |

---

## Configuration Points

### To Change Base Images
Edit `trivy-scan-import.yml` → `parameters.baseImagestoImport`

### To Change Cache Rules
Edit `trivy-scan-import.yml` → `parameters.cacheRulesToValidate` (source of truth: `acr-repositories.yaml`)

### To Adjust Thresholds
Edit `trivy-scan-import.yml` → `variables.severityThreshold` (default: `CRITICAL,HIGH`)

### To Change Timeouts
- Base images: `base-image-import-stage.yml` → `timeoutInMinutes: 120`
- Cache rules: `cache-rules-stage.yml` → `timeoutInMinutes: 180`
- Per-scan: `trivyTimeout` variable (default: `10m`)

---

## Template Reusability

All templates follow a consistent pattern with explicit naming:

### scan-image.yml
```yaml
parameters:
  - taskName: string  # Caller provides full task name
  - condition: string # Caller controls when task runs
  - baseRegistry, baseImage, baseTag, severityThreshold, trivyTimeout
```

### import-image.yml
```yaml
parameters:
  - taskName: string  # Caller provides full task name
  - condition: string # Caller controls when task runs
  - baseRegistry, baseImage, baseTag, targetImage, acrName, serviceConnection, baseDigest
```

This makes templates reusable in other pipelines with clear, explicit naming and no hardcoded task name prefixes.
