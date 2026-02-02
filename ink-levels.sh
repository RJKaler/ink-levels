#!/bin/bash

PRINTER_IP="192.168.1.194"
logfile="$HOME/logs/ink-levels.log"

if [[ ! -d "$HOME/logs"
  echo "Creating dir for log file..." 
  mkdir -vp "$HOME/logs"
else 
  echo "Log dir exists. Proceeding..." 
fi

echo "[Querying printer… please wait]"

# Parallel SNMP queries (FAST)
snmp_output="$(
  printf "%s\n" \
    "1.3.6.1.2.1.43.11.1.1.6" \
    "1.3.6.1.2.1.43.11.1.1.9" |
  xargs -P 2 -I{} snmpwalk -v1 -c public "$PRINTER_IP" {}
)"

# Parse
parsed_output="$(echo "$snmp_output" | awk '
/\.43\.11\.1\.1\.6\.1\./ {
    split($1,a,".");
    idx=a[length(a)];
    sub(/.*STRING: "/,"",$0);
    sub(/"$/,"",$0);
    name[idx]=$0
}
/\.43\.11\.1\.1\.9\.1\./ {
    split($1,a,".");
    idx=a[length(a)];
    sub(/.*INTEGER: /,"",$0);
    level[idx]=$0
}
END {
    for (i in name) {
        printf "%-35s %3s%%\n", name[i], level[i]
    }
}
')"

# STDOUT
echo "$parsed_output"

# LOG
{
  echo "======== $(date) ========"
  echo "$parsed_output"
  echo
} >> "$logfile"
