# Redis for Windows on MSYS2

> **Note** This project is under development.
> **Development use only** This repository and its release artifacts are intended for development and testing scenarios.

[![Build](https://github.com/taizod1024/redis-windows/actions/workflows/build-redis.yml/badge.svg)](https://github.com/taizod1024/redis-windows/actions)
[![Release](https://img.shields.io/github/v/release/taizod1024/redis-windows)](https://github.com/taizod1024/redis-windows/releases)

Compiled from [official Redis source](https://github.com/redis/redis) for Windows, and packaged to run with MSYS2 runtime.

## Origin and Modifications

- Origin: This repository is a fork of [redis-windows/redis-windows](https://github.com/redis-windows/redis-windows).
- Upstream source: Redis source code is downloaded from the official Redis repository during CI builds.
- Scope in this fork:
  - MSYS2-only build and packaging.
  - Service management support is out of scope.
  - .NET/C# wrapper components are out of scope to keep the repository focused on Redis build artifacts.
  - Only the necessary files and workflows are kept for this scope.

## Usage

For baseline usage and context, refer to [redis-windows/redis-windows](https://github.com/redis-windows/redis-windows).

Use MSYS2 POSIX paths (`/c/...`, `/d/...`) on the command line.

```cmd
redis-server.exe /c/config/redis.conf --dir /d/data --port 6379
```

## Technical Details

- Build toolchain: MSYS2
- Runtime: MSYS2
- Path handling: use MSYS2 POSIX-style paths on command line

## winget Registration

This repository includes an automated workflow for winget registration: `.github/workflows/publish-winget.yml`.

Behavior:

- Trigger: when a release is published.
- Target asset: the first release asset matching `*-msys2.zip`.
- Submission flow:
  - tries `wingetcreate update` first (for existing package IDs)
  - falls back to `wingetcreate new` when the package is not yet registered

Portable package policy:

- The submission uses the zip artifact as the package source.
- The intended user experience is that `winget install` enables immediate command use (`redis-server`).
- If winget-pkgs review requests manifest adjustments (for example command aliases), update the generated PR accordingly.

Required repository secret:

- `WINGET_GITHUB_TOKEN`: GitHub personal access token that can create PRs against `microsoft/winget-pkgs`.

Optional repository variables (workflow defaults are used when omitted):

- Package Identifier is fixed in workflow: `taizod1024.redis-windows`
- Publisher is fixed in workflow: `taizod1024`
- `WINGET_PACKAGE_NAME` (example: `Redis for Windows (MSYS2)`)
- `WINGET_PACKAGE_SHORT_DESCRIPTION`
- `WINGET_PACKAGE_LICENSE` (example: `MIT`)
- `WINGET_PACKAGE_LICENSE_URL` (example: `https://github.com/redis-windows/redis-windows/blob/main/LICENSE`)

Notes:

- Pre-releases are skipped.
- Use a stable version tag for winget publication.

## Disclaimer

This project is not affiliated with, endorsed by, or sponsored by Redis Ltd. The license provided here applies only to this repository, not to the official Redis project.

This is recommended for local development only. For production environments, please follow Redis official guidance and deploy on Linux. This project is not responsible for any losses caused by its use.
