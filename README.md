# ShadowScan
ShadowScan captures the essence of stealthiness, slow scanning, and the pursuit of vulnerabilities like low-hanging fruit. 

Based on the "Potential Hacks To Look For" - from [https://github.com/trustedsec/spoonmap ](https://github.com/trustedsec/spoonmap#potential-hacks-to-look-for)

This scanner is low and slow. Helpful for Red Team Engagements. The script will randomly sleep between ping scans and port scans.


Simply provide your ip file, a list of IPs and add any ports you'd like to scan. 
```
PS> .\YourTool.ps1 -idFile "ips.txt" -ports 80,443,445
```

Feel free to add mappings to other services and their respective ports:

```
$portServices = @{
    80    = "HTTP";
    443   = "HTTPS";
    445   = "SMB";
    7070  = "WebLogic";
    7071  = "WebLogic";
    4786  = "Cisco Smart Install";
    4848  = "GlassFish";
    5555  = "HP Data Protector";
    5556  = "HP Data Protector";
    3300  = "SAP";
    6129  = "DameWare";
    6379  = "Redis";
    6970  = "Cisco Unified Comm Manager";
    Port  = "Service"
}
```
