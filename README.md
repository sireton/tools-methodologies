# 🔒 pentest-vault

Private Obsidian knowledge base — HTB CPTS methodology library and blog content drafts.

> **This repository is private.** Never make it public.

---

## Structure

```
pentest-vault/
├── 00-Meta/                  # Tools, wordlists, shell tricks, file transfers
├── 01-Recon/                 # Enumeration methodology
├── 02-Foothold/              # Initial access by service
├── 03-Post-Exploitation/     # Post-ex checklist and privesc
├── 04-Lateral-Movement/      # Pivoting, PtH, remote execution
├── 05-Active-Directory/      # AD attacks, Kerberos, BloodHound
├── 06-Web-Attacks/           # SQLi, LFI, file upload, SSRF
├── 07-Pillaging/             # Credential hunting
├── 08-Reporting/             # Report structure and references
└── Templates/
    ├── Engagement Template.md          # Per-box working notes
    ├── HTB Walkthrough Template.md     # Blog walkthrough post
    ├── Engagement Report Template.md   # Blog report post
    ├── ProLab Report Template.md       # ProLab blog report
    └── Vulnerability Write-Up Template.md
```

---

## Daily Workflow

### Starting a New Machine

1. Create a new note — `Ctrl+N`, name it `Machines/YYYY-MM-DD-MachineName`
2. Press `Ctrl+T` → pick **Engagement Template**
3. Your note is pre-filled and ready — use this as your private scratchpad throughout the engagement (raw nmap output, credentials, rabbit holes, flags)

### Writing Up (Once Rooted)

1. New note → `Ctrl+T` → pick **HTB Walkthrough Template** → name it `Drafts/YYYY-MM-DD-MachineName-Walkthrough`
2. New note → `Ctrl+T` → pick **Engagement Report Template** → name it `Drafts/YYYY-MM-DD-MachineName-Report`
3. Fill both out using your private working notes as the source
4. Save screenshots to `assets/img/<machine-name>/` inside the vault

### Pre-Publish Checklist

Before copying anything to the blog repo:

- [ ] Remove the **OBSIDIAN PRIVATE METADATA** block from the front matter
- [ ] Machine is **retired** on HTB (never publish active machine writeups)
- [ ] No real flags, hashes, or credentials in the post
- [ ] All screenshot paths match `assets/img/<machine-name>/filename.png`
- [ ] Front matter complete — title, date, categories, tags, description, image

### Publishing to the Blog

**1. Copy the markdown files** into your blog repo `_posts/` folder:
```
_posts/YYYY-MM-DD-MachineName-Walkthrough.md
_posts/YYYY-MM-DD-MachineName-Report.md
```

**2. Copy screenshots** into the blog repo:
```
assets/img/<machine-name>/
```

**3. Push the blog repo:**
```bash
cd "C:\Users\sireton\sireton.github.io"
git add .
git commit -m "Add <MachineName> walkthrough and report"
git push
```

Your post goes live on [sireton.github.io](https://sireton.github.io) within ~60 seconds via GitHub Actions.

---

### Syncing the Vault

**Auto-sync** runs every 20 minutes via the Obsidian Git plugin.

**Manual sync anytime:**
```bash
# Inside Obsidian
Ctrl+P → "Obsidian Git: Commit and sync"

# Or from terminal
cd "C:\Users\sireton\Pentesting\pentest-vault"
git add .
git commit -m "vault update: "
git push
```

---

### Full Loop at a Glance

```
[Obsidian — Private Vault]
  Engagement Template  →  working notes, raw output, creds
        ↓  (machine rooted + HTB retires it)
  HTB Walkthrough Template  →  Drafts/
  Engagement Report Template  →  Drafts/
        ↓  (pre-publish checklist passed)
[Copy to sireton.github.io]
  _posts/YYYY-MM-DD-Machine-Walkthrough.md
  _posts/YYYY-MM-DD-Machine-Report.md
  assets/img/<machine-name>/
        ↓
  git add . → git commit → git push
        ↓
[Live on sireton.github.io in ~60 seconds]
```