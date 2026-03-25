# 🔍 Recon & Enumeration Index
#recon #phase

## Checklist
- [ ] Host discovery / ping sweep
- [ ] Full port scan (all 65535)
- [ ] Service/version detection
- [ ] OS fingerprinting
- [ ] Web tech fingerprinting (if ports 80/443/8080)
- [ ] DNS enumeration
- [ ] SMB/NFS enumeration (if ports 139/445/2049)
- [ ] SNMP enumeration (if port 161)
- [ ] LDAP enumeration (if port 389/636)
- [ ] Subdomain/vhost fuzzing

---

## Nmap — Standard Workflow
```bash
# 1. Fast all-port sweep
nmap -p- --min-rate 5000 -oA allports <IP>

# 2. Deep scan on open ports
nmap -p <ports> -sC -sV -oA targeted <IP>

# 3. UDP scan (top 100)
sudo nmap -sU --top-ports 100 <IP>

# 4. Vuln scripts
nmap -p <ports> --script vuln <IP>
```

## FFUF — Web Fuzzing
```bash
# Directory fuzzing
ffuf -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -u http://<IP>/FUZZ

# Extension fuzzing
ffuf -w /usr/share/seclists/Discovery/Web-Content/raft-medium-files.txt -u http://<IP>/FUZZ -e .php,.txt,.bak,.html

# Vhost fuzzing
ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -u http://<domain>/ -H "Host: FUZZ.<domain>" -fs <default_size>

# Parameter fuzzing (GET)
ffuf -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -u "http://<IP>/page.php?FUZZ=value"
```

## SMB Enumeration
```bash
smbclient -N -L //<IP>
enum4linux-ng -A <IP>
crackmapexec smb <IP> --shares
nmap -p 445 --script smb-enum-shares,smb-enum-users <IP>
```

## DNS Enumeration
```bash
dig axfr @<IP> <domain>
gobuster dns -d <domain> -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt
dig -x <IP> @<nameserver>
```

## SNMP
```bash
onesixtyone -c /usr/share/seclists/Discovery/SNMP/common-snmp-community-strings.txt <IP>
snmpwalk -v2c -c <community> <IP>
```

## LDAP
```bash
ldapsearch -x -H ldap://<IP> -b "DC=<domain>,DC=<tld>"
ldapsearch -x -H ldap://<IP> -D "user@domain.com" -w password -b "DC=domain,DC=com"
```

---
*See also: [[05-Active-Directory/AD Index]] | [[06-Web-Attacks/Web Attacks Index]]*
