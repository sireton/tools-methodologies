# engagekit

![Python](https://img.shields.io/badge/python-3.8%2B-blue?style=flat-square&logo=python)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)

A cross-platform Python script that scaffolds a structured pentest engagement workspace in seconds. Run it before you start work and get a ready-to-use directory with pre-populated markdown templates, organised scan folders, a loot tracker, and a timestamped evidence capture helper — all named and dated for the engagement automatically.

---

## What It Creates

```
AcmeCorp-20260330/
├── README.md                        ← Workspace quick reference
├── 00-Scope.md                      ← Fill this out first
├── notes/
│   ├── 01-Recon.md
│   ├── 02-Foothold.md
│   ├── 03-Post-Exploitation.md
│   ├── 04-Lateral-Movement.md
│   ├── 05-Privilege-Escalation.md
│   └── 06-Findings.md               ← CVSS + MITRE ATT&CK ready
├── scans/
│   ├── nmap/
│   ├── web/
│   ├── smb/
│   └── ldap/
├── evidence/
│   └── capture.sh  /  capture.bat   ← Timestamped evidence capture helper
├── loot/
│   └── loot.md                      ← Credentials, hashes, flags
└── tools/                           ← Payloads and custom scripts
```

Scope type controls which `scans/` subfolders are created — a web app engagement gets `web/` only, an internal gets `nmap/smb/ldap/`, and so on.

---

## Requirements

- Python 3.8 or later
- No external dependencies — standard library only

---

## Installation

```bash
git clone https://github.com/sireton/engagekit
cd engagekit
```

**Optional — add to PATH so you can run it from anywhere:**

```bash
# Linux / macOS
cp engagekit.py ~/.local/bin/engagekit
chmod +x ~/.local/bin/engagekit

# Windows (PowerShell) — add the folder to your PATH via System Settings
# then run as: python engagekit.py
```

---

## Usage

```
python engagekit.py <target> [options]

Arguments:
  target              Short identifier used in folder name (e.g. AcmeCorp)

Options:
  -a, --author        Tester name
  -c, --client        Full client name for templates (default: same as target)
  -s, --scope         Scope type: internal | external | webapp | ad | full (default: full)
  -o, --output        Base output directory (default: ./engagements)
  --no-templates      Create folder structure only, skip markdown files
  --dry-run           Print what would be created without writing anything
```

---

## Examples

```bash
# Quickest — target name only
python engagekit.py AcmeCorp

# Full client engagement
python engagekit.py AcmeCorp -c "Acme Corporation" -s internal -a "Sam Ireton"

# Web app scope — only creates scans/web/
python engagekit.py ClientPortal -c "Client Web Portal" -s webapp

# Active Directory focused
python engagekit.py CorpAD -c "Corp Internal AD" -s ad

# Custom output directory
python engagekit.py AcmeCorp -o ~/Engagements

# Preview without creating anything
python engagekit.py AcmeCorp --dry-run

# Folders only, no markdown
python engagekit.py AcmeCorp --no-templates
```

---

## Scope Types

| Flag       | Scan subfolders created       | Best for                        |
|------------|-------------------------------|---------------------------------|
| `full`     | nmap, web, smb, ldap          | General / unknown scope         |
| `internal` | nmap, smb, ldap               | Internal network assessments    |
| `external` | nmap, web                     | External / perimeter            |
| `webapp`   | web                           | Web application only            |
| `ad`       | nmap, smb, ldap               | Active Directory focused        |

---

## Evidence Capture Helper

The `capture.sh` (Linux/macOS) or `capture.bat` (Windows) script in the `evidence/` folder saves timestamped command output with a single command. Run it, paste your output, and save. No manual file naming.

```bash
# Linux / macOS
cd evidence/
./capture.sh "nmap full port scan"
# Paste output → Ctrl+D to save
# Creates: 20260330_143022-nmap_full_port_scan.txt

# Windows
cd evidence\
capture.bat "nmap full port scan"
# Paste output → Ctrl+Z + Enter to save
```

---

## Workflow

1. Run `engagekit.py` with the target name before starting work
2. Fill out `00-Scope.md` — in/out of scope, RoE, credentials
3. Work through `notes/01` through `notes/05` as you progress through each phase
4. Drop raw tool output into `scans/<tooltype>/`
5. Use `evidence/capture.sh` to save command output as you go
6. Track all credentials, hashes, and keys in `loot/loot.md`
7. Document findings in `notes/06-Findings.md` with CVSS scores and MITRE mappings

---

## Related Tools

- [reconX](https://github.com/sireton/reconX) — automated initial enumeration, pairs naturally with engagekit
