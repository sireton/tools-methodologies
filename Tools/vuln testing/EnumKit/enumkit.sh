#!/usr/bin/env bash
# enumkit.sh — Interactive Pentest Enumeration Script
# Author: Sam Ireton
# Usage: ./enumkit.sh <target>

set -euo pipefail

# ---------------------------------------------------------------------------
# GLOBALS
# ---------------------------------------------------------------------------

TARGET="${1:-}"
WORDLIST_DEFAULT="/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt"

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------

info()    { echo -e "${CYAN}[*]${NC} $*"; }
success() { echo -e "${GREEN}[+]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[-]${NC} $*"; }

ask_yn() {
    # ask_yn "Question" "Y"   → default yes
    # ask_yn "Question" "N"   → default no
    local prompt="$1"
    local default="${2:-Y}"
    local hint
    if [[ "${default^^}" == "Y" ]]; then
        hint="[Y/n]"
    else
        hint="[y/N]"
    fi
    read -rp "  $prompt $hint: " answer
    answer="${answer:-$default}"
    [[ "${answer^^}" == "Y" ]]
}

ask_choice() {
    # ask_choice "prompt" option1 option2 option3 ...
    # Returns the number selected (1-based)
    local prompt="$1"; shift
    local options=("$@")
    echo "  $prompt"
    for i in "${!options[@]}"; do
        echo "    $((i+1))) ${options[$i]}"
    done
    local choice
    while true; do
        read -rp "  > " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            REPLY="$choice"
            return
        fi
        warn "Enter a number between 1 and ${#options[@]}"
    done
}

check_tool() {
    if ! command -v "$1" &>/dev/null; then
        warn "$1 not found — skipping"
        return 1
    fi
    return 0
}

# ---------------------------------------------------------------------------
# USAGE
# ---------------------------------------------------------------------------

usage() {
    echo ""
    echo "Usage: ./enumkit.sh <target>"
    echo ""
    echo "  target    IP address or hostname to enumerate"
    echo ""
    echo "Example:"
    echo "  ./enumkit.sh 10.10.10.1"
    echo "  ./enumkit.sh target.htb"
    echo ""
    exit 1
}

# ---------------------------------------------------------------------------
# VALIDATE TARGET
# ---------------------------------------------------------------------------

if [[ -z "$TARGET" ]]; then
    error "No target specified."
    usage
fi

# ---------------------------------------------------------------------------
# BANNER
# ---------------------------------------------------------------------------

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗"
echo -e "║           enumkit v1.0               ║"
echo -e "╚══════════════════════════════════════╝${NC}"
echo ""
info "Target: $TARGET"
echo ""

# ---------------------------------------------------------------------------
# STEP 1 — OUTPUT LOCATION
# ---------------------------------------------------------------------------

echo -e "${YELLOW}── Output Location ─────────────────────${NC}"
ask_choice "Where should output go?" \
    "Create output in current directory (./enumkit-output/)" \
    "Specify a custom directory" \
    "Use an existing engagekit workspace"

OUTPUT_MODE="$REPLY"

case "$OUTPUT_MODE" in
    1)
        OUTDIR="$(pwd)/enumkit-output"
        ;;
    2)
        read -rp "  Path: " CUSTOM_DIR
        OUTDIR="${CUSTOM_DIR/#\~/$HOME}"
        ;;
    3)
        read -rp "  Workspace path: " WS_DIR
        OUTDIR="${WS_DIR/#\~/$HOME}"
        if [[ ! -d "$OUTDIR" ]]; then
            error "Directory not found: $OUTDIR"
            exit 1
        fi
        # Check it looks like an engagekit workspace
        if [[ ! -d "$OUTDIR/scans" ]]; then
            warn "scans/ subfolder not found — this may not be an engagekit workspace"
            warn "Output will still be written to $OUTDIR/scans/"
        fi
        ;;
esac

NMAP_OUT="$OUTDIR/scans/nmap"
WEB_OUT="$OUTDIR/scans/web"
SMB_OUT="$OUTDIR/scans/smb"

echo ""

# ---------------------------------------------------------------------------
# STEP 2 — MODULE SELECTION
# ---------------------------------------------------------------------------

echo -e "${YELLOW}── Modules ─────────────────────────────${NC}"
RUN_NMAP=false
RUN_WEB=false
RUN_SMB=false

ask_yn "Run nmap?" "Y"      && RUN_NMAP=true
ask_yn "Run web enumeration (ffuf + whatweb)?" "Y" && RUN_WEB=true
ask_yn "Run SMB enumeration?" "Y" && RUN_SMB=true

echo ""

# ---------------------------------------------------------------------------
# STEP 3 — NMAP OPTIONS
# ---------------------------------------------------------------------------

NMAP_UDP=false
NMAP_VULN=false

if $RUN_NMAP; then
    echo -e "${YELLOW}── Nmap Options ────────────────────────${NC}"
    info "Fast all-port sweep + deep service scan will always run"
    ask_yn "Also run UDP top-100 scan?" "N" && NMAP_UDP=true
    ask_yn "Run vuln scripts after service scan?" "N" && NMAP_VULN=true
    echo ""
fi

# ---------------------------------------------------------------------------
# STEP 4 — WEB OPTIONS
# ---------------------------------------------------------------------------

WEB_WORDLIST=""
WEB_SCHEME="both"

if $RUN_WEB; then
    echo -e "${YELLOW}── Web Options ─────────────────────────${NC}"

    # Wordlist
    ask_yn "Use default wordlist (raft-medium-directories)?" "Y"
    if [[ $? -eq 0 ]]; then
        WEB_WORDLIST="$WORDLIST_DEFAULT"
    else
        read -rp "  Wordlist path: " CUSTOM_WL
        WEB_WORDLIST="${CUSTOM_WL/#\~/$HOME}"
        if [[ ! -f "$WEB_WORDLIST" ]]; then
            warn "Wordlist not found at $WEB_WORDLIST — falling back to default"
            WEB_WORDLIST="$WORDLIST_DEFAULT"
        fi
    fi

    # Scheme
    ask_choice "Scan which protocols?" "HTTP and HTTPS" "HTTP only" "HTTPS only"
    case "$REPLY" in
        1) WEB_SCHEME="both" ;;
        2) WEB_SCHEME="http" ;;
        3) WEB_SCHEME="https" ;;
    esac
    echo ""
fi

# ---------------------------------------------------------------------------
# STEP 5 — SMB OPTIONS
# ---------------------------------------------------------------------------

SMB_ENUM4LINUX=false
SMB_SMBCLIENT=false

if $RUN_SMB; then
    echo -e "${YELLOW}── SMB Options ─────────────────────────${NC}"
    ask_yn "Run enum4linux-ng?" "Y"  && SMB_ENUM4LINUX=true
    ask_yn "Run smbclient share list?" "Y" && SMB_SMBCLIENT=true
    echo ""
fi

# ---------------------------------------------------------------------------
# STEP 6 — CONFIRM AND START
# ---------------------------------------------------------------------------

echo -e "${YELLOW}── Summary ─────────────────────────────${NC}"
echo "  Target     : $TARGET"
echo "  Output     : $OUTDIR"
echo "  nmap       : $(  $RUN_NMAP && echo "yes (udp=$(  $NMAP_UDP  && echo yes || echo no), vuln=$($NMAP_VULN && echo yes || echo no))" || echo no)"
echo "  web        : $($RUN_WEB  && echo "yes (scheme=$WEB_SCHEME)" || echo no)"
echo "  smb        : $($RUN_SMB  && echo yes || echo no)"
echo ""

read -rp "  Start enumeration? [Y/n]: " CONFIRM
CONFIRM="${CONFIRM:-Y}"
if [[ "${CONFIRM^^}" != "Y" ]]; then
    info "Aborted."
    exit 0
fi

echo ""

# ---------------------------------------------------------------------------
# CREATE OUTPUT DIRECTORIES
# ---------------------------------------------------------------------------

$RUN_NMAP && mkdir -p "$NMAP_OUT"
$RUN_WEB  && mkdir -p "$WEB_OUT"
$RUN_SMB  && mkdir -p "$SMB_OUT"

# ---------------------------------------------------------------------------
# NMAP MODULE
# ---------------------------------------------------------------------------

if $RUN_NMAP; then
    echo -e "${YELLOW}── nmap ─────────────────────────────────${NC}"

    # Phase 1: fast all-port sweep
    info "Phase 1: Fast all-port sweep..."
    if check_tool nmap; then
        nmap -p- --min-rate 5000 -oA "$NMAP_OUT/allports" "$TARGET" 2>/dev/null
        success "All-port sweep complete → $NMAP_OUT/allports.*"

        # Extract open ports
        PORTS=$(grep "^[0-9]" "$NMAP_OUT/allports.nmap" 2>/dev/null \
            | grep "/tcp" \
            | awk -F'/' '{print $1}' \
            | tr '\n' ',' \
            | sed 's/,$//')

        if [[ -z "$PORTS" ]]; then
            warn "No open TCP ports found on $TARGET"
        else
            success "Open ports: $PORTS"

            # Phase 2: deep service scan
            info "Phase 2: Deep service scan on $PORTS..."
            nmap -p "$PORTS" -sC -sV -oA "$NMAP_OUT/targeted" "$TARGET" 2>/dev/null
            success "Service scan complete → $NMAP_OUT/targeted.*"

            # Phase 3: UDP (optional)
            if $NMAP_UDP; then
                info "Phase 3: UDP top-100 scan..."
                sudo nmap -sU --top-ports 100 -oA "$NMAP_OUT/udp-top100" "$TARGET" 2>/dev/null
                success "UDP scan complete → $NMAP_OUT/udp-top100.*"
            fi

            # Phase 4: Vuln scripts (optional)
            if $NMAP_VULN; then
                info "Phase 4: Vuln scripts..."
                nmap -p "$PORTS" --script vuln -oA "$NMAP_OUT/vuln" "$TARGET" 2>/dev/null
                success "Vuln scan complete → $NMAP_OUT/vuln.*"
            fi
        fi
    fi
    echo ""
fi

# ---------------------------------------------------------------------------
# WEB MODULE
# ---------------------------------------------------------------------------

if $RUN_WEB; then
    echo -e "${YELLOW}── web ──────────────────────────────────${NC}"

    # Determine which ports to scan
    # If nmap ran, read from its output. Otherwise probe common ports.
    if $RUN_NMAP && [[ -f "$NMAP_OUT/allports.nmap" ]]; then
        RAW_PORTS=$(grep "^[0-9]" "$NMAP_OUT/allports.nmap" 2>/dev/null \
            | grep "/tcp" \
            | awk -F'/' '{print $1}')
    else
        warn "nmap output not available — probing common web ports"
        RAW_PORTS="80 443 8080 8443"
    fi

    WEB_FOUND=false

    for PORT in $RAW_PORTS; do
        # Determine scheme
        if [[ "$PORT" == "443" || "$PORT" == "8443" ]]; then
            DETECTED_SCHEME="https"
        else
            DETECTED_SCHEME="http"
        fi

        # Skip if scheme filter doesn't match
        if [[ "$WEB_SCHEME" == "http"  && "$DETECTED_SCHEME" == "https" ]]; then continue; fi
        if [[ "$WEB_SCHEME" == "https" && "$DETECTED_SCHEME" == "http"  ]]; then continue; fi

        # Only act on common web ports
        if [[ "$PORT" =~ ^(80|443|8080|8443|8000|8008|8888)$ ]]; then
            URL="${DETECTED_SCHEME}://${TARGET}:${PORT}"
            info "Web enumeration: $URL"
            WEB_FOUND=true

            # WhatWeb fingerprint
            if check_tool whatweb; then
                whatweb "$URL" -a 3 \
                    --log-verbose="$WEB_OUT/whatweb-${PORT}.txt" 2>/dev/null \
                    || true
                success "whatweb complete → $WEB_OUT/whatweb-${PORT}.txt"
            fi

            # ffuf directory fuzzing
            if check_tool ffuf; then
                if [[ ! -f "$WEB_WORDLIST" ]]; then
                    warn "Wordlist not found: $WEB_WORDLIST — skipping ffuf"
                else
                    ffuf -w "$WEB_WORDLIST" \
                         -u "${URL}/FUZZ" \
                         -mc 200,204,301,302,307,401,403 \
                         -o "$WEB_OUT/ffuf-${PORT}.json" \
                         -of json \
                         -t 40 \
                         -s 2>/dev/null \
                         || true
                    success "ffuf complete → $WEB_OUT/ffuf-${PORT}.json"
                fi
            fi
        fi
    done

    if ! $WEB_FOUND; then
        warn "No web ports detected"
    fi
    echo ""
fi

# ---------------------------------------------------------------------------
# SMB MODULE
# ---------------------------------------------------------------------------

if $RUN_SMB; then
    echo -e "${YELLOW}── smb ──────────────────────────────────${NC}"

    # Check if 445 is actually open if nmap ran
    SMB_OPEN=true
    if $RUN_NMAP && [[ -f "$NMAP_OUT/allports.nmap" ]]; then
        if ! grep -q "^445" "$NMAP_OUT/allports.nmap" 2>/dev/null; then
            warn "Port 445 not detected in nmap output — running SMB anyway"
        fi
    fi

    if $SMB_ENUM4LINUX; then
        if check_tool enum4linux-ng; then
            info "Running enum4linux-ng..."
            enum4linux-ng -A "$TARGET" > "$SMB_OUT/enum4linux.txt" 2>&1 || true
            success "enum4linux-ng complete → $SMB_OUT/enum4linux.txt"
        fi
    fi

    if $SMB_SMBCLIENT; then
        if check_tool smbclient; then
            info "Running smbclient share list (null session)..."
            smbclient -N -L "//$TARGET" > "$SMB_OUT/smbclient-shares.txt" 2>&1 || true
            success "smbclient complete → $SMB_OUT/smbclient-shares.txt"
        fi
    fi
    echo ""
fi

# ---------------------------------------------------------------------------
# FINDINGS SUMMARY
# ---------------------------------------------------------------------------

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗"
echo -e "║         Findings Summary             ║"
echo -e "╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Target:${NC} $TARGET"
echo -e "  ${CYAN}Output:${NC} $OUTDIR"
echo ""

# --- NMAP SUMMARY ---
if $RUN_NMAP && [[ -f "$NMAP_OUT/targeted.nmap" ]]; then
    echo -e "${YELLOW}── Open Ports & Services ───────────────${NC}"

    # Parse open ports and service versions from targeted scan
    while IFS= read -r line; do
        if [[ "$line" =~ ^([0-9]+)/tcp.*open[[:space:]]+([a-zA-Z0-9_-]+)[[:space:]]*(.*) ]]; then
            PORT="${BASH_REMATCH[1]}"
            SERVICE="${BASH_REMATCH[2]}"
            VERSION="${BASH_REMATCH[3]}"
            printf "  ${GREEN}%-6s${NC} %-12s %s\n" "$PORT" "$SERVICE" "$VERSION"
        fi
    done < "$NMAP_OUT/targeted.nmap"

    echo ""

    # Notable port flags
    echo -e "${YELLOW}── Notable Flags ───────────────────────${NC}"
    FLAGGED=false

    # SSH
    if grep -q "^22/tcp.*open" "$NMAP_OUT/targeted.nmap" 2>/dev/null; then
        echo -e "  ${CYAN}[SSH]${NC}  Port 22 open — try default/weak creds, check banner for version"
        FLAGGED=true
    fi

    # FTP anonymous
    if grep -q "^21/tcp.*open" "$NMAP_OUT/targeted.nmap" 2>/dev/null; then
        if grep -q "Anonymous FTP login allowed" "$NMAP_OUT/targeted.nmap" 2>/dev/null; then
            echo -e "  ${RED}[FTP]${NC}  Anonymous FTP login allowed — check for readable/writable files"
        else
            echo -e "  ${CYAN}[FTP]${NC}  Port 21 open — test anonymous login manually"
        fi
        FLAGGED=true
    fi

    # SMB
    if grep -q "^445/tcp.*open" "$NMAP_OUT/targeted.nmap" 2>/dev/null; then
        echo -e "  ${CYAN}[SMB]${NC}  Port 445 open — check null session, guest access, share permissions"
        FLAGGED=true
    fi

    # RDP
    if grep -q "^3389/tcp.*open" "$NMAP_OUT/targeted.nmap" 2>/dev/null; then
        echo -e "  ${CYAN}[RDP]${NC}  Port 3389 open — check for BlueKeep / weak creds"
        FLAGGED=true
    fi

    # WinRM
    if grep -q "^5985/tcp.*open\|^5986/tcp.*open" "$NMAP_OUT/targeted.nmap" 2>/dev/null; then
        echo -e "  ${CYAN}[WINRM]${NC} Port 5985/5986 open — try Evil-WinRM if creds obtained"
        FLAGGED=true
    fi

    # MSSQL
    if grep -q "^1433/tcp.*open" "$NMAP_OUT/targeted.nmap" 2>/dev/null; then
        echo -e "  ${CYAN}[MSSQL]${NC} Port 1433 open — check for sa / default creds, xp_cmdshell"
        FLAGGED=true
    fi

    # LDAP (likely AD)
    if grep -q "^389/tcp.*open\|^636/tcp.*open" "$NMAP_OUT/targeted.nmap" 2>/dev/null; then
        echo -e "  ${CYAN}[LDAP]${NC}  Port 389/636 open — likely Active Directory, try anonymous bind"
        FLAGGED=true
    fi

    if ! $FLAGGED; then
        echo "  No notable flags"
    fi

    echo ""
fi

# --- WEB SUMMARY ---
if $RUN_WEB; then
    WEB_FILES=("$WEB_OUT"/whatweb-*.txt)
    if [[ -f "${WEB_FILES[0]}" ]]; then
        echo -e "${YELLOW}── Web Technologies ────────────────────${NC}"
        for f in "$WEB_OUT"/whatweb-*.txt; do
            [[ -f "$f" ]] || continue
            PORT=$(basename "$f" | sed 's/whatweb-\(.*\)\.txt/\1/')
            echo -e "  ${CYAN}Port $PORT:${NC}"

            # Extract HTTP title
            TITLE=$(grep -o 'Title\[[^]]*\]' "$f" 2>/dev/null | head -1 | sed 's/Title\[//;s/\]//' || true)
            [[ -n "$TITLE" ]] && echo "    Title       : $TITLE"

            # Extract detected technologies (IP, Country, HTTPServer, X-Powered-By, etc.)
            grep -oP '(?<=HTTPServer\[)[^\]]+' "$f" 2>/dev/null | head -1 \
                | while read -r v; do echo "    Server      : $v"; done || true

            grep -oP '(?<=X-Powered-By\[)[^\]]+' "$f" 2>/dev/null | head -1 \
                | while read -r v; do echo "    Powered-By  : $v"; done || true

            grep -oP '(?<=WordPress\[)[^\]]+\]|WordPress' "$f" 2>/dev/null | head -1 \
                | while read -r v; do echo "    CMS         : WordPress $v"; done || true

            grep -oP '(?<=Joomla\[)[^\]]+\]|Joomla' "$f" 2>/dev/null | head -1 \
                | while read -r v; do echo "    CMS         : Joomla $v"; done || true

            echo ""
        done
    fi

    # ffuf hits
    FFUF_FILES=("$WEB_OUT"/ffuf-*.json)
    if [[ -f "${FFUF_FILES[0]}" ]]; then
        echo -e "${YELLOW}── Web Directories Found ───────────────${NC}"
        for f in "$WEB_OUT"/ffuf-*.json; do
            [[ -f "$f" ]] || continue
            PORT=$(basename "$f" | sed 's/ffuf-\(.*\)\.json/\1/')
            # Extract urls and status codes from ffuf JSON
            if command -v python3 &>/dev/null; then
                python3 -c "
import json, sys
try:
    data = json.load(open('$f'))
    results = data.get('results', [])
    if not results:
        print('    No results')
    for r in results[:20]:
        print(f\"    [{r.get('status','')}] /{r.get('input',{}).get('FUZZ','')}  ({r.get('length','')} bytes)\")
    if len(results) > 20:
        print(f'    ... and {len(results)-20} more (see $f)')
except Exception as e:
    print(f'    Could not parse: {e}')
" 2>/dev/null && echo ""
            else
                HIT_COUNT=$(grep -c '"status"' "$f" 2>/dev/null || echo 0)
                echo "  Port $PORT: $HIT_COUNT results — see $f"
            fi
        done
        echo ""
    fi
fi

# --- SMB SUMMARY ---
if $RUN_SMB; then
    echo -e "${YELLOW}── SMB Shares ──────────────────────────${NC}"

    if [[ -f "$SMB_OUT/smbclient-shares.txt" ]]; then
        # Extract share names and types
        SHARES=$(grep "Disk\|IPC\|Printer" "$SMB_OUT/smbclient-shares.txt" 2>/dev/null || true)
        if [[ -n "$SHARES" ]]; then
            echo "$SHARES" | while IFS= read -r line; do
                echo "  $line"
            done

            # Flag anonymous access
            if ! grep -q "NT_STATUS_ACCESS_DENIED\|NT_STATUS_LOGON_FAILURE" \
                "$SMB_OUT/smbclient-shares.txt" 2>/dev/null; then
                echo ""
                echo -e "  ${RED}[!]${NC} Null session succeeded — anonymous SMB access may be available"
            fi
        else
            echo "  No shares returned (null session likely blocked)"
        fi
    fi

    if [[ -f "$SMB_OUT/enum4linux.txt" ]]; then
        # Surface any users found
        USERS=$(grep -A1 "username:" "$SMB_OUT/enum4linux.txt" 2>/dev/null \
            | grep -v "^--$" | head -10 || true)
        if [[ -n "$USERS" ]]; then
            echo ""
            echo -e "  ${CYAN}Users found via enum4linux:${NC}"
            echo "$USERS" | while IFS= read -r line; do
                echo "    $line"
            done
        fi
    fi

    echo ""
fi

echo -e "${GREEN}[+]${NC} enumkit complete — $TARGET"
echo ""
