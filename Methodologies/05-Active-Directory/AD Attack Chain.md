# 🔗 AD Attack Chain
#active-directory #attack-chain

## Classic Chain: External → DA

```
[External Recon]
    └── Subdomain / VPN portal / exposed service
            ↓
[Foothold]
    └── Phishing / CVE / Weak creds on exposed service
            ↓
[Internal Recon]
    └── BloodHound + LDAP enum + Share hunting
            ↓
[Privilege Escalation]
    └── Local admin → Credential dumping
            ↓
[Credential Abuse]
    ├── Kerberoasting → Hash cracking → Lateral move
    ├── AS-REP Roasting → Crack → Lateral move
    ├── Password spray → Valid creds → WinRM/SMB
    └── Pass-the-Hash → Local admin → More creds
            ↓
[Path to DA via BloodHound]
    ├── GenericAll / GenericWrite / WriteDACL → ACL abuse
    ├── Constrained/Unconstrained Delegation abuse
    └── Direct DA group membership path
            ↓
[Domain Admin]
    └── DCSync → All hashes → Golden Ticket → Persistence
```

---

## Key Pivot Moments

| Situation | Technique | Tool |
|---|---|---|
| Have user creds, want DA | Kerberoasting | impacket-GetUserSPNs |
| Have user creds, want DA | BloodHound shortest path | BloodHound |
| Have local admin hash | Pass-the-Hash | evil-winrm / cme |
| Have DA hash | DCSync | impacket-secretsdump |
| Have DA hash | Golden Ticket | mimikatz |
| Have GenericAll on user | Force password reset | PowerView |
| Have GenericAll on group | Add self to group | PowerView / net |
| Have WriteDACL | Grant DCSync rights | PowerView |

---

## BloodHound Cypher Quick Hits
```cypher
-- Shortest path to DA
MATCH p=shortestPath((u:User {name:"<USER@DOMAIN>"})-[*1..]->(g:Group {name:"DOMAIN ADMINS@DOMAIN"})) RETURN p

-- All kerberoastable users
MATCH (u:User {hasspn:true}) RETURN u.name, u.description

-- AS-REP roastable
MATCH (u:User {dontreqpreauth:true}) RETURN u.name
```

---
*See also: [[05-Active-Directory/Kerberos Attacks]] | [[05-Active-Directory/BloodHound]]*
