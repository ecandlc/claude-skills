# Dectris Mythen2 Driver Reference

## Hardware Overview

The Dectris Mythen2 is a 1D silicon microstrip detector used at synchrotron beamlines for powder diffraction and X-ray scattering. It communicates over TCP/IP using a text-based socket protocol.

- Default port: **1030**
- Protocol: plain TCP, ASCII commands terminated by `\n`
- Data format: binary array of 32-bit integers (1280 channels per module)

## ADMythen Driver

The ADMythen EPICS driver wraps the Mythen2 socket protocol as an areaDetector driver.

- Source: https://github.com/areaDetector/ADMythen
- Driver class: `MythenDetector` (C++)
- Inherits from: `ADDriver` (ADCore)

## configure/RELEASE for ADMythen

```makefile
EPICS_BASE=/home/user/epics/base
ASYN=/home/user/epics/asyn
AREADETECTOR=/home/user/epics/areaDetector
ADCORE=$(AREADETECTOR)/ADCore
ADSUPPORT=$(AREADETECTOR)/ADSupport
```

## IOC Configuration

### MythenConfig call in st.cmd

```
MythenConfig(portName, hostName, portNumber, maxBuffers, maxMemory)
```

| Argument | Description |
|----------|-------------|
| `portName` | asyn port name (e.g. `"MYTHEN"`) |
| `hostName` | Mythen2 IP address or hostname |
| `portNumber` | TCP port (default `1030`) |
| `maxBuffers` | Max NDArray buffers (`0` = unlimited) |
| `maxMemory` | Max memory bytes (`0` = unlimited) |

Example:
```
MythenConfig("MYTHEN", "192.168.1.100", "1030", 0, 0)
```

### Database Loading

```
dbLoadRecords("$(ADMYTHEN)/db/mythen.db",
    "P=MYT:,R=det1:,PORT=MYTHEN,ADDR=0,TIMEOUT=1")
```

## Key PVs

| PV Suffix | Type | Description |
|-----------|------|-------------|
| `Acquire` | bo | 1=start, 0=stop acquisition |
| `AcquireTime` | ao | Integration time in seconds |
| `NumImages` | longout | Number of frames |
| `ImageMode` | mbbo | Single/Multiple/Continuous |
| `DetectorState_RBV` | mbbi | Idle/Acquire/Readout/Error |
| `Model_RBV` | stringin | Detector model string |
| `Temperature_RBV` | ai | Detector temperature (°C) |
| `Threshold` | ao | Energy threshold in keV |
| `NumModules_RBV` | longin | Number of installed modules |

Full PV prefix example: `MYT:det1:Acquire`

## Mythen2 Socket Protocol

The driver sends ASCII commands over TCP. Useful for debugging:

```bash
# Test connectivity
telnet <MYTHEN_IP> 1030

# Inside telnet session:
-get version      # Get firmware version
-get nmodules     # Get number of modules
-get temperature  # Get detector temperature
-set time 1.0     # Set integration time to 1 second
-start            # Trigger acquisition
-readout          # Read data from detector
```

## Network Setup on WSL2

WSL2 uses a NAT network. If the Mythen2 is on a physical network:

1. Ensure the Windows host can ping the Mythen2 IP
2. WSL2 can reach the Windows host via `$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')`
3. If on same subnet, configure WSL2 networking: Windows Settings → Network → Ethernet → Bridged (may require WSL2 `.wslconfig` changes)

For direct USB-Ethernet adapter to Mythen2, assign a static IP on that adapter and use it in `MythenConfig`.

## Troubleshooting

**IOC connects but no data**
→ Run `-readout` manually via telnet to confirm detector returns data
→ Check `MYT:det1:DetectorState_RBV` — should transition from Idle → Acquire → Readout → Idle

**`Connection refused` on port 1030**
→ Mythen2 control software must be running on the detector controller PC
→ Check detector is powered and the PC is running the Mythen server software

**All channels read zero**
→ Energy threshold may be set too high — try lowering with `caput MYT:det1:Threshold 8.0` (8 keV)

**Detector returns `ERROR` on commands**
→ Another client may be connected — Mythen2 allows only one TCP connection at a time
