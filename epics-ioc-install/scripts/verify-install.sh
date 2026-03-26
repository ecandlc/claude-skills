#!/usr/bin/env bash
# verify-install.sh — Verify EPICS IOC installation (EPICS Base + areaDetector + Mythen2)
# Usage: bash verify-install.sh [PREFIX]
# PREFIX defaults to "MYT:" — set to match your IOC's PV prefix

set -euo pipefail

PREFIX="${1:-MYT:}"
PASS=0
FAIL=0

check() {
    local label="$1"
    local result="$2"
    if [ "$result" = "ok" ]; then
        echo "  [OK]   $label"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $label — $result"
        FAIL=$((FAIL + 1))
    fi
}

echo "============================================"
echo " EPICS IOC Installation Verification"
echo "============================================"
echo ""

# --- Environment checks ---
echo "-- Environment --"

if [ -n "${EPICS_BASE:-}" ] && [ -d "$EPICS_BASE" ]; then
    check "EPICS_BASE set and exists ($EPICS_BASE)" "ok"
else
    check "EPICS_BASE" "not set or directory missing (export EPICS_BASE=~/epics/base)"
fi

if [ -n "${EPICS_HOST_ARCH:-}" ]; then
    check "EPICS_HOST_ARCH set ($EPICS_HOST_ARCH)" "ok"
else
    check "EPICS_HOST_ARCH" "not set (export EPICS_HOST_ARCH=linux-x86_64)"
fi

# --- Tool checks ---
echo ""
echo "-- EPICS Tools --"

for tool in caget caput camonitor softIoc; do
    if command -v "$tool" &>/dev/null; then
        check "$tool in PATH" "ok"
    else
        check "$tool in PATH" "not found — check PATH includes \$EPICS_BASE/bin/\$EPICS_HOST_ARCH"
    fi
done

# --- Library checks ---
echo ""
echo "-- Shared Libraries --"

for lib in libca.so libCom.so; do
    if find "${EPICS_BASE:-/nonexistent}/lib" -name "$lib" 2>/dev/null | grep -q .; then
        check "$lib built" "ok"
    else
        check "$lib built" "not found under \$EPICS_BASE/lib"
    fi
done

# --- areaDetector checks ---
echo ""
echo "-- areaDetector --"

ADCORE="${ADCORE:-~/epics/areaDetector/ADCore}"
ADCORE_EXPANDED="${ADCORE/\~/$HOME}"

if [ -d "$ADCORE_EXPANDED/lib" ]; then
    check "ADCore built (lib directory exists)" "ok"
else
    check "ADCore built" "lib directory not found at $ADCORE_EXPANDED/lib"
fi

ADMYTHEN="${ADMYTHEN:-~/epics/areaDetector/ADMythen}"
ADMYTHEN_EXPANDED="${ADMYTHEN/\~/$HOME}"

if [ -d "$ADMYTHEN_EXPANDED/lib" ]; then
    check "ADMythen built (lib directory exists)" "ok"
else
    check "ADMythen built" "lib directory not found at $ADMYTHEN_EXPANDED/lib"
fi

# --- IOC / PV checks (requires running IOC) ---
echo ""
echo "-- IOC PV checks (requires running IOC) --"

if ! command -v caget &>/dev/null; then
    echo "  [SKIP] caget not in PATH — skipping PV checks"
else
    for pv in \
        "${PREFIX}det1:DetectorState_RBV" \
        "${PREFIX}det1:Model_RBV" \
        "${PREFIX}det1:AcquireTime"; \
    do
        result=$(caget -t -w 2 "$pv" 2>&1) || true
        if echo "$result" | grep -qv "Channel connect timed out"; then
            check "PV $pv accessible" "ok"
        else
            check "PV $pv accessible" "timeout — is the IOC running? Check CA networking."
        fi
    done
fi

# --- Summary ---
echo ""
echo "============================================"
echo " Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
    echo " See SKILL.md Troubleshooting section for help."
    exit 1
else
    echo " All checks passed. EPICS IOC installation looks good."
fi
