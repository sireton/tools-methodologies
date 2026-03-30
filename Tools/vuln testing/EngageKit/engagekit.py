#!/usr/bin/env python3
"""
engagekit.py — Pentest Engagement Workspace Scaffolder
Author: Sam Ireton

Usage:
    python engagekit.py <TargetName> [options]

Options:
    -a, --author      Tester name (default: Sam Ireton)
    -c, --client      Client or target name (default: same as TargetName)
    -s, --scope       Scope type: internal | external | webapp | ad | full (default: full)
    -o, --output      Base output directory (default: ./engagements)
    --no-templates    Create folders only, skip markdown files
    --dry-run         Print what would be created without writing anything

Examples:
    python engagekit.py AcmeCorp -c "Acme Corporation" -s internal
    python engagekit.py ClientWeb -s webapp -o ~/Engagements
    python engagekit.py TestLab --dry-run
"""

import argparse
import platform
from datetime import date
from pathlib import Path


# ---------------------------------------------------------------------------
# 1. OS DETECTION
# Figures out whether we are on Windows, macOS, or Linux so the script can
# adapt paths and generate the right capture helper (capture.sh vs capture.bat).
# ---------------------------------------------------------------------------

def detect_os() -> str:
    system = platform.system().lower()
    if system == "windows":
        return "windows"
    elif system == "darwin":
        return "macos"
    elif system == "linux":
        return "linux"
    else:
        return "unknown"


def sanitize_name(name: str, os_type: str) -> str:
    """
    Strips characters from a string that are illegal in file/folder names
    on the current OS. Windows has the most restrictions so we apply those
    when on Windows; Unix-like systems just strip slashes.
    """
    if os_type == "windows":
        for char in r'<>:"/\\|?*':
            name = name.replace(char, "_")
    else:
        name = name.replace("/", "_").replace("\\", "_")
    return name


# ---------------------------------------------------------------------------
# 2. FOLDER STRUCTURE DEFINITION
# Defines which directories to create. The structure is the same regardless
# of OS — only the capture helper script changes.
# Scope type controls which scan subfolders make sense for the engagement.
# ---------------------------------------------------------------------------

SCAN_SUBDIRS = {
    "internal": ["nmap", "smb", "ldap"],
    "external": ["nmap", "web"],
    "webapp":   ["web"],
    "ad":       ["nmap", "smb", "ldap"],
    "full":     ["nmap", "web", "smb", "ldap"],
}

def build_directory_list(scope: str) -> list:
    """
    Returns a list of relative directory paths to create inside the engagement
    root. Scope type trims irrelevant scan subfolders — no point creating an
    ldap/ folder on a pure web app assessment.
    """
    dirs = ["scans", "evidence", "loot", "tools", "notes"]
    for sub in SCAN_SUBDIRS.get(scope, SCAN_SUBDIRS["full"]):
        dirs.append(f"scans/{sub}")
    return dirs


# ---------------------------------------------------------------------------
# 3. TEMPLATE CONTENT
# Each function below returns a string of markdown content for one file.
# These are pre-populated with the engagement details passed in at runtime
# so you open the file and it is already labelled and dated correctly.
# ---------------------------------------------------------------------------

SCOPE_LABELS = {
    "internal": "Internal Network",
    "external": "External / Perimeter",
    "webapp":   "Web Application",
    "ad":       "Active Directory",
    "full":     "Full Scope",
}

def scope_template(target: str, client: str, author: str, scope: str) -> str:
    """
    00-Scope.md — the first file you fill out before starting work.
    Contains target info, scope type, in/out of scope definitions,
    rules of engagement, and a checklist of attack phases to tick off.
    """
    today = date.today().isoformat()
    scope_label = SCOPE_LABELS.get(scope, "Full Scope")
    return f"""---
target: {target}
client: {client}
date: {today}
author: {author}
scope_type: {scope_label}
status: In Progress
---

# Engagement Scope — {client}

## Target Information

| Field      | Value         |
|---|---|
| Client     | {client}      |
| Target     | {target}      |
| Scope Type | {scope_label} |
| Start Date | {today}       |
| Tester     | {author}      |

## Scope Type

- [ ] Internal Network
- [ ] External / Perimeter
- [ ] Web Application
- [ ] Active Directory
- [ ] Full Scope

## In Scope

- 

## Out of Scope

- Denial of service testing
- Social engineering (unless explicitly authorised)
- Production database modification

## Rules of Engagement

- Testing window:
- Emergency contact:
- Actions requiring prior approval:

## Credentials Provided

| Username | Password | Privilege Level |
|---|---|---|
| None | None | N/A |

---

## Attack Map

- [ ] Recon & Enumeration
- [ ] Foothold
- [ ] Post-Exploitation
- [ ] Lateral Movement
- [ ] Privilege Escalation
- [ ] Objectives
"""


def phase_template(target: str, phase_name: str, author: str) -> str:
    """
    One file per attack phase (Recon, Foothold, etc.).
    Each has a checklist, a commands section, and a findings/notes section.
    The link back to 00-Scope.md keeps everything navigable in Obsidian.
    """
    today = date.today().isoformat()
    return f"""---
target: {target}
phase: {phase_name}
date: {today}
author: {author}
---

# {phase_name} — {target}

## Checklist

- [ ] 

## Commands Run

```bash
# 
```

## Findings / Notes



## Evidence

- See `../evidence/` directory

---

*[Back to Scope](../00-Scope.md)*
"""


def findings_template(target: str, client: str, author: str) -> str:
    """
    06-Findings.md — structured finding blocks ready for reporting.
    Each finding has severity, CVSS score, MITRE ATT&CK mapping,
    evidence, impact, and remediation. Duplicate the F-01 block for
    each additional finding found during the engagement.
    """
    today = date.today().isoformat()
    return f"""---
target: {target}
client: {client}
date: {today}
author: {author}
---

# Findings — {client}

## Summary

| ID   | Title | Severity    | CVSS |
|---|---|---|---|
| F-01 |       | 🔴 Critical |      |

---

## F-01 — [Title]

| Field             | Detail |
|---|---|
| **Severity**      | 🔴 Critical |
| **CVSS Score**    | |
| **CVSSv3 Vector** | `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` |
| **Affected System** | |
| **MITRE ATT&CK**  | `TXXXX — Technique Name` |

### Description



### Evidence

```bash
# Command / output demonstrating exploitability
```

### Impact

> **Worst case:**

### Remediation

1. 

---

*Duplicate the block above for each additional finding.*
"""


def loot_template(target: str, client: str) -> str:
    """
    loot/loot.md — centralised tracker for everything sensitive found
    during the engagement: credentials, hashes, keys, and interesting files.
    The warning header is intentional — this file must never be committed
    to a public repo or included in client deliverables as-is.
    """
    return f"""# Loot — {client}

> ⚠️  SENSITIVE — keep local. Never commit to a public repo or share outside the engagement.

## Credentials

| Username | Password / Hash | Source | Cracked? | Used For |
|---|---|---|---|---|
|          |                 |        |          |          |

## Hashes

| Type   | Hash | Cracked Value |
|---|---|---|
| NTLM   |      |               |
| bcrypt |      |               |

## SSH / Private Keys

| File Path | Passphrase | Used For |
|---|---|---|
|           |            |          |

## Interesting Files

| File | Contents Summary | Location on Target |
|---|---|---|
|      |                  |                    |
"""


def capture_script_unix(target: str, client: str) -> str:
    """
    evidence/capture.sh — runs on Linux and macOS.
    Call it with a short description of what you are capturing.
    It creates a timestamped file, writes a header with engagement details,
    then waits for you to paste command output. Ctrl+D saves and closes it.

    Example: ./capture.sh "nmap full port scan"
    Creates:  20260330_143022-nmap_full_port_scan.txt
    """
    return f"""#!/usr/bin/env bash
# capture.sh — Timestamped evidence capture
# Engagement: {client} / {target}
#
# Usage: ./capture.sh "description of what you are capturing"
# Paste your command output at the prompt, then Ctrl+D to save.

DESC="${{1:-capture}}"
OUTFILE="./$(date +%Y%m%d_%H%M%S)-${{DESC// /_}}.txt"

{{
    echo "======================================================"
    echo "  Engagement : {client}"
    echo "  Capture    : $DESC"
    echo "  Timestamp  : $(date)"
    echo "  Host       : $(hostname) | User: $(whoami)"
    echo "======================================================"
    echo ""
}} >> "$OUTFILE"

echo "[*] Capturing to: $OUTFILE"
echo "[*] Paste output then Ctrl+D to save."
cat >> "$OUTFILE"
echo "[+] Saved: $OUTFILE"
"""


def capture_script_windows(target: str, client: str) -> str:
    """
    evidence/capture.bat — Windows equivalent of capture.sh.
    Same concept: run it with a description, paste output, Ctrl+Z + Enter to save.

    Example: capture.bat "nmap full port scan"
    Creates:  20260330_143022-nmap_full_port_scan.txt
    """
    return f"""@echo off
REM capture.bat — Timestamped evidence capture
REM Engagement: {client} / {target}
REM
REM Usage: capture.bat "description of what you are capturing"
REM Paste output at the prompt, then Ctrl+Z and Enter to save.

SET DESC=%~1
IF "%DESC%"=="" SET DESC=capture
FOR /F "tokens=2 delims==" %%I IN ('wmic os get localdatetime /value') DO SET DT=%%I
SET TIMESTAMP=%DT:~0,8%_%DT:~8,6%
SET OUTFILE=%TIMESTAMP%_%DESC: =_%.txt

echo ====================================================== >> %OUTFILE%
echo   Engagement : {client} >> %OUTFILE%
echo   Capture    : %DESC% >> %OUTFILE%
echo   Timestamp  : %DATE% %TIME% >> %OUTFILE%
echo ====================================================== >> %OUTFILE%
echo. >> %OUTFILE%

echo [*] Capturing to: %OUTFILE%
echo [*] Paste output then Ctrl+Z and Enter to save.
more >> %OUTFILE%
echo [+] Saved: %OUTFILE%
"""


def readme_template(target: str, client: str, author: str, scope: str) -> str:
    """
    README.md — quick reference card for the engagement workspace.
    Shows the folder structure, workflow steps, and capture helper usage.
    """
    today = date.today().isoformat()
    date_compact = today.replace("-", "")
    scope_label = SCOPE_LABELS.get(scope, "Full Scope")
    return f"""# {client} — Engagement Workspace

| Field   | Value         |
|---|---|
| Client  | {client}      |
| Target  | {target}      |
| Scope   | {scope_label} |
| Tester  | {author}      |
| Created | {today}       |
| Status  | In Progress   |

## Structure

```
{target}-{date_compact}/
├── README.md
├── 00-Scope.md          ← Fill this out first
├── notes/
│   ├── 01-Recon.md
│   ├── 02-Foothold.md
│   ├── 03-Post-Exploitation.md
│   ├── 04-Lateral-Movement.md
│   ├── 05-Privilege-Escalation.md
│   └── 06-Findings.md
├── scans/               ← Raw tool output organised by tool type
├── evidence/            ← Timestamped screenshots and command output
│   └── capture.sh/.bat ← Run this to save timestamped evidence
├── loot/
│   └── loot.md          ← Credentials, hashes, keys — never share publicly
└── tools/               ← Payloads and custom scripts
```

## Workflow

1. Fill out `00-Scope.md` before doing anything else.
2. Work through each phase note in `notes/` in order.
3. Drop raw tool output into `scans/<tooltype>/`.
4. Use the capture helper in `evidence/` to save timestamped command output as you go.
5. Track all credentials, hashes, and keys in `loot/loot.md`.
6. Document each finding in `notes/06-Findings.md` with CVSS and MITRE mapping.

## Evidence Capture

```bash
# Linux / macOS
./evidence/capture.sh "nmap full port scan"

# Windows
evidence\\capture.bat "nmap full port scan"
```
"""


# ---------------------------------------------------------------------------
# 4. FILE MANIFEST
# Assembles the full list of (relative_path, content) pairs to write.
# Called after all template functions are defined so it can reference them.
# ---------------------------------------------------------------------------

def build_file_manifest(
    target: str,
    client: str,
    author: str,
    scope: str,
    os_type: str,
    no_templates: bool,
) -> list:
    """
    Returns a list of (relative_path, content) tuples.
    Each tuple is one file to write inside the engagement root directory.
    If --no-templates is set, only .gitkeep placeholder files are returned
    so the folder structure exists in git without any markdown content.
    """
    gitkeeps = [(f"scans/{sub}/.gitkeep", "") for sub in SCAN_SUBDIRS.get(scope, SCAN_SUBDIRS["full"])]
    gitkeeps.append(("tools/.gitkeep", ""))

    if no_templates:
        return gitkeeps

    files = []
    files.append(("README.md",   readme_template(target, client, author, scope)))
    files.append(("00-Scope.md", scope_template(target, client, author, scope)))

    phases = [
        ("01-Recon",                "Recon & Enumeration"),
        ("02-Foothold",             "Foothold"),
        ("03-Post-Exploitation",    "Post-Exploitation"),
        ("04-Lateral-Movement",     "Lateral Movement"),
        ("05-Privilege-Escalation", "Privilege Escalation"),
    ]
    for filename, phase_name in phases:
        files.append((f"notes/{filename}.md", phase_template(target, phase_name, author)))

    files.append(("notes/06-Findings.md", findings_template(target, client, author)))
    files.append(("loot/loot.md", loot_template(target, client)))

    if os_type == "windows":
        files.append(("evidence/capture.bat", capture_script_windows(target, client)))
    else:
        files.append(("evidence/capture.sh", capture_script_unix(target, client)))

    files.extend(gitkeeps)
    return files


# ---------------------------------------------------------------------------
# 5. DIRECTORY AND FILE CREATION
# Takes the directory list and file manifest and writes everything to disk.
# On Unix-like systems it also marks capture.sh as executable.
# ---------------------------------------------------------------------------

def create_engagement(
    target: str,
    client: str,
    author: str,
    scope: str,
    base_dir: Path,
    no_templates: bool,
    dry_run: bool,
    os_type: str,
) -> Path:
    """
    Builds the engagement root path, creates all directories, then writes
    all files. Returns the path to the engagement root directory.
    """
    today = date.today().strftime("%Y%m%d")
    safe_target = sanitize_name(target, os_type)
    eng_root = base_dir / f"{safe_target}-{today}"

    dirs = build_directory_list(scope)
    files = build_file_manifest(target, client, author, scope, os_type, no_templates)

    all_dirs = set(dirs)
    for rel_path, _ in files:
        parent = str(Path(rel_path).parent)
        if parent != ".":
            all_dirs.add(parent)

    if dry_run:
        print(f"\n[DRY RUN] Engagement root: {eng_root}\n")
        print("Directories:")
        for d in sorted(all_dirs):
            print(f"  {eng_root / d}")
        print("\nFiles:")
        for rel_path, _ in files:
            print(f"  {eng_root / rel_path}")
        print()
        return eng_root

    for d in sorted(all_dirs):
        (eng_root / d).mkdir(parents=True, exist_ok=True)

    for rel_path, content in files:
        file_path = eng_root / rel_path
        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_path.write_text(content, encoding="utf-8")
        if os_type != "windows" and file_path.name == "capture.sh":
            file_path.chmod(0o755)

    return eng_root


# ---------------------------------------------------------------------------
# 6. CLI ARGUMENT PARSING
# Defines all flags, their defaults, and the help text shown by --help.
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="engagekit — Pentest Engagement Workspace Scaffolder",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python engagekit.py AcmeCorp
  python engagekit.py AcmeCorp -c "Acme Corporation" -s internal
  python engagekit.py ClientWeb -s webapp -o ~/Engagements
  python engagekit.py TestLab --dry-run
  python engagekit.py BigCorp -s full --no-templates
        """,
    )
    parser.add_argument("target",
        help="Short target identifier used in folder name (e.g. AcmeCorp)")
    parser.add_argument("-a", "--author",
        default="",
        help="Tester name")
    parser.add_argument("-c", "--client",
        default=None,
        help="Full client name for templates (default: same as target)")
    parser.add_argument("-s", "--scope",
        default="full",
        choices=["internal", "external", "webapp", "ad", "full"],
        help="Scope type — controls which scan subfolders are created (default: full)")
    parser.add_argument("-o", "--output",
        default="./engagements",
        help="Base directory to create the engagement folder in (default: ./engagements)")
    parser.add_argument("--no-templates",
        action="store_true",
        help="Create folder structure only, skip all markdown files")
    parser.add_argument("--dry-run",
        action="store_true",
        help="Print what would be created without writing anything")
    return parser.parse_args()


# ---------------------------------------------------------------------------
# 7. ENTRY POINT
# Ties everything together: parse args, detect OS, run, print summary.
# ---------------------------------------------------------------------------

def main() -> None:
    args = parse_args()
    os_type = detect_os()
    client = args.client if args.client else args.target
    base_dir = Path(args.output).expanduser().resolve()

    print(f"\n[*] engagekit — Pentest Engagement Scaffolder")
    print(f"[*] OS detected  : {platform.system()} ({os_type})")
    print(f"[*] Target       : {args.target}")
    print(f"[*] Client       : {client}")
    print(f"[*] Scope        : {args.scope}")
    print(f"[*] Author       : {args.author}")
    print(f"[*] Output base  : {base_dir}")

    eng_root = create_engagement(
        target=args.target,
        client=client,
        author=args.author,
        scope=args.scope,
        base_dir=base_dir,
        no_templates=args.no_templates,
        dry_run=args.dry_run,
        os_type=os_type,
    )

    if not args.dry_run:
        print(f"\n[+] Workspace ready : {eng_root}")
        print(f"[+] Start with      : {eng_root / '00-Scope.md'}")
        if os_type == "windows":
            print(f"[+] Evidence capture: {eng_root / 'evidence' / 'capture.bat'} \"description\"")
        else:
            print(f"[+] Evidence capture: {eng_root / 'evidence' / 'capture.sh'} \"description\"")
        print()


if __name__ == "__main__":
    main()
