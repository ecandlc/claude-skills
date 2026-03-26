# areaDetector Reference

## Module Dependency Tree

Build in this order — each module requires those above it:

```
EPICS Base 7
└── asyn          (async driver support)
└── seq           (state notation language, SNCSEQ)
    └── busy      (busy record)
    └── calc      (calculation records)
        └── sscan (scanning records)
        └── autosave (settings persistence)
            └── ADSupport   (bundled external libraries)
            └── ADCore      (areaDetector core)
                └── ADMythen  (Mythen driver)
```

## RELEASE File for areaDetector

`~/epics/areaDetector/configure/RELEASE` — defines all support module paths:

```makefile
EPICS_BASE=/home/user/epics/base
ASYN=/home/user/epics/asyn
SNCSEQ=/home/user/epics/seq
BUSY=/home/user/epics/busy
CALC=/home/user/epics/calc
SSCAN=/home/user/epics/sscan
AUTOSAVE=/home/user/epics/autosave
AREADETECTOR=/home/user/epics/areaDetector
ADSUPPORT=$(AREADETECTOR)/ADSupport
ADCORE=$(AREADETECTOR)/ADCore
```

## CONFIG_SITE.local for areaDetector

Using system-installed HDF5/TIFF/JPEG (recommended over bundled ADSupport):

```makefile
# ~/epics/areaDetector/configure/CONFIG_SITE.local
HDF5_EXTERNAL=YES
HDF5_LIB=/usr/lib/x86_64-linux-gnu/hdf5/serial
HDF5_INCLUDE=/usr/include/hdf5/serial

TIFF_EXTERNAL=YES
JPEG_EXTERNAL=YES
XML2_EXTERNAL=YES

# Disable unused plugins to speed build
WITH_BLOSC=NO
WITH_BITSHUFFLE=NO
WITH_KAFKA=NO
WITH_PYTHON=NO
```

## Build Order Within areaDetector

```bash
cd ~/epics/areaDetector
# ADSupport must build before ADCore
cd ADSupport && make && cd ..
cd ADCore   && make && cd ..
# Now build detector drivers
cd ADMythen && make && cd ..
```

## ADCore Plugin Architecture

ADCore provides a plugin chain. Each plugin is an asyn port:

```
Detector Driver (Mythen)
    → NDArray callbacks
        → NDPluginStdArrays  (exposes data to CA)
        → NDPluginStats      (compute statistics)
        → NDFileHDF5         (save to HDF5)
        → NDPluginROI        (region of interest)
```

Load plugins in `st.cmd` via:
```
$(ADCORE)/iocBoot/commonPlugins/commonPlugins.cmd
```

## Common Build Errors

**`asyn/devGpib/devGpib.h: No such file`**
→ ASYN path in RELEASE is wrong or asyn was not fully built.

**`hdf5.h: No such file or directory`**
→ Install `libhdf5-dev`: `sudo apt-get install libhdf5-dev`
→ Or set `HDF5_EXTERNAL=NO` in CONFIG_SITE.local to use bundled version.

**`undefined reference to XML2`**
→ Install `libxml2-dev`: `sudo apt-get install libxml2-dev`

**Submodule directories empty after clone**
→ Run: `git submodule update --init ADSupport ADCore`

## Key ADCore Record Types

| Record | Purpose |
|--------|---------|
| `$(P)$(R)Acquire` | Start/stop acquisition |
| `$(P)$(R)AcquireTime` | Exposure time in seconds |
| `$(P)$(R)NumImages` | Number of images to acquire |
| `$(P)$(R)ImageMode` | Single / Multiple / Continuous |
| `$(P)$(R)DetectorState_RBV` | Current detector state |
| `$(P)$(R)ArrayData` | Raw array data (via NDStdArrays) |
