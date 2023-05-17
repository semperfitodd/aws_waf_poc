#!/bin/bash

URL="http://waf.bsisandbox.com/"

echo "*********************"
echo "****Running bot control test****"
echo "*********************"

response=$(curl -o /dev/null -s -w "%{http_code}\n" "$URL")
if [ "$response" -eq 403 ]; then
    echo "Bot traffic denied by AWS WAF"
else
    echo "Bot traffic allowed"
fi

echo "*********************"
echo "****Running SQL Injection Test****"
echo "*********************"

output=$(sqlmap -u "$URL" --batch 2>&1)
echo "$output"
if echo "$output" | grep -q "\[CRITICAL\] WAF/IPS identified as 'AWS WAF (Amazon)'"; then
    echo "SQL injection traffic potentially blocked by AWS WAF"
else
    echo "No WAF detection reported by sqlmap"
fi

echo "*********************"
echo "****Running XSS Test****"
echo "*********************"

response=$(curl -o /dev/null -s -w "%{http_code}\n" "$URL/<script>alert('XSS')</script>")
if [ "$response" -eq 403 ]; then
    echo "XSS script traffic denied by AWS WAF"
else
    echo "XSS script traffic allowed"
fi

echo "*********************"
echo "****Running HTTP Flood (DDoS) Test****"
echo "*********************"

ab -n 1000 -c 100 "$URL"

echo "DDoS attack completed. Check WAF logs"

echo "*********************"
echo "****All tests completed****"
echo "*********************"