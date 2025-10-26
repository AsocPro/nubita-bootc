# TLS Manifests (Future Use)

This directory contains cert-manager and step-ca configurations for future TLS implementation.

## Contents

- `cert-manager/` - Certificate manager for Kubernetes
- `step-ca/` - Internal certificate authority

## Status

**NOT CURRENTLY DEPLOYED** - These manifests are preserved for future use when TLS is implemented.

See `docs/TLS.md` for implementation options and migration plan.

## To Deploy TLS (Future)

1. Review and choose a TLS solution from `docs/TLS.md`
2. Update configurations as needed for chosen solution
3. Copy manifests from this directory to parent `manifests/` directory
4. Update `Containerfile` to include TLS manifest COPY commands
5. Update service HelmCharts to enable TLS
6. Rebuild and deploy bootc image
