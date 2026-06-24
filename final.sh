#!/bin/bash

domain="$1"
RED="\033[1;31m"
RESET="\033[0m"
subdomain_path="$domain/subdomains"
waybackurl_path="$domain/waybackurl"
nuclei_path="$domain/nuclei"
dirsearch_path="$domain/dirsearch"
xss_path="$domain/xss" # New directory for XSS results

if [ ! -d "$domain" ]; then
 mkdir "$domain"
fi

if [ ! -d "$subdomain_path" ]; then
 mkdir "$subdomain_path"
fi

if [ ! -d "$waybackurl_path" ]; then
 mkdir "$waybackurl_path"
fi

if [ ! -d "$nuclei_path" ]; then
 mkdir "$nuclei_path"
fi

if [ ! -d "$dirsearch_path" ]; then
 mkdir "$dirsearch_path"
fi

if [ ! -d "$xss_path" ]; then
 mkdir "$xss_path"
fi

# Subdomain enumeration
echo -e "${RED}[+] Launching subfinder...${RESET}"
subfinder -d "$domain" -silent -o "$subdomain_path/found.txt" >/dev/null 2>&1

echo -e "${RED}[+] Launching Assetfinder...${RESET}"
assetfinder "$domain" | grep "$domain" >> "$subdomain_path/found.txt"

# To find alive domains
echo -e "${RED}[+] Checking for alive domains...${RESET}"
httpx -l "$subdomain_path/found.txt" -silent -threads 200 -o "$subdomain_path/alive.txt" >/dev/null 2>&1

echo -e "${RED}[+] Checking waybackurls...${RESET}"
cat "$subdomain_path/alive.txt" | waybackurls > "$waybackurl_path/waybackurls.txt"

echo -e "${RED}[+] Checking gau...${RESET}"
gau "$domain" | sort -u >> "$waybackurl_path/waybackurls.txt"

# Separate waybackurls
grep "\.js" "$waybackurl_path/waybackurls.txt" | sort -u > "$waybackurl_path/wayback_js.txt"
grep "\.json" "$waybackurl_path/waybackurls.txt" | sort -u > "$waybackurl_path/wayback_json.txt"

# XSS automation
echo -e "${RED}[+] Launching XSS automation...${RESET}"
echo -e "${RED}[+] Running XSStrike...${RESET}"
python3 XSStrike.py -u "$domain" -o "$xss_path/xss_results.txt" >/dev/null 2>&1

echo -e "${RED}[+] Running kxss...${RESET}"
cat "$subdomain_path/alive.txt" "$waybackurl_path/waybackurls.txt" | kxss > "$xss_path/kxss_results.txt" >/dev/null 2>&1

# Finding ports of a subdomain
echo -e "${RED}[+] Launching Naabu...${RESET}"
naabu -l "$subdomain_path/found.txt" -o "$subdomain_path/ports.txt" >/dev/null 2>&1

# Directory enumeration
echo -e "${RED}[+] Launching dirsearch...${RESET}"
dirsearch -u "$domain" -o "$dirsearch_path/dirsearch_output.txt" >/dev/null 2>&1

# Finding Subdomain Takeovers
echo -e "${RED}[+] Running subzy....To Find Takeover bugs...${RESET}"
subzy run --targets "$subdomain_path/found.txt" 2>&1 >/dev/null > "$subdomain_path/subdomain_takeover.txt"

# Finding nuclei CVEs
echo -e "${RED}[+] Launching Nuclei it takes sometime...${RESET}"
nuclei -l "$subdomain_path/alive.txt" -o "$nuclei_path/nuclei.txt" >/dev/null 2>&1