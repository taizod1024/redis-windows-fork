# Redis for Windows (Fork)

[![Build](https://github.com/taizod1024/redis-windows-fork/actions/workflows/check-and-build-daily.yml/badge.svg)](https://github.com/taizod1024/redis-windows-fork/actions/workflows/check-and-build-daily.yml)
[![Release](https://img.shields.io/github/v/release/taizod1024/redis-windows-fork)](https://github.com/taizod1024/redis-windows-fork/releases)

Forked from [redis-windows/redis-windows](https://github.com/redis-windows/redis-windows).

## Scope in this fork

- Build and packaging from the [official Redis source](https://github.com/redis/redis) are limited to [MSYS2](https://www.msys2.org/).
- Redis and MSYS2 license and redistribution notices are bundled in release artifacts.
- Service management support is out of scope.
- .NET/C# wrapper components are out of scope to keep the repository focused on Redis build artifacts.
- Only the necessary files and workflows are kept for this scope.

## Usage

For baseline usage and context, refer to [redis-windows/redis-windows](https://github.com/redis-windows/redis-windows).

Use MSYS2 POSIX paths (`/c/...`, `/d/...`) on the command line.

```cmd
redis-server.exe /c/config/redis.conf --dir /d/data --port 6379
```

### Install with winget

The ZIP contents are extracted directly into the selected directory. winget adds that directory to the PATH for the selected scope so the bundled MSYS2 runtime DLLs are found.

For all users, install to a fixed machine-wide directory:

```powershell
winget install --id taizod1024.redis-windows-fork --exact --scope machine --location "C:\Program Files\Redis for Windows"
```

Use the same location when upgrading:

```powershell
winget upgrade --id taizod1024.redis-windows-fork --exact --scope machine --location "C:\Program Files\Redis for Windows"
```

For the current user only, install without administrator privileges:

```powershell
winget install --id taizod1024.redis-windows-fork --exact --scope user --location "$env:LOCALAPPDATA\Programs\Redis for Windows"
```

Use the same location when upgrading:

```powershell
winget upgrade --id taizod1024.redis-windows-fork --exact --scope user --location "$env:LOCALAPPDATA\Programs\Redis for Windows"
```

Passing the same `--location` during upgrades keeps the installation path unchanged across Redis versions. If `--location` is omitted, winget uses its default package directory for the selected scope.

These commands require the updated winget manifest and ZIP layout to be published. Existing installations must be uninstalled and reinstalled once to move to this location.

## Technical Details

- Build toolchain: MSYS2
- Runtime: MSYS2
- Path handling: use MSYS2 POSIX-style paths on command line

## Licensing and Redistribution Notices

Release artifacts include license and redistribution notice files for Redis and bundled runtime dependencies.

- Redis notices are included under `LICENCES/redis/`.
- MSYS2 runtime notices are included under `LICENCES/msys2-runtime/`.
- OpenSSL notices are included under `LICENCES/libopenssl/`.
- GCC runtime notices are included under `LICENCES/gcc-libs/`.

When redistributing release artifacts from this repository, keep these notice files together with the binaries.

## Acknowledgements

Thanks to the following projects and communities:

- [redis-windows/redis-windows](https://github.com/redis-windows/redis-windows) for the original Windows porting and packaging work.
- [redis/redis](https://github.com/redis/redis) for the upstream Redis source code.
- [MSYS2](https://www.msys2.org/) for the toolchain and runtime used in this fork.

## Disclaimer

This project is not affiliated with, endorsed by, or sponsored by Redis Ltd.

The license and notice files bundled in this repository and its release artifacts are provided to satisfy redistribution requirements for included components (such as Redis and bundled runtime libraries). They do not change or replace the licensing terms of the official upstream projects.

This project is intended for local development only. For production environments, please follow official Redis guidance and deploy on Linux. This project is not responsible for any damages caused by its use.
