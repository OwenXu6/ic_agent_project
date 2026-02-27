#!/bin/bash
# Run this script ONCE in your Remote Desktop terminal after running:
#   prep -l ECE260B_WI26_A00
#
# It saves the full EDA environment to ~/.eda_env so that SSH agent
# sessions can source it without needing the desktop session.
#
# Usage:
#   bash ~/ic_agent/tools/capture_eda_env.sh

OUT=~/.eda_env

echo "# EDA environment captured on $(date) from $(hostname)" > "$OUT"
echo "# Source this file before running dc_shell, innovus, etc." >> "$OUT"
echo "" >> "$OUT"

# Save full PATH
echo "export PATH=\"$PATH\"" >> "$OUT"

# Save critical env vars
for VAR in \
    SNPSLMD_LICENSE_FILE \
    CDS_LIC_FILE \
    PDK_DIR \
    DCOMPILER \
    SYNOPSYS \
    CDSHOME \
    CDS_INST_DIR \
    LD_LIBRARY_PATH \
    MANPATH \
    ACMS_MODULES \
    MODULEPATH \
    PREPPROMPT \
    PREPLABEL; do
    VAL="${!VAR}"
    if [ -n "$VAL" ]; then
        echo "export ${VAR}=\"${VAL}\"" >> "$OUT"
    fi
done

echo "" >> "$OUT"
echo "Saved EDA environment to $OUT"
echo ""
echo "Contents:"
cat "$OUT"
echo ""
echo "Quick check:"
which dc_shell && echo "dc_shell OK" || echo "WARNING: dc_shell not in PATH"
which innovus  && echo "innovus OK"  || echo "WARNING: innovus not in PATH"
