# EPICS Base Reference

## Environment Variables

| Variable | Example | Purpose |
|----------|---------|---------|
| `EPICS_BASE` | `/home/user/epics/base` | Path to built EPICS Base tree |
| `EPICS_HOST_ARCH` | `linux-x86_64` | Host architecture string |
| `PATH` | `$EPICS_BASE/bin/$EPICS_HOST_ARCH:$PATH` | Adds `caget`, `caput`, `camonitor`, `softIoc` |
| `EPICS_CA_AUTO_ADDR_LIST` | `YES` | Required on WSL2 for CA broadcast discovery |

Determine `EPICS_HOST_ARCH` from `uname -m`:
- `x86_64` → `linux-x86_64`
- `aarch64` → `linux-aarch64`

## Directory Structure After Build

```
~/epics/base/
├── bin/linux-x86_64/    # caget, caput, softIoc, etc.
├── lib/linux-x86_64/    # libca.so, libCom.so, etc.
├── include/             # Headers for building against EPICS
├── dbd/                 # Database definition files
└── db/                  # Built-in record type databases
```

## RELEASE File Format

Every EPICS module has `configure/RELEASE`. It maps module name → path.

```makefile
# configure/RELEASE
EPICS_BASE=/home/user/epics/base

# Reference other modules by their variable name
ASYN=/home/user/epics/asyn
SNCSEQ=/home/user/epics/seq
```

Rules:
- Use **absolute paths** — `~` is not expanded by make
- Module variable names are uppercase (match what downstream modules expect)
- Order does not matter in RELEASE itself

## CONFIG_SITE.local

Override build options without touching the base configuration:

```makefile
# configure/CONFIG_SITE.local (in EPICS Base or any module)

# Disable cross-compilation (WSL2 only builds host)
CROSS_COMPILER_TARGET_ARCHS =

# Optimize build
OPT_CFLAGS = -O2
OPT_CXXFLAGS = -O2
```

## Key Build Commands

```bash
make               # Full build
make clean         # Remove build artifacts
make distclean     # Remove all generated files
make -j$(nproc)    # Parallel build (faster, but harder to read errors)
```

Use `make` without `-j` for the first build of a module to see errors clearly.

## Useful CA Command-Line Tools

```bash
caget <PV>                     # Read a PV value
caput <PV> <value>             # Write a PV value
camonitor <PV>                 # Monitor PV changes
cainfo <PV>                    # Show PV type and connection info
softIoc -d <file.db>           # Start a software IOC from a .db file
```

## WSL2 Networking Notes

Channel Access uses UDP broadcast by default. On WSL2, the virtual network may not forward broadcasts. Fix:

```bash
export EPICS_CA_AUTO_ADDR_LIST=YES
export EPICS_CAS_INTF_ADDR_LIST=$(hostname -I | awk '{print $1}')
```

Add these to `~/.bashrc` alongside `EPICS_BASE`.
