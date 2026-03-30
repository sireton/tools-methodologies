# enumkit

![Bash](https://img.shields.io/badge/bash-5.0%2B-green?style=flat-square&logo=gnu-bash)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)

An interactive bash script that runs a structured enumeration workflow against a target and prints a clean findings summary when complete. Covers nmap, web (ffuf + whatweb), and SMB. Designed to work standalone or drop output directly into an [engagekit](https://github.com/sireton/engagekit) workspace.

---

## What It Does

1. Walks you through a short interactive setup: output location, which modules to run, and scan options for each
2. Runs the selected modules in sequence with real-time progress output
3. Prints a parsed findings summary on screen when complete: open ports with service versions, detected web technologies, ffuf directory hits, SMB shares, and notable flags

---

## Requirements

- bash 5.0+
- `nmap` — port scanning
- `ffuf` — web directory fuzzing
- `whatweb` — web technology fingerprinting
- `enum4linux-ng` — SMB enumeration
- `smbclient` — SMB share listing

All available via `apt` on Kali, Parrot, or the HTB Pwnbox. Tools are checked before use — missing tools are skipped with a warning rather than crashing the script.

---

## Installation

```bash
git clone https://github.com/sireton/enumkit
cd enumkit
chmod +x enumkit.sh
```

---

## Usage

```bash
./enumkit.sh <target>
```

The script walks you through setup interactively. No flags required.

```bash
./enumkit.sh 10.10.10.1
./enumkit.sh target.htb
```

---

## Interactive Setup Flow

```
╔══════════════════════════════════════╗
║           enumkit v1.0               ║
╚══════════════════════════════════════╝

[*] Target: 10.10.10.1

── Output Location ─────────────────────
  Where should output go?
    1) Create output in current directory (./enumkit-output/)
    2) Specify a custom directory
    3) Use an existing engagekit workspace

── Modules ─────────────────────────────
  Run nmap? [Y/n]
  Run web enumeration (ffuf + whatweb)? [Y/n]
  Run SMB enumeration? [Y/n]

── Nmap Options ────────────────────────
  Also run UDP top-100 scan? [y/N]
  Run vuln scripts after service scan? [y/N]

── Web Options ─────────────────────────
  Use default wordlist (raft-medium-directories)? [Y/n]
  Scan which protocols?
    1) HTTP and HTTPS
    2) HTTP only
    3) HTTPS only

── SMB Options ─────────────────────────
  Run enum4linux-ng? [Y/n]
  Run smbclient share list? [Y/n]

── Summary ─────────────────────────────
  Start enumeration? [Y/n]
```

---

## Output Structure

### Standalone mode

```
enumkit-output/
└── scans/
    ├── nmap/
    │   ├── allports.nmap / .xml / .gnmap
    │   ├── targeted.nmap / .xml / .gnmap
    │   ├── udp-top100.*        (if selected)
    │   └── vuln.*              (if selected)
    ├── web/
    │   ├── whatweb-80.txt
    │   ├── whatweb-443.txt
    │   ├── ffuf-80.json
    │   └── ffuf-443.json
    └── smb/
        ├── enum4linux.txt
        └── smbclient-shares.txt
```

### engagekit workspace mode

Point enumkit at an existing engagekit workspace and output drops directly into the existing `scans/` subfolders:

```bash
./enumkit.sh 10.10.10.1
# Select option 3 when prompted for output location
# Enter: ~/Engagements/AcmeCorp-20260330
```

---

## Findings Summary

After all scans complete, enumkit parses the raw output and prints a structured summary:

```
╔══════════════════════════════════════╗
║         Findings Summary             ║
╚══════════════════════════════════════╝

  Target: 10.10.10.1

── Open Ports & Services ───────────────
  22     ssh          OpenSSH 7.4 (protocol 2.0)
  80     http         Apache httpd 2.4.6
  445    microsoft-ds Windows Server 2016

── Notable Flags ────────────────────────
  [SSH]   Port 22 open — try default/weak creds, check banner for version
  [SMB]   Port 445 open — check null session, guest access, share permissions

── Web Technologies ─────────────────────
  Port 80:
    Title      : Welcome to AcmeCorp
    Server     : Apache/2.4.6 (CentOS)
    Powered-By : PHP/5.4.16

── Web Directories Found ────────────────
  [200] /admin   (1342 bytes)
  [301] /images  (234 bytes)
  [403] /backup  (289 bytes)

── SMB Shares ───────────────────────────
  ADMIN$   Disk   Remote Admin
  C$       Disk   Default share
  IPC$     IPC    Remote IPC
  Files    Disk

  [!] Null session succeeded — anonymous SMB access may be available
```

Notable flags are surfaced automatically for: anonymous FTP, open SMB with null session check, SSH, RDP, WinRM, MSSQL, and LDAP.

---

## Integration with engagekit

enumkit is designed to pair with [engagekit](https://github.com/sireton/engagekit). The recommended workflow:

```bash
# 1. Scaffold the engagement workspace
python engagekit.py AcmeCorp -c "Acme Corporation" -s internal

# 2. Run enumkit and point it at the workspace
./enumkit.sh 10.10.10.1
# Select option 3 → enter the engagekit workspace path

# 3. Output lands directly in scans/nmap, scans/web, scans/smb
# 4. Work through notes/01-Recon.md using the findings summary as your starting point
```

---

## Related Tools

- [engagekit](https://github.com/sireton/engagekit) — pentest engagement workspace scaffolder
