---
name: epics-ioc-install
description: Use this skill when the user asks to "install EPICS", "set up an IOC", "build EPICS base", "install areaDetector", "configure Mythen detector", "set up ADMythen", or mentions EPICS, IOC, areaDetector, ADMythen, or Dectris Mythen in an installation or setup context.
version: 1.0.0
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
---

# EPICS IOC Installation Skill

This skill guides installation of an EPICS 7 IOC with areaDetector and Dectris Mythen2 detector support, building all components from source into `~/epics/`.

## Installation Overview

Components to build, in order:
1. System dependencies
2. EPICS Base 7
3. Support modules: asyn, seq, busy, calc, sscan, autosave
4. areaDetector (ADSupport + ADCore)
5. ADMythen driver
6. IOC startup

## Step 1 — Assess Environment

Check architecture and existing tools before starting:

```bash
uname -m           # Should be x86_64 → EPICS_HOST_ARCH=linux-x86_64
gcc --version
make --version
perl --version
git --version
```

If any are missing, run Step 2. If all present, skip to Step 3.

## Step 2 — Install System Dependencies

Run the provided script or manually:

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  libreadline-dev \
  libncurses-dev \
  libssl-dev \
  libxml2-dev \
  libhdf5-dev \
  libtiff-dev \
  libjpeg-dev \
  re2c \
  perl \
  git \
  wget
```

See `scripts/install-deps.sh` for the full annotated script.

## Step 3 — Build EPICS Base 7

```bash
mkdir -p ~/epics
cd ~/epics
git clone --branch 7.0 https://github.com/epics-base/epics-base.git base
cd base
make
```

Build takes ~5-10 minutes. Then add to `~/.bashrc`:

```bash
export EPICS_BASE=~/epics/base
export EPICS_HOST_ARCH=linux-x86_64
export PATH=$EPICS_BASE/bin/$EPICS_HOST_ARCH:$PATH
```

Apply immediately: `source ~/.bashrc`

Verify: `caget --version` should succeed.

See `references/epics-base.md` for RELEASE file format and CONFIG_SITE options.

## Step 4 — Build Support Modules

Build these modules **in order** — each depends on the previous ones.

### 4a. asyn

```bash
cd ~/epics
git clone https://github.com/epics-modules/asyn.git
cd asyn
```

Edit `configure/RELEASE`:
```
EPICS_BASE=~/epics/base
```

```bash
make
```

### 4b. seq (SNCSEQ)

```bash
cd ~/epics
git clone https://github.com/epics-modules/sequencer.git seq
cd seq
```

Edit `configure/RELEASE`:
```
EPICS_BASE=~/epics/base
```

```bash
make
```

### 4c. busy

```bash
cd ~/epics
git clone https://github.com/epics-modules/busy.git
cd busy
```

Edit `configure/RELEASE`:
```
EPICS_BASE=~/epics/base
ASYN=~/epics/asyn
```

```bash
make
```

### 4d. calc

```bash
cd ~/epics
git clone https://github.com/epics-modules/calc.git
cd calc
```

Edit `configure/RELEASE`:
```
EPICS_BASE=~/epics/base
ASYN=~/epics/asyn
SNCSEQ=~/epics/seq
```

```bash
make
```

### 4e. sscan

```bash
cd ~/epics
git clone https://github.com/epics-modules/sscan.git
cd sscan
```

Edit `configure/RELEASE`:
```
EPICS_BASE=~/epics/base
CALC=~/epics/calc
SNCSEQ=~/epics/seq
```

```bash
make
```

### 4f. autosave

```bash
cd ~/epics
git clone https://github.com/epics-modules/autosave.git
cd autosave
```

Edit `configure/RELEASE`:
```
EPICS_BASE=~/epics/base
```

```bash
make
```

## Step 5 — Build areaDetector

areaDetector is an umbrella repo that pulls in ADSupport and ADCore.

```bash
cd ~/epics
git clone https://github.com/areaDetector/areaDetector.git
cd areaDetector
git submodule init ADSupport ADCore
git submodule update ADSupport ADCore
```

Create `configure/RELEASE.local`:
```
EPICS_BASE=~/epics/base
ASYN=~/epics/asyn
SNCSEQ=~/epics/seq
BUSY=~/epics/busy
CALC=~/epics/calc
SSCAN=~/epics/sscan
AUTOSAVE=~/epics/autosave
```

Create `configure/CONFIG_SITE.local`:
```
# Use system HDF5/TIFF/JPEG rather than bundled ADSupport versions
HDF5_EXTERNAL=YES
TIFF_EXTERNAL=YES
JPEG_EXTERNAL=YES
XML2_EXTERNAL=YES
```

Build ADSupport first, then ADCore:

```bash
cd ADSupport && make && cd ..
cd ADCore && make && cd ..
```

See `references/areadetector.md` for full RELEASE structure and common build errors.

## Step 6 — Build ADMythen Driver

The ADMythen driver communicates with the Mythen2 detector over TCP socket.

```bash
cd ~/epics
git clone https://github.com/areaDetector/ADMythen.git
cd ADMythen
```

Edit `configure/RELEASE`:
```
EPICS_BASE=~/epics/base
ASYN=~/epics/asyn
AREADETECTOR=~/epics/areaDetector
ADCORE=~/epics/areaDetector/ADCore
ADSUPPORT=~/epics/areaDetector/ADSupport
```

```bash
make
```

See `references/mythen-driver.md` for Mythen2 socket protocol details, PV naming, and hardware connection setup.

## Step 7 — Create and Start the IOC

Create the IOC directory:

```bash
mkdir -p ~/epics/iocs/mythen/iocBoot/iocMythen
cd ~/epics/iocs/mythen
```

Create `iocBoot/iocMythen/st.cmd`:
```
#!../../bin/linux-x86_64/mythen

< envPaths

epicsEnvSet("PREFIX",       "MYT:")
epicsEnvSet("PORT",         "MYTHEN")
epicsEnvSet("MYTHEN_HOST",  "192.168.1.1")   # Set to your Mythen2 IP
epicsEnvSet("MYTHEN_PORT",  "1030")           # Default Mythen2 port

cd "${TOP}"

dbLoadDatabase("dbd/mythen.dbd")
mythen_registerRecordDeviceDriver(pdbbase)

# Create Mythen2 driver (portName, hostName, port, maxBuffers, maxMemory)
MythenConfig("$(PORT)", "$(MYTHEN_HOST)", "$(MYTHEN_PORT)", 0, 0)

dbLoadRecords("$(ADMYTHEN)/db/mythen.db", "P=$(PREFIX),R=det1:,PORT=$(PORT),ADDR=0,TIMEOUT=1")
dbLoadRecords("$(ADCORE)/db/NDStdArrays.template", "P=$(PREFIX),R=image1:,PORT=Image1,ADDR=0,TIMEOUT=1,NDARRAY_PORT=$(PORT),TYPE=Int32,FTVL=LONG,NELEMENTS=1280")

iocInit()
```

Start the IOC:
```bash
cd ~/epics/iocs/mythen/iocBoot/iocMythen
chmod +x st.cmd
./st.cmd
```

## Step 8 — Verify Installation

Run the verification script or check manually:

```bash
# Check EPICS environment
echo $EPICS_BASE
echo $EPICS_HOST_ARCH
caget --version

# Test IOC PVs (with IOC running)
caget MYT:det1:Acquire
caget MYT:det1:Model
caput MYT:det1:AcquireTime 1.0
caput MYT:det1:Acquire 1
```

See `scripts/verify-install.sh` for the full automated check.

## Troubleshooting

**`make` fails in EPICS Base with readline errors**
→ Install `libreadline-dev`: `sudo apt-get install libreadline-dev`

**areaDetector configure/RELEASE module not found**
→ Ensure all module paths use absolute paths (expand `~` to `/home/<user>`)

**ADMythen build: `MythenDetector.h` not found**
→ Confirm `ADCORE` and `AREADETECTOR` point to the correct directories in configure/RELEASE

**IOC starts but no PVs respond**
→ Check `EPICS_CA_ADDR_LIST` and firewall; on WSL2 run `export EPICS_CA_AUTO_ADDR_LIST=YES`

**Mythen2 connection timeout**
→ Verify Mythen2 IP/port with `telnet <MYTHEN_HOST> 1030`; check network routing on WSL2
