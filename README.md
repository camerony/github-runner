# GitHub Actions Self-Hosted Runner - Dokploy Deployment

## Quick Start

### 1. Get Runner Registration Token

Visit: https://github.com/camerony/Affine-custom/settings/actions/runners/new

Or use GitHub API:
```bash
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer YOUR_GITHUB_TOKEN" \
  https://api.github.com/repos/camerony/Affine-custom/actions/runners/registration-token
```

Save the `token` value.

### 2. Deploy in Dokploy

1. **Open Dokploy** → Create New Application
2. **Application Type**: Docker Compose or Custom Dockerfile
3. **Upload these files**:
   - `Dockerfile`
   - `entrypoint.sh`

4. **Set Environment Variables**:
   - `RUNNER_TOKEN`: (from step 1)
   - `RUNNER_NAME`: `affine-runner-01`

5. **Configure Volumes**:
   - Mount: `/var/run/docker.sock:/var/run/docker.sock` (Docker-in-Docker)
   - Volume: `runner-work:/home/runner/_work` (Persistent workspace)

6. **Set Privileges**:
   - Enable: `Privileged mode` (required for Docker-in-Docker)

7. **Deploy**: Click Deploy

### 3. Verify Connection

Visit: https://github.com/camerony/Affine-custom/settings/actions/runners

Should see "affine-runner-01" with status "Idle" and labels: self-hosted, linux, x64, docker

### 4. Update Workflows

Edit `.github/workflows/build-images.yml` and `release.yml`:

Change:
```yaml
runs-on: ubuntu-latest
```

To:
```yaml
runs-on: [self-hosted, linux, x64]
```

### 5. Test

```bash
git tag v0.25.13-test
git push origin v0.25.13-test
```

Check GitHub Actions tab - jobs should run on your self-hosted runner.

## Credential Persistence

The runner stores permanent credentials in `/home/runner/.credentials` after initial registration.

**Container restart** (stop/start in Dokploy):
- ✅ Credentials persist
- ✅ No new token needed
- ✅ Runner reconnects automatically

**Container rebuild** (rebuild image in Dokploy):
- ❌ Credentials lost
- ⚠️ Need new registration token
- Follow steps 1-3 again with fresh token

**Best practice**: Avoid rebuilding unless updating runner software or Dockerfile changes.

## Network Requirements

**Outbound only** (no incoming ports needed):
- github.com:443
- api.github.com:443
- ghcr.io:443

The runner polls GitHub for jobs - no incoming connections required!

## Troubleshooting

**View logs in Dokploy**:
- Go to Application → Logs tab
- Look for "Runner listener started"

**Check runner status**:
```bash
# From Dokploy console/shell
ps aux | grep Runner.Listener
```

**Restart runner**:
- Dokploy UI → Restart button

## Cleanup Between Jobs

The runner reuses the workspace. To add cleanup:

1. Create `cleanup.sh`:
```bash
#!/bin/bash
find /home/runner/_work -mindepth 1 -maxdepth 1 -type d ! -name '_PipelineMapping' -exec rm -rf {} +
docker image prune -af --filter "until=72h"
docker volume prune -f
```

2. Add to Dokploy volumes: `./cleanup.sh:/home/runner/cleanup.sh:ro`

3. Run periodically via cron in container (optional)

## Maintenance

**Update runner** (quarterly):
1. Check latest version: https://github.com/actions/runner/releases
2. Update `RUNNER_VERSION` in Dockerfile
3. Rebuild and redeploy in Dokploy

**Rotate token** (annually):
1. Get new token from GitHub
2. Update `RUNNER_TOKEN` env var in Dokploy
3. Restart application

## Recent Updates

**2025-02-03**: Fixed build dependencies, Docker socket permissions, and credential persistence
- Added Node.js 22 and CorePack to Dockerfile (fixes yarn not found)
- Added build-essential, clang, llvm, pkg-config, libssl-dev (fixes Rust compilation)
- Added python3 for node-gyp native builds
- Fixed Docker socket permissions in entrypoint.sh (automatically adds runner to docker group)
- **Fixed credential persistence**: Runner only registers once, reuses credentials on restart
  - Registration token only needed for initial setup or container rebuild
  - Container restarts no longer require new token
- **Action required**: Redeploy runner in Dokploy with fresh registration token
