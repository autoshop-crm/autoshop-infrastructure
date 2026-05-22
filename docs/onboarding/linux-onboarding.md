# Linux Onboarding

Canonical local onboarding entrypoint:

```bash
./scripts/onboarding/onboard-local.sh
```

Optional GUI launcher:

- `autoshop-onboard.desktop`
- `run-onboarding.sh`

Supported v1 auto-install target:

- Ubuntu
- Debian

The onboarding flow:

1. runs Linux preflight checks;
2. installs base CLI dependencies when possible;
3. installs Docker Engine and Docker Compose plugin for Ubuntu/Debian;
4. clones sibling repositories next to `autoshop-infrastructure`;
5. prepares local env files;
6. starts the full stack;
7. verifies health, web pages, and bootstrap admin login.
